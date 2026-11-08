// lib/core/services/ad_pacing.dart
//
// Reklam sıklık sınırları (docs/reklam_duzeni.md). Sayaçlar SharedPreferences'ta KALICIDIR
// (uygulama kapanınca sıfırlanmaz). Saf mantık: saat dışarıdan verilir, test edilebilir.
//
// Geçiş reklamı : en az 180 sn aralık, oturumda 2, günde 5; uygulamada 2 fal tamamlanmadan yok.
// Ödüllü        : hak bitti +1 tür başına 1 ve günde toplam 3; hemen aç günde 3; kutu açma günde 6;
//                 hepsi toplam günde 10.
// Saat geri alınırsa: gün sayaçları sıfırlanmaz (kullanıcı saati oynayarak sınırı aşamaz) ve son
// geçiş "gelecekte" kalmışsa o an sınırı doldurulmuş sayılır; saat yeniden ilerleyince kendiliğinden düzelir.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Ödüllü reklamın ne için sunulduğu (sınırlar türe göre ayrı).
enum OdulTuru { hakBitti, hemenAc, kutuAc }

class AdPacing {
  AdPacing(this._prefs) {
    _oku();
  }

  static const prefsKey = 'ad_pacing_v1';

  // ── Geçiş sınırları ──
  static const gecisAraligi = Duration(seconds: 180);
  static const gecisOturumMax = 2;
  static const gecisGunMax = 5;
  static const gecisIcinMinFal = 2;

  // ── Ödüllü sınırları ──
  static const hakBittiTurBasina = 1;
  static const hakBittiGunMax = 3;
  static const hemenAcGunMax = 3;
  static const kutuAcGunMax = 6;
  static const odulToplamGunMax = 10;

  /// Geçiş reklamı için fal en az bu kadar açık kalmış olmalı.
  static const gecisIcinMinSure = Duration(seconds: 25);

  /// Doğal ara mı? Fal ekranı kapanıp menüye dönüyor, süre yeterli, Dert Ortağı değil.
  static bool dogalAraMi(String falTuru, Duration sure, {required bool menuyeDonuyor}) =>
      menuyeDonuyor && falTuru != 'dertortagi' && sure >= gecisIcinMinSure;

  final SharedPreferences _prefs;

  String? _gun;
  int _gecisBugun = 0;
  int _sonGecisMs = 0;
  final Map<String, int> _odul = {};
  final Set<String> _hakBittiTurleri = {};

  /// Bu uygulama çalışmasında gösterilen geçiş sayısı (kalıcı DEĞİL: "oturum").
  int oturumGecis = 0;

  static String gunAnahtari(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _oku() {
    final raw = _prefs.getString(prefsKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _gun = j['d'] as String?;
      _gecisBugun = (j['ig'] as num?)?.toInt() ?? 0;
      _sonGecisMs = (j['li'] as num?)?.toInt() ?? 0;
      (j['r'] as Map<String, dynamic>? ?? const {}).forEach((k, v) => _odul[k] = (v as num).toInt());
      _hakBittiTurleri.addAll((j['hb'] as List? ?? const []).map((e) => '$e'));
    } catch (_) {
      // Bozuk kayıt: sıfırdan başlanır.
    }
  }

  Future<void> _yaz() => _prefs.setString(
        prefsKey,
        jsonEncode({
          'd': _gun,
          'ig': _gecisBugun,
          'li': _sonGecisMs,
          'r': _odul,
          'hb': _hakBittiTurleri.toList(),
        }),
      );

  /// Gün değiştiyse sayaçları sıfırlar; saat geri gittiyse sıfırlamaz.
  /// Gelecekteki "son geçiş" zamanı bugüne çekilir (sınır dolu kalır, sonra kendiliğinden açılır).
  void _normalize(DateTime now) {
    final bugun = gunAnahtari(now);
    if (_gun == null) {
      _gun = bugun;
    } else if (_gun!.compareTo(bugun) < 0) {
      _gun = bugun;
      _gecisBugun = 0;
      _odul.clear();
      _hakBittiTurleri.clear();
    }
    // _gun > bugün → saat geri alındı: sayaçlar korunur.
    final ms = now.millisecondsSinceEpoch;
    if (_sonGecisMs > ms) _sonGecisMs = ms;
  }

  int _o(String k) => _odul[k] ?? 0;
  int get _odulToplam => _o('hakBitti') + _o('hemenAc') + _o('kutuAc');

  // ── Geçiş ──

  bool canShowInterstitial(DateTime now, {required int tamamlananFal}) {
    _normalize(now);
    if (tamamlananFal < gecisIcinMinFal) return false;
    if (oturumGecis >= gecisOturumMax) return false;
    if (_gecisBugun >= gecisGunMax) return false;
    if (_sonGecisMs != 0 &&
        now.millisecondsSinceEpoch - _sonGecisMs < gecisAraligi.inMilliseconds) {
      return false;
    }
    return true;
  }

  Future<void> recordInterstitial(DateTime now) {
    _normalize(now);
    _gecisBugun++;
    oturumGecis++;
    _sonGecisMs = now.millisecondsSinceEpoch;
    return _yaz();
  }

  // ── Ödüllü ──

  bool canOfferReward(OdulTuru tur, DateTime now, {String? falTuru}) {
    _normalize(now);
    if (_odulToplam >= odulToplamGunMax) return false;
    switch (tur) {
      case OdulTuru.hakBitti:
        if (_o('hakBitti') >= hakBittiGunMax) return false;
        if (falTuru != null && _hakBittiTurleri.contains(falTuru)) return false;
        return true;
      case OdulTuru.hemenAc:
        return _o('hemenAc') < hemenAcGunMax;
      case OdulTuru.kutuAc:
        return _o('kutuAc') < kutuAcGunMax;
    }
  }

  Future<void> recordReward(OdulTuru tur, DateTime now, {String? falTuru}) {
    _normalize(now);
    _odul[tur.name] = _o(tur.name) + 1;
    if (tur == OdulTuru.hakBitti && falTuru != null) _hakBittiTurleri.add(falTuru);
    return _yaz();
  }
}
