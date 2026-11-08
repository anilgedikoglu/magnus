// lib/core/magnus_ses/magnus_takvim.dart
//
// Magnus'un takvim farkındalığı: bugün özel bir gün mü? İnternetsiz çalışır.
// Dini günler Diyanet'in yıllık listelerinden alındı (vakithesaplama.diyanet.gov.tr, 2026-11-09).
// Tablo 2030 sonuna kadar; sonrası için yeni liste eklenmezse dini gün karşılaması çıkmaz, başka bir şey bozulmaz.
// Kandiller "gecesi" olan günün tarihiyle yazıldı (Diyanet'in 23/24 gösteriminde ilk gün).

class _Dini {
  const _Dini(this.ay, this.gun, this.anahtar);
  final int ay, gun;
  final String anahtar;
}

const Map<int, List<_Dini>> _kDiniGunler = {
  2026: [_Dini(12, 10, 'regaip')],
  2027: [
    _Dini(1, 4, 'mirac'),
    _Dini(1, 22, 'berat'),
    _Dini(2, 8, 'ramazan_ilk'),
    _Dini(3, 5, 'kadir'),
    _Dini(3, 8, 'arefe_ramazan'),
    _Dini(3, 9, 'ramazan_bayrami'),
    _Dini(3, 10, 'ramazan_bayrami'),
    _Dini(3, 11, 'ramazan_bayrami'),
    _Dini(5, 15, 'arefe_kurban'),
    _Dini(5, 16, 'kurban_bayrami'),
    _Dini(5, 17, 'kurban_bayrami'),
    _Dini(5, 18, 'kurban_bayrami'),
    _Dini(5, 19, 'kurban_bayrami'),
    _Dini(6, 6, 'hicri_yilbasi'),
    _Dini(6, 15, 'asure'),
    _Dini(8, 13, 'mevlid'),
    _Dini(12, 2, 'regaip'),
    _Dini(12, 24, 'mirac'),
  ],
  2028: [
    _Dini(1, 11, 'berat'),
    _Dini(1, 28, 'ramazan_ilk'),
    _Dini(2, 22, 'kadir'),
    _Dini(2, 25, 'arefe_ramazan'),
    _Dini(2, 26, 'ramazan_bayrami'),
    _Dini(2, 27, 'ramazan_bayrami'),
    _Dini(2, 28, 'ramazan_bayrami'),
    _Dini(5, 4, 'arefe_kurban'),
    _Dini(5, 5, 'kurban_bayrami'),
    _Dini(5, 6, 'kurban_bayrami'),
    _Dini(5, 7, 'kurban_bayrami'),
    _Dini(5, 8, 'kurban_bayrami'),
    _Dini(5, 25, 'hicri_yilbasi'),
    _Dini(6, 3, 'asure'),
    _Dini(8, 2, 'mevlid'),
    _Dini(11, 23, 'regaip'),
    _Dini(12, 13, 'mirac'),
    _Dini(12, 30, 'berat'),
  ],
  2029: [
    _Dini(1, 16, 'ramazan_ilk'),
    _Dini(2, 10, 'kadir'),
    _Dini(2, 13, 'arefe_ramazan'),
    _Dini(2, 14, 'ramazan_bayrami'),
    _Dini(2, 15, 'ramazan_bayrami'),
    _Dini(2, 16, 'ramazan_bayrami'),
    _Dini(4, 23, 'arefe_kurban'),
    _Dini(4, 24, 'kurban_bayrami'),
    _Dini(4, 25, 'kurban_bayrami'),
    _Dini(4, 26, 'kurban_bayrami'),
    _Dini(4, 27, 'kurban_bayrami'),
    _Dini(5, 14, 'hicri_yilbasi'),
    _Dini(5, 23, 'asure'),
    _Dini(7, 23, 'mevlid'),
    _Dini(11, 8, 'regaip'),
    _Dini(12, 2, 'mirac'),
    _Dini(12, 20, 'berat'),
  ],
  2030: [
    _Dini(1, 5, 'ramazan_ilk'),
    _Dini(1, 30, 'kadir'),
    _Dini(2, 3, 'arefe_ramazan'),
    _Dini(2, 4, 'ramazan_bayrami'),
    _Dini(2, 5, 'ramazan_bayrami'),
    _Dini(2, 6, 'ramazan_bayrami'),
    _Dini(4, 12, 'arefe_kurban'),
    _Dini(4, 13, 'kurban_bayrami'),
    _Dini(4, 14, 'kurban_bayrami'),
    _Dini(4, 15, 'kurban_bayrami'),
    _Dini(4, 16, 'kurban_bayrami'),
    _Dini(5, 3, 'hicri_yilbasi'),
    _Dini(5, 12, 'asure'),
    _Dini(7, 12, 'mevlid'),
    _Dini(10, 31, 'regaip'),
    _Dini(11, 22, 'mirac'),
    _Dini(12, 9, 'berat'),
    _Dini(12, 26, 'ramazan_ilk'),
  ],
};

/// Ramazan'ın ilk gününden sonraki günler (ilk gün dahil değil), arefe öncesine kadar.
const List<(int, int, int, int, int, int)> _kRamazanlar = [
  (2027, 2, 9, 2027, 3, 7),
  (2028, 1, 29, 2028, 2, 24),
  (2029, 1, 17, 2029, 2, 12),
  (2030, 1, 6, 2030, 2, 2),
];

const Map<String, (int, int)> _kSabitGunler = {
  'yilbasi': (1, 1),
  'sevgililer': (2, 14),
  'kadinlar_gunu': (3, 8),
  'canakkale': (3, 18),
  'nevruz': (3, 21),
  'nisan23': (4, 23),
  'mayis1': (5, 1),
  'mayis19': (5, 19),
  'temmuz15': (7, 15),
  'agustos30': (8, 30),
  'cumhuriyet': (10, 29),
  'ataturk': (11, 10),
  'ogretmenler': (11, 24),
};

/// Burç adı → mevsiminin ilk günü (ay, gün).
const Map<String, (int, int)> _kBurcBaslangic = {
  'koç': (3, 21),
  'boğa': (4, 20),
  'ikizler': (5, 21),
  'yengeç': (6, 22),
  'aslan': (7, 23),
  'başak': (8, 23),
  'terazi': (9, 23),
  'akrep': (10, 23),
  'yay': (11, 22),
  'oğlak': (12, 22),
  'kova': (1, 20),
  'balık': (2, 19),
};

class MagnusTakvim {
  MagnusTakvim._();

  static DateTime _nPazar(int yil, int ay, int n) {
    var d = DateTime(yil, ay);
    while (d.weekday != DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return DateTime(d.year, d.month, d.day + 7 * (n - 1));
  }

  /// Bugün için özel gün anahtarları, öncelik sırasıyla (ilk geçerli olan kullanılır).
  static List<String> ozelGunler(DateTime now, {String? dogumTarihi, String? burc}) {
    final out = <String>[];
    if (_dogumGunuMu(now, dogumTarihi)) out.add('dogum_gunu');
    for (final d in _kDiniGunler[now.year] ?? const <_Dini>[]) {
      if (d.ay == now.month && d.gun == now.day) out.add(d.anahtar);
    }
    _kSabitGunler.forEach((k, v) {
      if (v.$1 == now.month && v.$2 == now.day) out.add(k);
    });
    final anneler = _nPazar(now.year, 5, 2);
    if (now.month == anneler.month && now.day == anneler.day) out.add('anneler_gunu');
    final babalar = _nPazar(now.year, 6, 3);
    if (now.month == babalar.month && now.day == babalar.day) out.add('babalar_gunu');
    final b = _kBurcBaslangic[(burc ?? '').trim().replaceAll('İ', 'i').toLowerCase()];
    if (b != null && b.$1 == now.month && b.$2 == now.day) out.add('burc_sezonu');
    if (_ramazanIcinde(now)) out.add('ramazan');
    return out;
  }

  /// Ramazan ayındayız mı (ilk gün dahil)? Gündüz yemek şakaları bu günlerde çıkmaz.
  static bool ramazanda(DateTime now) {
    if (_ramazanIcinde(now)) return true;
    return (_kDiniGunler[now.year] ?? const <_Dini>[])
        .any((d) => d.anahtar == 'ramazan_ilk' && d.ay == now.month && d.gun == now.day);
  }

  /// Ağırbaşlı günler: Magnus o gün şaka yapmaz, yalnız günün sözünü söyler.
  static String? agirGun(DateTime now) {
    for (final k in const ['ataturk', 'canakkale', 'temmuz15']) {
      final v = _kSabitGunler[k]!;
      if (v.$1 == now.month && v.$2 == now.day) return k;
    }
    return null;
  }

  static bool _ramazanIcinde(DateTime now) {
    final g = DateTime(now.year, now.month, now.day);
    for (final (y1, a1, d1, y2, a2, d2) in _kRamazanlar) {
      if (!g.isBefore(DateTime(y1, a1, d1)) && !g.isAfter(DateTime(y2, a2, d2))) return true;
    }
    return false;
  }

  static bool _dogumGunuMu(DateTime now, String? dogumTarihi) {
    if (dogumTarihi == null || dogumTarihi.isEmpty) return false;
    final d = DateTime.tryParse(dogumTarihi);
    return d != null && d.month == now.month && d.day == now.day;
  }

  static String mevsim(int ay) {
    if (ay >= 3 && ay <= 5) return 'ilkbahar';
    if (ay >= 6 && ay <= 8) return 'yaz';
    if (ay >= 9 && ay <= 11) return 'sonbahar';
    return 'kis';
  }
}
