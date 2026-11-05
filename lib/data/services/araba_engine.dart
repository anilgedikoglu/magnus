// "Arabam Ne?" falı motoru (2026-11-05). Eğlence amaçlıdır.
//
// Kullanıcıya özel, kalıcı bir ARABA ÇİZELGESİ bir kez üretilir ve saklanır:
//  • bu yıldan en fazla +50 yıla kadar 5 ardışık yıl aralığı (2-12 yıl, rastgele);
//  • %15 olasılıkla aralıkların arasında 1-2 yıllık "arabasız dönem";
//  • gelir artar → seviye (kademe) genellikle +0..+2 yükselir, en fazla -1 düşer;
//  • elektrikli: yakın yıllarda nadir, 15+ yıl sonra belirgin, 25+ yıl sonra baskın;
//    uydurma gelecek modeller (F) yalnız 2040 ve sonrasında;
//  • kadın/erkek eğilimi ×1.8; aynı model iki kez çıkmaz;
//  • açılan kutular kalıcı (slot indeksi bazında) → tekrar reklam istemez.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'kismet_engine.dart' show KismetEngine;

class ArabaCar {
  const ArabaCar({
    required this.id,
    required this.model,
    required this.tier,
    required this.fuel,
    required this.lean,
  });

  final int id;
  final String model;
  final String tier; // K1..K7, E1..E4, F
  final String fuel; // benzin/dizel/hibrit/elektrik/hidrojen
  final String lean; // kadin/erkek/notr

  /// Fiyat seviyesi (1..7). Elektrikler küçük→lüks sırasıyla 3..6, F = 5.
  int get level {
    if (tier == 'F') return 5;
    final n = int.parse(tier.substring(1));
    return tier.startsWith('E') ? n + 2 : n;
  }

  bool get isElectricTier => tier.startsWith('E');

  static ArabaCar fromJson(Map<String, dynamic> j) => ArabaCar(
        id: j['id'] as int,
        model: j['model'] as String,
        tier: j['kademe'] as String,
        fuel: j['yakit'] as String,
        lean: j['egilim'] as String,
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

  static const schema = 1;
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
    final t = generate(pool, gender: gender, age: age, baseYear: year, seed: seed ?? Random().nextInt(1 << 31));
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
  }) {
    final rnd = Random(seed);

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

    // 2) Seviye + model seçimi
    final used = <int>{};
    final slots = <ArabaSlot>[];
    var cursor = baseYear;
    var prevLevel = 0;
    for (var i = 0; i < rangeCount; i++) {
      final start = cursor;
      final end = cursor + lengths[i] - 1;
      final offset = start - baseYear;

      int target;
      if (i == 0) {
        target = _firstLevel(rnd, age);
      } else {
        target = prevLevel + _weightedInt(rnd, const [(-1, 3), (0, 30), (1, 40), (2, 27)]);
      }
      target = target.clamp(1, 6);

      final car = _pickCar(rnd, pool, gender, used, target: target, startYear: start, offset: offset);
      used.add(car.id);
      prevLevel = car.level;
      slots.add(ArabaSlot(start, end, car.id));
      cursor = end + 1;

      if (i == gapAfter) {
        slots.add(ArabaSlot(cursor, cursor + gapLen - 1, null));
        cursor += gapLen;
      }
    }
    return ArabaTimeline(seed: seed, baseYear: baseYear, signature: gender, slots: slots);
  }

  static int _firstLevel(Random rnd, int age) {
    if (age < 25) return _weightedInt(rnd, const [(1, 70), (2, 30)]);
    if (age <= 40) return _weightedInt(rnd, const [(2, 25), (3, 45), (4, 30)]);
    return _weightedInt(rnd, const [(3, 30), (4, 45), (5, 25)]);
  }

  static ArabaCar _pickCar(
    Random rnd,
    List<ArabaCar> pool,
    String gender,
    Set<int> used, {
    required int target,
    required int startYear,
    required int offset,
  }) {
    // Kategori: F (2040+) → elektrik → akaryakıt/hibrit
    final pFuture = startYear < 2040 ? 0.0 : (offset >= 25 ? 0.25 : 0.12);
    final pElectric = offset < 8 ? 0.03 : offset < 15 ? 0.12 : offset < 25 ? 0.35 : 0.65;
    var cat = 'K';
    final r = rnd.nextDouble();
    if (r < pFuture && target <= 5) {
      cat = 'F';
    } else if (r < pFuture + pElectric) {
      cat = 'E';
    }

    List<ArabaCar> cands;
    if (cat == 'F') {
      cands = pool.where((c) => c.tier == 'F' && !used.contains(c.id)).toList();
    } else if (cat == 'E') {
      final e = (target - 2).clamp(1, 4);
      cands = pool.where((c) => c.tier == 'E$e' && !used.contains(c.id)).toList();
    } else {
      var k = target;
      // K7 (süper lüks) çok nadir ve yalnız ileri yıllarda
      if (offset >= 15 && target >= 5 && rnd.nextDouble() < 0.025) k = 7;
      cands = pool.where((c) => c.tier == 'K$k' && !used.contains(c.id)).toList();
    }
    if (cands.isEmpty) {
      // Yedek: aynı seviyeli, kullanılmamış, F olmayan herhangi biri (F kuralı bozulmasın)
      cands = pool.where((c) => !used.contains(c.id) && c.tier != 'F' && c.level == target).toList();
      if (cands.isEmpty) cands = pool.where((c) => !used.contains(c.id) && c.tier != 'F').toList();
    }
    final want = gender == 'kadin' ? 'kadin' : gender == 'erkek' ? 'erkek' : '';
    final weights = [for (final c in cands) (want.isNotEmpty && c.lean == want) ? 1.8 : 1.0];
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
        'hidrojen' => en ? 'Hydrogen' : 'Hidrojen',
        _ => k,
      };
}
