// lib/core/services/kehanet_hak.dart
//
// Kehanet menüsü günlük giriş hakkı (docs/reklam_duzeni.md): günde 3 ücretsiz giriş; bitince kullanıcı
// isterse ödüllü reklamla 3 giriş daha. Sınır reklamdan bağımsızdır (diğer günlük haklar gibi).

import 'package:shared_preferences/shared_preferences.dart';

class KehanetHak {
  KehanetHak(this._prefs);

  static const prefsKey = 'kehanet_hak_v1';
  static const gunlukUcretsiz = 3;
  static const odulHakki = 3;

  final SharedPreferences _prefs;

  static String _gun(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int kalan(DateTime now) {
    final kayit = (_prefs.getString(prefsKey) ?? '').split('|');
    if (kayit.length != 2 || kayit[0] != _gun(now)) return gunlukUcretsiz;
    return int.tryParse(kayit[1]) ?? gunlukUcretsiz;
  }

  bool girebilir(DateTime now) => kalan(now) > 0;

  Future<void> _yaz(DateTime now, int deger) => _prefs.setString(prefsKey, '${_gun(now)}|$deger');

  /// Bir giriş düşer (0'ın altına inmez).
  Future<void> kullan(DateTime now) {
    final k = kalan(now);
    return _yaz(now, k > 0 ? k - 1 : 0);
  }

  Future<void> odulEkle(DateTime now) => _yaz(now, kalan(now) + odulHakki);
}
