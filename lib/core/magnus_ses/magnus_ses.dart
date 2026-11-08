// lib/core/magnus_ses/magnus_ses.dart
//
// Magnus'un sesi: cihazda çalışan, kuralla işleyen seçim beyni. Hafızaya, takvime, gelen kutusuna ve
// profile bakıp o an ne söyleyeceğine karar verir. Metinler assets/data/magnus_ses.json'da.
// Aynı havuzdaki metin, uygun olanlar bitmeden tekrar gösterilmez.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/inbox_item.dart';
import '../../data/models/user_profile.dart';
import '../utils/variable_replacer.dart';
import 'magnus_fal_adlari.dart';
import 'magnus_hafiza.dart';
import 'magnus_takvim.dart';

class SesMetni {
  const SesMetni(this.id, this.metin, this.metinEn, this.grup, this.kosullar);
  final String id;
  final String metin;
  final String metinEn;
  final String grup;
  final List<Map<String, String>> kosullar;

  static SesMetni fromJson(Map<String, dynamic> j, String grup) => SesMetni(
        '${j['id']}',
        j['metin'] as String,
        j['metin_en'] as String,
        j['grup'] as String? ?? grup,
        [
          for (final k in j['kosullar'] as List? ?? const [])
            {'degisken': '${k['degisken']}', 'deger': '${k['deger']}'}
        ],
      );
}

/// Metin seçerken gereken anlık durum.
class MagnusBaglam {
  const MagnusBaglam({
    required this.now,
    required this.profile,
    required this.isEn,
    required this.gelenKutusu,
    this.oturumSaniye = 0,
  });
  final DateTime now;
  final UserProfile profile;
  final bool isEn;
  final List<InboxItem> gelenKutusu;
  final int oturumSaniye; // bu oturumda henüz hafızaya yazılmamış süre
}

enum DonusKaynagi { gelenKutusu, profil }

class MagnusSes {
  MagnusSes(this._prefs, this.hafiza, {Random? rng}) : _rng = rng ?? Random();

  final SharedPreferences _prefs;
  final MagnusHafiza hafiza;
  final Random _rng;

  List<SesMetni> _donus = const [];
  List<SesMetni> _giris = const [];
  Map<String, List<SesMetni>> _ozel = const {};
  Map<String, List<SesMetni>> _durum = const {};

  DateTime? _sonKonusma;
  String? _sonGrup;
  String? _sonHam; // farklı havuzlarda aynı cümle varsa üst üste gelmesin
  bool _uzunKaldiDendi = false;
  bool _cokUzunDendi = false;
  bool _geceDendi = false;

  /// Dönüşte en az bu kadar aralıkla konuşur.
  static const donusAraligi = Duration(seconds: 40);

  Future<void> yukle() async => yukleMetin(await rootBundle.loadString('assets/data/magnus_ses.json'));

  void yukleMetin(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    List<SesMetni> liste(List<dynamic> l, String g) =>
        [for (final e in l) SesMetni.fromJson(e as Map<String, dynamic>, g)];
    Map<String, List<SesMetni>> harita(Map<String, dynamic> m) =>
        m.map((k, v) => MapEntry(k, liste(v as List, k)));
    _donus = liste(j['donus'] as List, 'genel');
    _giris = liste(j['giris'] as List, 'genel');
    _ozel = harita(j['ozel'] as Map<String, dynamic>);
    _durum = harita(j['durum'] as Map<String, dynamic>);
  }

  // ── Koşullar ──────────────────────────────────────────────────────────────

  static String vakit(int saat) {
    if (saat >= 5 && saat < 12) return 'sabah';
    if (saat >= 12 && saat < 17) return 'ogle';
    if (saat >= 17 && saat < 22) return 'aksam';
    return 'gece';
  }

  static String _sade(String s) => s
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(' ', '')
      .replaceAll('_', '');

  static bool _medeniUyar(String beklenen, String gercek) {
    final g = _sade(gercek);
    return switch (_sade(beklenen)) {
      'evli' => g == 'evli',
      'iliskisivar' => g.startsWith('iliskisivar') || g == 'iliskivar' || g == 'nisanli' || g == 'flort',
      'iliskisiyok' => g.startsWith('iliskisiyok') || g == 'bekar' || g == 'iliskiyok' || g == 'bosanmis' || g == 'dul',
      final b => b == g,
    };
  }

  static bool _meslekUyar(String beklenen, String gercek) {
    final b = _sade(beklenen), g = _sade(gercek);
    if (b == g) return true;
    return g.startsWith(b) || b.startsWith(g) && g.isNotEmpty;
  }

  bool _uyar(SesMetni m, MagnusBaglam b) {
    final gruplar = <String, List<String>>{};
    for (final k in m.kosullar) {
      gruplar.putIfAbsent(k['degisken']!, () => []).add(k['deger']!);
    }
    final p = b.profile;
    return gruplar.entries.every((g) => g.value.any((v) => switch (g.key) {
          'vakit' => vakit(b.now.hour) == v,
          'hafta_gunu' => '${b.now.weekday}' == v,
          'ay' => '${b.now.month}' == v,
          'mevsim' => MagnusTakvim.mevsim(b.now.month) == v,
          'ramazan_disi' => !MagnusTakvim.ramazanda(b.now),
          'cinsiyet' => _sade(p.gender) == _sade(v),
          'medeni_durum' => _medeniUyar(v, p.maritalStatus),
          'meslek' => _meslekUyar(v, p.job),
          'yasmax' => p.age > 0 && p.age <= (int.tryParse(v) ?? 0),
          'yasmin' => p.age >= (int.tryParse(v) ?? 999),
          _ => false,
        }));
  }

  bool _gosterilebilir(SesMetni m, MagnusBaglam b, Map<String, String> ekler) {
    final t = b.isEn ? m.metinEn : m.metin;
    if (t == _sonHam || !_uyar(m, b)) return false;
    if (b.profile.name.trim().isEmpty && t.contains('{{isim')) return false;
    if ((b.profile.zodiacSign ?? '').isEmpty && t.contains('{{burc')) return false;
    for (final k in const ['fal', 'fali', 'fala', 'faldan', 'falin', 'suredir', 'kalan', 'adet', 'ziyaret', 'seri', 'ara_gun', 'app_dakika']) {
      if (t.contains('{{$k}}') && !ekler.containsKey(k)) return false;
    }
    return true;
  }

  // ── Tekrarsız seçim ───────────────────────────────────────────────────────

  String? _sec(String anahtar, List<SesMetni> havuz, MagnusBaglam b, Map<String, String> ekler) {
    final uygun = [for (final m in havuz) if (_gosterilebilir(m, b, ekler)) m];
    if (uygun.isEmpty) return null;
    final kayit = 'ses_goster_$anahtar';
    final gosterilen = _prefs.getStringList(kayit) ?? <String>[];
    var kalan = uygun.where((m) => !gosterilen.contains(m.id)).toList();
    var yeni = gosterilen;
    if (kalan.isEmpty) {
      // Yalnız şu an uygun olanlar sıfırlanır; başka gün/vakit metinlerinin kaydı kalır.
      final uygunIdler = {for (final m in uygun) m.id};
      final son = gosterilen.lastWhere(uygunIdler.contains, orElse: () => '');
      yeni = [...gosterilen.where((id) => !uygunIdler.contains(id)), if (son.isNotEmpty) son];
      kalan = uygun.where((m) => m.id != son).toList();
      if (kalan.isEmpty) kalan = uygun;
    }
    final m = kalan[_rng.nextInt(kalan.length)];
    _prefs.setStringList(kayit, [...yeni, m.id]);
    _sonGrup = m.grup;
    _sonHam = b.isEn ? m.metinEn : m.metin;
    _sonKonusma = b.now;
    return VariableReplacer.replace(b.isEn ? m.metinEn : m.metin, {...b.profile.toVariableMap(), ...ekler});
  }

  String? _durumSoyle(String anahtar, MagnusBaglam b, [Map<String, String> ekler = const {}]) {
    final havuz = _durum[anahtar];
    if (havuz == null) return null;
    return _sec('durum_$anahtar', havuz, b, ekler);
  }

  String? _havuzdan(String ad, List<SesMetni> havuz, String grup, MagnusBaglam b, Map<String, String> ekler) =>
      _sec('${ad}_$grup', havuz.where((m) => m.grup == grup).toList(), b, ekler);

  /// Ağırlıklı karıştırılmış grup sırası; bir önceki grup en sona alınır.
  List<String> _sira(Map<String, double> agirlik) {
    final kalan = Map<String, double>.of(agirlik);
    final out = <String>[];
    while (kalan.isNotEmpty) {
      final toplam = kalan.values.fold<double>(0, (a, b) => a + b);
      var x = _rng.nextDouble() * toplam;
      var secilen = kalan.keys.last;
      for (final e in kalan.entries) {
        x -= e.value;
        if (x <= 0) {
          secilen = e.key;
          break;
        }
      }
      out.add(secilen);
      kalan.remove(secilen);
    }
    if (out.length > 1 && out.first == _sonGrup) out.add(out.removeAt(0));
    return out;
  }

  bool _zar(double olasilik) => _rng.nextDouble() < olasilik;

  // ── Değişkenler ───────────────────────────────────────────────────────────

  Map<String, String> _falEkleri(String tur, bool isEn) {
    final a = kFalAdlari[tur];
    if (a == null) return const {};
    return isEn
        ? {'fal': a.en, 'fali': a.en, 'fala': a.en, 'faldan': a.en, 'falin': a.en}
        : {'fal': a.yalin, 'fali': a.belirtme, 'fala': a.yonelme, 'faldan': a.ayrilma, 'falin': a.tamlayan};
  }

  static String suredir(Duration d, bool isEn) {
    if (d.inMinutes < 60) {
      final m = max(1, d.inMinutes);
      return isEn ? 'for $m ${m == 1 ? 'minute' : 'minutes'}' : '$m dakikadır';
    }
    if (d.inHours < 24) {
      final h = d.inHours;
      return isEn ? 'for $h ${h == 1 ? 'hour' : 'hours'}' : '$h saattir';
    }
    final g = d.inDays;
    return isEn ? 'for $g ${g == 1 ? 'day' : 'days'}' : '$g gündür';
  }

  static String kalanSure(Duration d, bool isEn) {
    if (d.inMinutes < 60) {
      final m = max(1, d.inMinutes + (d.inSeconds % 60 > 0 ? 1 : 0));
      return isEn ? '$m ${m == 1 ? 'minute' : 'minutes'}' : '$m dakika';
    }
    final h = d.inHours;
    return isEn ? '$h ${h == 1 ? 'hour' : 'hours'}' : '$h saat';
  }

  int _dakikaBugun(MagnusBaglam b) => (hafiza.saniyeBugun + b.oturumSaniye) ~/ 60;

  // ── Gelen kutusu farkındalığı ─────────────────────────────────────────────

  static DateTime? _hazirOlmaAni(InboxItem i) =>
      DateTime.tryParse(i.unlockAt ?? '') ?? DateTime.tryParse(i.date);

  String? _gelenKutusuYorumu(MagnusBaglam b, {required double olasilik}) {
    final okunmamis = b.gelenKutusu.where((i) => !i.isRead && !i.isLocked).toList();
    if (okunmamis.length >= 2 && _zar(olasilik)) {
      final s = _durumSoyle('okunmadi_cok', b, {'adet': '${okunmamis.length}'});
      if (s != null) return s;
    }
    if (okunmamis.isNotEmpty && _zar(olasilik)) {
      okunmamis.sort((x, y) => (_hazirOlmaAni(x) ?? b.now).compareTo(_hazirOlmaAni(y) ?? b.now));
      final en = okunmamis.first;
      final tur = falTuruGelenKutusu(en.fortuneTypeKey);
      final an = _hazirOlmaAni(en);
      if (tur != null && an != null && b.now.difference(an).inMinutes >= 30) {
        final s = _durumSoyle('okunmadi', b, {..._falEkleri(tur, b.isEn), 'suredir': suredir(b.now.difference(an), b.isEn)});
        if (s != null) return s;
      }
    }
    final kilitli = b.gelenKutusu.where((i) => i.isLocked).toList();
    if (kilitli.isNotEmpty && _zar(olasilik * 0.7)) {
      kilitli.sort((x, y) => x.unlockAt!.compareTo(y.unlockAt!));
      final en = kilitli.first;
      final tur = falTuruGelenKutusu(en.fortuneTypeKey);
      final an = DateTime.tryParse(en.unlockAt!);
      if (tur != null && an != null) {
        final s = _durumSoyle('hazirlaniyor', b, {..._falEkleri(tur, b.isEn), 'kalan': kalanSure(an.difference(b.now), b.isEn)});
        if (s != null) return s;
      }
    }
    return null;
  }

  // ── Açılış ────────────────────────────────────────────────────────────────

  /// Uygulama açılışı / arka plandan dönüş karşılaması.
  String? giris(MagnusBaglam b, GirisBilgisi g) {
    final ekler = {
      'ziyaret': '${g.bugunKacinci}',
      'seri': '${g.seri}',
      'ara_gun': '${g.araGun}',
    };
    String? grup(String ad) => _havuzdan('giris', _giris, ad, b, ekler);

    final agir = MagnusTakvim.agirGun(b.now);
    if (agir != null) {
      final havuz = _ozel[agir];
      return havuz == null ? null : _sec('ozel_$agir', havuz, b, ekler);
    }
    if (g.ilkKez) return grup('ilk_kez') ?? grup('genel');

    if (g.bugunKacinci == 1) {
      for (final k in MagnusTakvim.ozelGunler(b.now, dogumTarihi: b.profile.birthDate, burc: b.profile.zodiacSign)) {
        final havuz = _ozel[k];
        if (havuz == null) continue;
        final s = _sec('ozel_$k', havuz, b, ekler);
        if (s != null) return s;
      }
      if (g.araGun >= 30) {
        final s = grup('uzun_ara_cok');
        if (s != null) return s;
      } else if (g.araGun >= 7) {
        final s = grup('uzun_ara');
        if (s != null) return s;
      } else if (g.araGun >= 2) {
        final s = grup('uzun_ara_kisa');
        if (s != null) return s;
      }
    }

    final kutu = _gelenKutusuYorumu(b, olasilik: 0.55);
    if (kutu != null) return kutu;

    if (g.bugunKacinci == 1 && g.seri >= 3 && _zar(0.3)) {
      final s = grup('seri');
      if (s != null) return s;
    }
    if (g.bugunKacinci >= 2 && _zar(0.75)) {
      final s = grup(g.bugunKacinci >= 6 ? 'ziyaret_cok' : 'ziyaret_${g.bugunKacinci}');
      if (s != null) return s;
    }

    final sira = _sira(g.bugunKacinci == 1
        ? const {'vakit': 34, 'gun': 28, 'genel': 26, 'kisi': 8, 'mevsim': 4}
        : const {'genel': 50, 'vakit': 34, 'kisi': 12, 'mevsim': 4});
    for (final ad in [...sira, 'genel']) {
      final s = grup(ad);
      if (s != null) return s;
    }
    return null;
  }

  // ── Sekmeden ana menüye dönüş ─────────────────────────────────────────────

  /// Gelen Kutusu ya da Kullanıcı Bilgileri'nden dönüş; arada bir konuşur, çoğu kez susar.
  String? sekmeDonus(MagnusBaglam b, DonusKaynagi kaynak) {
    if (MagnusTakvim.agirGun(b.now) != null) return null;
    final son = _sonKonusma;
    if (son != null && b.now.difference(son) < donusAraligi) return null;

    final okunan = hafiza.sonOkunan;
    if (kaynak == DonusKaynagi.gelenKutusu && okunan != null && b.now.difference(okunan.$2).inMinutes < 10) {
      hafiza.sonOkunan = null;
      if (_zar(0.85)) {
        final s = _durumSoyle('memnun', b, _falEkleri(okunan.$1, b.isEn));
        if (s != null) return s;
      }
    }

    if (!hafiza.ilkFalDendi && b.gelenKutusu.isNotEmpty) {
      hafiza.ilkFalDendi = true;
      hafiza.kaydet();
      final s = _durumSoyle('ilk_fal', b);
      if (s != null) return s;
    }

    if (!_zar(0.5)) return null; // her dönüşte değil

    final saat = b.now.hour;
    if (saat < 5 && !_geceDendi) {
      _geceDendi = true;
      final s = _durumSoyle('gece_kusu', b);
      if (s != null) return s;
    }
    final dk = _dakikaBugun(b);
    if (dk >= 45 && !_cokUzunDendi) {
      _cokUzunDendi = true;
      final s = _durumSoyle('cok_uzun_kaldi', b, {'app_dakika': '$dk'});
      if (s != null) return s;
    } else if (dk >= 15 && !_uzunKaldiDendi) {
      _uzunKaldiDendi = true;
      final s = _durumSoyle('uzun_kaldi', b, {'app_dakika': '$dk'});
      if (s != null) return s;
    }

    final kutu = _gelenKutusuYorumu(b, olasilik: 0.45);
    if (kutu != null) return kutu;

    if (kaynak == DonusKaynagi.gelenKutusu && _zar(0.35)) {
      final bos = b.gelenKutusu.isEmpty;
      final hepsi = b.gelenKutusu.any((i) => i.isRead) && b.gelenKutusu.every((i) => i.isRead || i.isLocked);
      final s = bos ? _durumSoyle('inbox_bos', b) : (hepsi ? _durumSoyle('inbox_donus', b) : null);
      if (s != null) return s;
    }
    if (kaynak == DonusKaynagi.profil && _zar(0.35)) {
      final s = _durumSoyle('profil_donus', b);
      if (s != null) return s;
    }

    final sevilen = hafiza.sevilipBugunAcilmayan(b.now, kFalAdlari.keys);
    if (sevilen != null && _zar(0.25)) {
      final s = _durumSoyle('oneri_bugun', b, _falEkleri(sevilen, b.isEn));
      if (s != null) return s;
    }
    final hic = kFalAdlari.keys.where(hafiza.hicAcilmadi).toList();
    if (hic.isNotEmpty && hafiza.oneriyeHazir(b.now) && _zar(0.2)) {
      final s = _durumSoyle('oneri_hic', b, _falEkleri(hic[_rng.nextInt(hic.length)], b.isEn));
      if (s != null) return s;
    }

    final ekler = <String, String>{};
    for (final ad in _sira(const {'genel': 30, 'davet': 27, 'mistik': 20, 'esprili': 18, 'vakit': 5})) {
      final s = _havuzdan('donus', _donus, ad, b, ekler);
      if (s != null) return s;
    }
    return null;
  }

  // ── Fal ekranından dönüş ──────────────────────────────────────────────────

  /// Fal ekranından menüye dönüşteki tepki; söyleyecek bir şey yoksa null.
  String? falDonus(MagnusBaglam b, String tur, Duration sure, {required bool vazgecti}) {
    if (MagnusTakvim.agirGun(b.now) != null) return null;
    final k = hafiza.kayit(tur, b.now);
    final ekler = _falEkleri(tur, b.isEn);
    if (vazgecti) {
      if (k.bugunVazgecti >= 2 && _zar(0.8)) {
        final s = _durumSoyle('vazgecti_tekrar', b, ekler);
        if (s != null) return s;
      }
      if (_zar(0.7)) {
        final s = _durumSoyle('vazgecti', b, ekler);
        if (s != null) return s;
      }
    }
    if (hafiza.sonFarkliTur(b.now) >= 4 && _zar(0.5)) {
      final s = _durumSoyle('gezgin', b);
      if (s != null) return s;
    }
    if (k.bugunAcilis >= 3 && _zar(0.45)) {
      final s = _durumSoyle('tekrar_bakti', b, ekler);
      if (s != null) return s;
    }
    if (!vazgecti && kAnlikFallar.contains(tur) && sure.inSeconds >= 25 && _zar(0.4)) {
      final s = _durumSoyle('memnun_anlik', b, ekler);
      if (s != null) return s;
    }
    return null;
  }

  /// Kilitli bir fal az önce hazır oldu.
  String? hazirOldu(MagnusBaglam b, InboxItem item) {
    if (MagnusTakvim.agirGun(b.now) != null) return null;
    final tur = falTuruGelenKutusu(item.fortuneTypeKey);
    if (tur == null) return null;
    return _durumSoyle('hazir_oldu', b, _falEkleri(tur, b.isEn));
  }
}
