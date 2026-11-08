// lib/core/magnus_ses/magnus_hafiza.dart
//
// Magnus'un cihazda tuttuğu kullanım hafızası: kaçıncı geliş, kaç gündür gelmedi, hangi fala girip
// çıktı. Yalnız SharedPreferences'ta durur, hiçbir yere gönderilmez.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GirisBilgisi {
  const GirisBilgisi({
    required this.ilkKez,
    required this.bugunKacinci,
    required this.araGun,
    required this.seri,
  });
  final bool ilkKez;
  final int bugunKacinci;
  final int araGun; // son gelişten bu yana geçen gün
  final int seri; // art arda gelinen gün
}

class FalKaydi {
  FalKaydi();
  int acilis = 0;
  int tamam = 0;
  String? gun; // sayaçların ait olduğu gün
  int bugunAcilis = 0;
  int bugunVazgecti = 0;

  Map<String, dynamic> toJson() => {
        'a': acilis,
        't': tamam,
        'g': gun,
        'ba': bugunAcilis,
        'bv': bugunVazgecti,
      };

  static FalKaydi fromJson(Map<String, dynamic> j) => FalKaydi()
    ..acilis = (j['a'] as num?)?.toInt() ?? 0
    ..tamam = (j['t'] as num?)?.toInt() ?? 0
    ..gun = j['g'] as String?
    ..bugunAcilis = (j['ba'] as num?)?.toInt() ?? 0
    ..bugunVazgecti = (j['bv'] as num?)?.toInt() ?? 0;
}

class MagnusHafiza {
  MagnusHafiza(this._prefs) {
    _oku();
  }

  static const anahtar = 'magnus_hafiza_v1';

  /// Ana menü açıkken etkin hafıza (gelen kutusu okumayı buraya yazar).
  static MagnusHafiza? aktif;
  final SharedPreferences _prefs;

  DateTime? _ilk;
  DateTime? _son;
  String? _gun;
  int _bugunGiris = 0;
  int _seri = 0;
  int _saniyeBugun = 0;
  bool ilkFalDendi = false;
  int _tamamFal = 0; // tamamlanan (anlık fal ≥25 sn) + okunan (gelen kutusu) fal sayısı; reklam sıklığı için
  bool _eskiKullanici = false; // hafıza gelmeden önce de uygulamayı kullanıyordu
  final Map<String, FalKaydi> _fallar = {};
  final List<(String, DateTime)> _sonAcilislar = [];
  (String, DateTime)? sonOkunan;

  static String gunAnahtari(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _gunFarki(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  void _oku() {
    final raw = _prefs.getString(anahtar);
    if (raw == null) {
      // Bu sürümden önce de uygulamayı kullanan kişi "ilk kez gelmiş" sayılmaz.
      if (_prefs.getBool('ilk_giris_yapildi') ?? false) {
        _ilk = DateTime.now();
        _eskiKullanici = true;
        ilkFalDendi = true;
      }
      return;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _ilk = DateTime.tryParse(j['ilk'] as String? ?? '');
      _son = DateTime.tryParse(j['son'] as String? ?? '');
      _gun = j['gun'] as String?;
      _bugunGiris = (j['bg'] as num?)?.toInt() ?? 0;
      _seri = (j['seri'] as num?)?.toInt() ?? 0;
      _saniyeBugun = (j['sn'] as num?)?.toInt() ?? 0;
      ilkFalDendi = j['ifd'] as bool? ?? false;
      _tamamFal = (j['tf'] as num?)?.toInt() ?? 0;
      _eskiKullanici = j['eski'] as bool? ?? false;
      (j['fal'] as Map<String, dynamic>? ?? const {}).forEach((k, v) {
        _fallar[k] = FalKaydi.fromJson(v as Map<String, dynamic>);
      });
    } catch (_) {
      // Bozuk kayıt: sıfırdan başlanır, uygulama etkilenmez.
    }
  }

  void kaydet() {
    _prefs.setString(
      anahtar,
      jsonEncode({
        'ilk': _ilk?.toIso8601String(),
        'son': _son?.toIso8601String(),
        'gun': _gun,
        'bg': _bugunGiris,
        'seri': _seri,
        'sn': _saniyeBugun,
        'ifd': ilkFalDendi,
        'tf': _tamamFal,
        'eski': _eskiKullanici,
        'fal': _fallar.map((k, v) => MapEntry(k, v.toJson())),
      }),
    );
  }

  /// Uygulamaya her geliş (açılış ya da arka plandan dönüş).
  GirisBilgisi girisKaydet(DateTime now) {
    final ilkKez = _ilk == null;
    final araGun = _son == null ? 0 : _gunFarki(_son!, now);
    if (_gun != gunAnahtari(now)) _yeniGun(now, araGun);
    _bugunGiris++;
    _ilk ??= now;
    _son = now;
    kaydet();
    return GirisBilgisi(ilkKez: ilkKez, bugunKacinci: _bugunGiris, araGun: araGun, seri: _seri);
  }

  void _yeniGun(DateTime now, int araGun) {
    _gun = gunAnahtari(now);
    _bugunGiris = 0;
    _saniyeBugun = 0;
    _seri = araGun == 1 ? _seri + 1 : 1;
  }

  void sureEkle(Duration d, DateTime now) {
    // Gece yarısını geçen oturumda yeni gün burada başlar; seri kaybolmasın.
    if (_gun != gunAnahtari(now)) _yeniGun(now, _son == null ? 0 : _gunFarki(_son!, now));
    _saniyeBugun += d.inSeconds;
    _son = now;
    kaydet();
  }

  int get saniyeBugun => _saniyeBugun;

  FalKaydi kayit(String tur, DateTime now) {
    final k = _fallar.putIfAbsent(tur, FalKaydi.new);
    final bugun = gunAnahtari(now);
    if (k.gun != bugun) {
      k.gun = bugun;
      k.bugunAcilis = 0;
      k.bugunVazgecti = 0;
    }
    return k;
  }

  void falGirdi(String tur, DateTime now) {
    final k = kayit(tur, now);
    k.acilis++;
    k.bugunAcilis++;
    _sonAcilislar.add((tur, now));
    if (_sonAcilislar.length > 12) _sonAcilislar.removeAt(0);
    kaydet();
  }

  void falCikti(String tur, DateTime now, {required bool vazgecti, required bool tamam}) {
    final k = kayit(tur, now);
    if (vazgecti) k.bugunVazgecti++;
    if (tamam) k.tamam++;
    kaydet();
  }

  /// Gelen kutusundan okunan her fal bir tamamlanan fal sayılır.
  void okundu(String tur, DateTime now) {
    sonOkunan = (tur, now);
    _tamamFal++;
    kaydet();
  }

  /// Ekranda sonucu gösteren (anlık) bir fal yeterince süre açık kalıp kapandı.
  void falTamamlandi() {
    _tamamFal++;
    kaydet();
  }

  /// Uygulamada toplam tamamlanan/okunan fal (geçiş reklamı için "ilk 2 fal" eşiği).
  int get tamamlananFal => _tamamFal;

  /// Son 5 dakikada kaç farklı türe girildi?
  int sonFarkliTur(DateTime now) => _sonAcilislar
      .where((e) => now.difference(e.$2).inMinutes < 5)
      .map((e) => e.$1)
      .toSet()
      .length;

  bool hicAcilmadi(String tur) => (_fallar[tur]?.acilis ?? 0) == 0;

  /// "Hiç denemedin" diyebilmek için yeterince gözlem var mı? Eski kullanıcının geçmişi bilinmez.
  bool oneriyeHazir(DateTime now) => _ilk != null && _gunFarki(_ilk!, now) >= (_eskiKullanici ? 30 : 7);

  bool bugunAcildi(String tur, DateTime now) => kayit(tur, now).bugunAcilis > 0;

  /// En çok açılan ama bugün açılmayan tür (en az 3 kez açılmış olmalı).
  String? sevilipBugunAcilmayan(DateTime now, Iterable<String> turler) {
    String? en;
    var enCok = 2;
    for (final t in turler) {
      final k = kayit(t, now);
      if (k.bugunAcilis == 0 && k.acilis > enCok) {
        enCok = k.acilis;
        en = t;
      }
    }
    return en;
  }
}
