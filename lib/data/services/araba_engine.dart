// "Arabam Ne?" falı motoru — v2 (2026-11-05, Anıl: "hep Mercedes S500 mantıklı mı? binlerce marka/model,
// yaşa ve cinsiyete göre olasılıkla; arabalar arasında mantık sırası; aynı arabayla devam edilebilir;
// Togg, Honda, Nissan, Citroën…").
//
// Havuz: assets/data/arabam.json — ChatGPT ile hazırlanan Türkiye pazarı listesi (marka, model+donanım,
// segment, fiyat sınıfı 1-7, yakıt, Türkiye'de yaygınlık 1-10, cinsiyet eğilimi, durum eski/guncel/gelecek).
//
// Kullanıcıya özel, kalıcı ÇİZELGE bir kez üretilir:
//  • bu yıldan +50 yıla kadar 5 ardışık yıl aralığı (2-12 yıl); %15 olasılıkla 1-2 yıllık arabasız dönem;
//  • ilk sınıf YAŞA göre (gençte ekonomik/popüler ağırlıklı), sonra çoğunlukla aynı sınıf ya da bir üstü;
//    lüks (6) ve süper lüks (7) ek bir zarla nadir;
//  • seçim Türkiye'de yaygınlığa göre ağırlıklı (Egea/Clio sık, Ferrari çok seyrek);
//  • yakıt payı yıllara göre (yakın yıllar benzin/hibrit, 2040+ elektrik);
//  • "eski" modeller yalnız ilk yıllarda düşük sınıfta (ikinci el), "gelecek" modeller kendi yılından sonra;
//  • %25 olasılıkla bir sonraki aralıkta AYNI arabayla devam; başka türlü aynı model tekrar çıkmaz;
//  • cinsiyet eğilimi ve yaş/medeni hale göre hafif segment eğilimi;
//  • açılan kutular kalıcı (slot indeksi bazında).
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'kismet_engine.dart' show KismetEngine;

class ArabaCar {
  const ArabaCar({
    required this.id,
    required this.brand,
    required this.name,
    required this.segment,
    required this.level,
    required this.fuel,
    required this.popularity,
    required this.lean,
    required this.status,
    this.fromYear,
  });

  final int id;
  final String brand;
  final String name; // model + motor/donanım
  final String segment; // sehir/kompakt/sedan/suv_kucuk/suv/suv_buyuk/mpv/pickup/spor/ust_sedan
  final int level; // fiyat sınıfı 1..7
  final String fuel; // benzin/dizel/hibrit/elektrik/lpg
  final int popularity; // Türkiye'de yollarda görülme 1..10
  final String lean; // kadin/erkek/notr
  final String status; // eski/guncel/gelecek
  final int? fromYear; // gelecek modeller için en erken yıl

  /// Ekranda görünen ad: "Fiat Egea Sedan 1.4 Fire Easy".
  String get model => name.toLowerCase().startsWith(brand.toLowerCase()) ? name : '$brand $name';

  static ArabaCar fromJson(Map<String, dynamic> j) => ArabaCar(
        id: j['id'] as int,
        brand: j['marka'] as String,
        name: j['model'] as String,
        segment: j['segment'] as String,
        level: j['sinif'] as int,
        fuel: j['yakit'] as String,
        popularity: j['yayginlik'] as int,
        lean: j['egilim'] as String,
        status: j['durum'] as String,
        fromYear: j['yil'] as int?,
      );
}

class ArabaSlot {
  const ArabaSlot(this.start, this.end, this.carId);
  final int start; // dahil
  final int end; // dahil
  final int? carId; // null → arabasız dönem

  bool get isGap => carId == null;

  Map<String, dynamic> toJson() => {'s': start, 'e': end, 'c': carId};
  static ArabaSlot fromJson(Map<String, dynamic> j) =>
      ArabaSlot(j['s'] as int, j['e'] as int, j['c'] as int?);
}

class ArabaTimeline {
  ArabaTimeline({
    required this.seed,
    required this.baseYear,
    required this.signature,
    required this.slots,
    Set<int>? revealed,
    this.computed = false,
  }) : revealed = revealed ?? {};

  /// 3: marka tabanlı başlangıç + ±1 kademeli ilerleme (Anıl + Codex, 2026-11-06). Eski kayıtlar
  /// okunmaz → yeniden üretilir.
  static const schema = 3;
  final int seed;
  final int baseYear;
  final String signature;
  final List<ArabaSlot> slots;
  final Set<int> revealed; // açılmış slot indeksleri
  bool computed; // "Hesaplanıyor" adımı bir kez geçildi mi

  bool isRevealed(int index) => revealed.contains(index);

  Map<String, dynamic> toJson() => {
        'v': schema, 'seed': seed, 'base': baseYear, 'sig': signature,
        'slots': [for (final s in slots) s.toJson()],
        'rev': revealed.toList(),
        'computed': computed,
      };

  static ArabaTimeline? fromJson(Map<String, dynamic> j) {
    if (j['v'] != schema) return null;
    return ArabaTimeline(
      seed: j['seed'] as int,
      baseYear: j['base'] as int,
      signature: j['sig'] as String,
      slots: [for (final s in j['slots'] as List) ArabaSlot.fromJson(Map<String, dynamic>.from(s as Map))],
      revealed: {for (final i in (j['rev'] as List? ?? const [])) i as int},
      computed: j['computed'] as bool? ?? false,
    );
  }
}

class ArabaEngine {
  ArabaEngine._();

  static const prefsKey = 'arabam_v1';
  static const brandPrefsKey = 'arabam_marka'; // kullanıcının seçtiği şu anki marka ("" = arabam yok)
  static const horizon = 50;
  static const rangeCount = 5;

  /// Bir sonraki aralıkta aynı arabayla devam olasılığı.
  static const pContinue = 0.25;

  static List<ArabaCar>? _pool;

  static Future<List<ArabaCar>> loadPool() async {
    final cached = _pool;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/arabam.json');
    return _pool = parsePool(raw);
  }

  static List<ArabaCar> parsePool(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return [for (final e in j['arabalar'] as List) ArabaCar.fromJson(Map<String, dynamic>.from(e as Map))];
  }

  /// Seçilebilir markalar — havuzdaki benzersiz markalar, A–Z sıralı (gelecek-only markalar dahil).
  static List<String> brands(List<ArabaCar> pool) {
    final set = <String>{for (final c in pool) c.brand};
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Markanın BAŞLANGIÇ sınıfı (1..7): o markanın güncel/eski modellerinin yaygınlık ağırlıklı
  /// MEDYAN fiyat sınıfı (Codex). Marka tek başına serveti belirlemez; yalnız gerçekçi bir
  /// başlangıç noktası verir. Bilinmeyen marka → 2.
  static int brandStartLevel(List<ArabaCar> pool, String brand) {
    final key = brand.toLowerCase();
    final cars = pool.where((c) => c.brand.toLowerCase() == key && c.status != 'gelecek').toList();
    if (cars.isEmpty) return 2;
    final levels = <int>[];
    for (final c in cars) {
      final w = c.popularity.clamp(1, 10);
      for (var i = 0; i < w; i++) {
        levels.add(c.level);
      }
    }
    levels.sort();
    return levels[levels.length ~/ 2].clamp(1, 7);
  }

  /// Bir sonraki araba sınıfı: en fazla ±1 kademe (Codex). [prevLen] önceki arabanın yıl süresi;
  /// yukarı çıkış için en az 4 yıl bekle. 6–7'ye giriş ek zorlukla. [jobBoost] küçük meslek etkisi.
  static int _progressLevel(Random rnd, int prev, int prevLen, double jobBoost) {
    final canUp = prevLen >= 4;
    var pUp = (0.18 + 0.025 * min(prevLen, 10) + jobBoost).clamp(0.15, 0.45);
    if (!canUp) pUp = 0;
    const pDown = 0.10;
    final r = rnd.nextDouble();
    var delta = r < pUp ? 1 : (r < pUp + pDown ? -1 : 0);
    if (delta > 0 && prev >= 5 && rnd.nextDouble() > 0.45) delta = 0; // lükse giriş zor
    if (delta > 0 && prev >= 6 && rnd.nextDouble() > 0.25) delta = 0; // süper lükse çok zor
    return (prev + delta).clamp(1, 7);
  }

  /// Kayıtlı çizelgeyi yükler; yoksa / cinsiyet değiştiyse / havuzla uyuşmuyorsa üretir.
  static Future<ArabaTimeline> load(
    SharedPreferences prefs,
    UserProfile p,
    List<ArabaCar> pool, {
    int? nowYear,
    int? seed,
    String? currentBrand, // null → kayıtlı markayı oku; "" → arabam yok
  }) async {
    final year = nowYear ?? DateTime.now().year;
    final gender = KismetEngine.genderOf(p);
    // Seçili marka: parametre verildiyse onu kaydet, yoksa kayıttan oku ("" = arabam yok).
    final brand = currentBrand ?? (prefs.getString(brandPrefsKey) ?? '');
    if (currentBrand != null) await prefs.setString(brandPrefsKey, currentBrand);
    final sig = _signature(gender, brand);
    final raw = prefs.getString(prefsKey);
    if (raw != null) {
      try {
        final t = ArabaTimeline.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        final ids = {for (final c in pool) c.id};
        // Tüm aralıklar geçmişte kaldıysa (yıllar sonra) yeni çizelge üretilir.
        final stillFuture = t != null && t.slots.isNotEmpty && t.slots.last.end >= year;
        if (t != null && stillFuture && t.signature == sig &&
            t.slots.every((s) => s.carId == null || ids.contains(s.carId))) {
          return t;
        }
      } catch (_) {/* bozuk kayıt → yeniden üret */}
    }
    final age = year - KismetEngine.birthYearOf(p, year);
    final evli = KismetEngine.maritalGroupOf(p) == 'evli';
    final t = generate(pool,
        gender: gender, age: age, married: evli, baseYear: year,
        currentBrand: brand.isEmpty ? null : brand,
        seed: seed ?? Random().nextInt(1 << 31));
    await save(prefs, t);
    return t;
  }

  static String _signature(String gender, String brand) =>
      '$gender|${brand.isEmpty ? '_yok' : brand.toLowerCase()}';

  static Future<void> save(SharedPreferences prefs, ArabaTimeline t) =>
      prefs.setString(prefsKey, jsonEncode(t.toJson()));

  static Future<void> reveal(SharedPreferences prefs, ArabaTimeline t, int slotIndex) {
    t.revealed.add(slotIndex);
    t.computed = true;
    return save(prefs, t);
  }

  static Future<void> markComputed(SharedPreferences prefs, ArabaTimeline t) {
    t.computed = true;
    return save(prefs, t);
  }

  // ── Üretim ────────────────────────────────────────────────────────────────
  static ArabaTimeline generate(
    List<ArabaCar> pool, {
    required String gender, // kadin / erkek / belirsiz
    required int age,
    required int baseYear,
    required int seed,
    bool married = false,
    String? currentBrand, // null → arabam yok
  }) {
    final rnd = Random(seed);
    final byId = {for (final c in pool) c.id: c};
    // Başlangıç sınıfı: markadan (Codex) — arabam yok → 0 (ilk alım sınıf 1). Doğum yeri KULLANILMAZ.
    final startLevel = currentBrand == null ? 0 : brandStartLevel(pool, currentBrand);

    // 1) Yıl aralıkları: 51 yıl (base..base+50) içinde 5 aralık (+ ops. boşluk)
    var remaining = horizon + 1;
    int gapAfter = -1, gapLen = 0;
    if (rnd.nextDouble() < 0.15) {
      gapAfter = rnd.nextInt(rangeCount - 1); // 0..3 → aralıklar arasında
      gapLen = 1 + rnd.nextInt(2);
      remaining -= gapLen;
    }
    final lengths = <int>[];
    for (var i = 0; i < rangeCount; i++) {
      final maxLen = min(12, remaining - 2 * (rangeCount - 1 - i));
      final len = 2 + rnd.nextInt(maxLen - 1);
      lengths.add(len);
      remaining -= len;
    }

    // 2) Sınıf + model seçimi
    final used = <int>{};
    final slots = <ArabaSlot>[];
    var cursor = baseYear;
    var prevLevel = 0;
    int? prevCarId;
    var prevLen = 0;
    for (var i = 0; i < rangeCount; i++) {
      final start = cursor;
      final end = cursor + lengths[i] - 1;
      final ageAt = age + (start - baseYear);

      ArabaCar car;
      final prevCar = prevCarId == null ? null : byId[prevCarId];
      final canContinue = prevCar != null && prevCar.status != 'eski' && prevLen + lengths[i] <= 15;
      if (canContinue && rnd.nextDouble() < pContinue) {
        car = prevCar; // aynı arabayla devam
      } else {
        final int target;
        if (i == 0) {
          // İlk gelecek araç: mevcut markanın başlangıç sınıfında (arabam yok → 1).
          target = startLevel == 0 ? 1 : startLevel;
        } else {
          target = _progressLevel(rnd, prevLevel, prevLen, 0.0); // ±1 kademeli; meslek etkisi nötr (v1)
        }
        car = _pickCar(rnd, pool, used,
            target: target, year: start, baseYear: baseYear, age: ageAt, gender: gender, married: married);
        used.add(car.id);
      }
      prevLevel = car.level;
      prevLen = car.id == prevCarId ? prevLen + lengths[i] : lengths[i];
      prevCarId = car.id;
      slots.add(ArabaSlot(start, end, car.id));
      cursor = end + 1;

      if (i == gapAfter) {
        slots.add(ArabaSlot(cursor, cursor + gapLen - 1, null));
        cursor += gapLen;
        prevCarId = null; // arabasız dönemden sonra yeni araba
        prevLen = 0;
      }
    }
    return ArabaTimeline(
        seed: seed, baseYear: baseYear,
        signature: _signature(gender, currentBrand ?? ''), slots: slots);
  }


  /// Yıla göre yakıt çarpanı (EV payı zamanla artar).
  static double _fuelFactor(String fuel, int year) {
    final p = year < 2030 ? 0 : year < 2035 ? 1 : year < 2040 ? 2 : 3;
    const t = {
      'benzin': [1.0, 0.8, 0.45, 0.15],
      'dizel': [0.8, 0.4, 0.15, 0.05],
      'hibrit': [0.9, 1.1, 1.0, 0.6],
      'elektrik': [0.45, 0.9, 1.5, 2.2],
      'lpg': [0.3, 0.2, 0.1, 0.05],
    };
    return (t[fuel] ?? const [0.5, 0.5, 0.5, 0.5])[p];
  }

  static double _segmentFactor(String seg, int age, String gender, bool married) {
    var x = 1.0;
    switch (seg) {
      case 'sehir':
        if (age < 30 || gender == 'kadin') x *= 1.3;
        if (married && age >= 30 && age < 50) x *= 0.8;
      case 'mpv':
        x *= (married && age >= 28 && age < 55) ? 1.4 : 0.6;
      case 'suv_buyuk':
        if (married) x *= 1.2;
        if (age < 27) x *= 0.6;
      case 'pickup':
        x *= gender == 'erkek' ? 0.8 : 0.3;
      case 'spor':
        x *= age < 45 ? 0.6 : 0.4;
      case 'ust_sedan':
        if (age < 35) x *= 0.6;
    }
    return x;
  }

  static ArabaCar _pickCar(
    Random rnd,
    List<ArabaCar> pool,
    Set<int> used, {
    required int target,
    required int year,
    required int baseYear,
    required int age,
    required String gender,
    required bool married,
  }) {
    bool eligible(ArabaCar c) {
      if (used.contains(c.id)) return false;
      if (c.status == 'gelecek' && (c.fromYear ?? baseYear) > year) return false;
      // Artık satılmayan model: yalnız ilk yıllarda, düşük sınıfta (ikinci el)
      if (c.status == 'eski' && (year > baseYear + 4 || c.level > 2)) return false;
      return true;
    }

    // Hedef sınıfta aday yoksa en yakın sınıfa genişle (önce aşağı, sonra yukarı)
    var cands = <ArabaCar>[];
    for (final d in const [0, -1, 1, -2, 2, -3, 3]) {
      final lv = target + d;
      if (lv < 1 || lv > 7) continue;
      cands = pool.where((c) => c.level == lv && eligible(c)).toList();
      if (cands.isNotEmpty) break;
    }
    if (cands.isEmpty) cands = pool.where((c) => !used.contains(c.id)).toList();

    final farFuture = year >= baseYear + 15;
    double w(ArabaCar c) {
      var x = pow(c.popularity.clamp(1, 10), 1.6).toDouble();
      x *= _fuelFactor(c.fuel, year);
      x *= _segmentFactor(c.segment, age, gender, married);
      if (gender == 'kadin' || gender == 'erkek') {
        if (c.lean == gender) x *= 1.6;
        if (c.lean != 'notr' && c.lean != gender) x *= 0.6;
      }
      if (c.status == 'eski') x *= 0.6;
      if (c.status == 'gelecek') x *= farFuture ? 1.8 : 1.2;
      if (c.status == 'guncel' && year >= baseYear + 20) x *= 0.5; // çok uzak gelecekte bugünün modelleri azalır
      return x;
    }

    final weights = [for (final c in cands) w(c)];
    final total = weights.fold<double>(0, (a, b) => a + b);
    var x = rnd.nextDouble() * total;
    for (var i = 0; i < cands.length; i++) {
      x -= weights[i];
      if (x <= 0) return cands[i];
    }
    return cands.last;
  }

}

/// Yakıt adları (TR / EN).
class ArabaLabels {
  ArabaLabels._();

  static String fuel(String k, bool en) => switch (k) {
        'benzin' => en ? 'Petrol' : 'Benzin',
        'dizel' => en ? 'Diesel' : 'Dizel',
        'hibrit' => en ? 'Hybrid' : 'Hibrit',
        'elektrik' => en ? 'Electric' : 'Elektrik',
        'lpg' => 'LPG',
        'hidrojen' => en ? 'Hydrogen' : 'Hidrojen',
        _ => k,
      };
}
