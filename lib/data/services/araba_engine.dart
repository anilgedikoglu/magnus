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

  /// 2: yeni havuz (marka/sınıf/yaygınlık). Eski kayıtlar okunmaz → yeniden üretilir.
  static const schema = 2;
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

  /// Kayıtlı çizelgeyi yükler; yoksa / cinsiyet değiştiyse / havuzla uyuşmuyorsa üretir.
  static Future<ArabaTimeline> load(
    SharedPreferences prefs,
    UserProfile p,
    List<ArabaCar> pool, {
    int? nowYear,
    int? seed,
  }) async {
    final year = nowYear ?? DateTime.now().year;
    final gender = KismetEngine.genderOf(p);
    final raw = prefs.getString(prefsKey);
    if (raw != null) {
      try {
        final t = ArabaTimeline.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        final ids = {for (final c in pool) c.id};
        // Tüm aralıklar geçmişte kaldıysa (yıllar sonra) yeni çizelge üretilir.
        final stillFuture = t != null && t.slots.isNotEmpty && t.slots.last.end >= year;
        if (t != null && stillFuture && t.signature == gender &&
            t.slots.every((s) => s.carId == null || ids.contains(s.carId))) {
          return t;
        }
      } catch (_) {/* bozuk kayıt → yeniden üret */}
    }
    final age = year - KismetEngine.birthYearOf(p, year);
    final evli = KismetEngine.maritalGroupOf(p) == 'evli';
    final t = generate(pool,
        gender: gender, age: age, married: evli, baseYear: year, seed: seed ?? Random().nextInt(1 << 31));
    await save(prefs, t);
    return t;
  }

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
  }) {
    final rnd = Random(seed);
    final byId = {for (final c in pool) c.id: c};

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
        final target = i == 0 ? _firstLevel(rnd, ageAt) : _nextLevel(rnd, prevLevel, ageAt);
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
    return ArabaTimeline(seed: seed, baseYear: baseYear, signature: gender, slots: slots);
  }

  /// İlk arabanın fiyat sınıfı — yaşa göre gerçekçi (Türkiye'de çoğunluk 1-3).
  static int _firstLevel(Random rnd, int age) {
    if (age < 23) return _weightedInt(rnd, const [(1, 55), (2, 40), (3, 5)]);
    if (age < 30) return _weightedInt(rnd, const [(1, 25), (2, 50), (3, 22), (4, 3)]);
    if (age < 40) return _weightedInt(rnd, const [(1, 12), (2, 45), (3, 30), (4, 11), (5, 2)]);
    if (age < 55) return _weightedInt(rnd, const [(1, 8), (2, 38), (3, 32), (4, 16), (5, 5), (6, 1)]);
    return _weightedInt(rnd, const [(1, 8), (2, 35), (3, 33), (4, 17), (5, 6), (6, 1)]);
  }

  /// Sonraki aralık: çoğunlukla aynı sınıf ya da bir üstü; lüks sınıflar ek zarla nadir.
  static int _nextLevel(Random rnd, int prev, int age) {
    final delta = age >= 70
        ? _weightedInt(rnd, const [(-1, 30), (0, 60), (1, 10)])
        : _weightedInt(rnd, const [(-1, 10), (0, 50), (1, 36), (2, 4)]);
    var t = (prev + delta).clamp(1, 7);
    if (t >= 6 && prev < 6 && rnd.nextDouble() > 0.30) t = 5; // lükse geçiş zor
    if (t == 7 && prev < 7 && rnd.nextDouble() > 0.10) t = 6; // süper lüks çok nadir
    return t;
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

  static int _weightedInt(Random rnd, List<(int, int)> items) {
    final sum = items.fold<int>(0, (a, b) => a + b.$2);
    var r = rnd.nextInt(sum);
    for (final (v, w) in items) {
      if (r < w) return v;
      r -= w;
    }
    return items.last.$1;
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
