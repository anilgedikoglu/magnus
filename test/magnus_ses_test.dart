// Magnus'un sesi: takvim, hafıza ve seçim kuralları.
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/magnus_ses/magnus_hafiza.dart';
import 'package:magnus_app/core/magnus_ses/magnus_ses.dart';
import 'package:magnus_app/core/magnus_ses/magnus_takvim.dart';
import 'package:magnus_app/data/models/inbox_item.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _p({String name = 'Deniz', String birth = '1991-04-12', String gender = 'kadin'}) => UserProfile(
      name: name,
      age: 35,
      gender: gender,
      job: 'ozelsektoru',
      maritalStatus: 'evli',
      birthDate: birth,
      zodiacSign: 'Koç',
    );

Map<String, dynamic> _m(String id, String metin, [List<Map<String, String>> kosullar = const [], String? grup]) => {
      'id': id,
      'metin': metin,
      'metin_en': 'EN $metin',
      'kosullar': kosullar,
      if (grup != null) 'grup': grup,
    };

String _havuz() => jsonEncode({
      'donus': [_m('d1', 'Bir.', [], 'genel'), _m('d2', 'İki.', [], 'mistik'), _m('d3', 'Üç.', [], 'davet')],
      'giris': [
        _m('g1', 'İlk selam {{isim}}.', [], 'ilk_kez'),
        _m('g2', 'Genel a.', [], 'genel'),
        _m('g3', 'Genel b.', [], 'genel'),
        _m('g4', 'Bugün {{ziyaret}}. geliş.', [], 'ziyaret_2'),
        _m('g5', 'Hayırlı cumalar {{isim}}.', [{'degisken': 'hafta_gunu', 'deger': '5'}], 'gun'),
        _m('g6', 'Çok uzun ara.', [], 'uzun_ara_cok'),
        _m('g7', '{{ara_gun}} gün oldu.', [], 'uzun_ara'),
      ],
      'ozel': {
        'dogum_gunu': [_m('o1', 'İyi ki doğdun {{isim}}.')],
        'ramazan_bayrami': [_m('o2', 'Bayramın mübarek.')],
      },
      'durum': {
        'vazgecti': [_m('v1', 'Neden {{faldan}} vazgeçtin?')],
        'vazgecti_tekrar': [_m('v2', 'Yine {{fala}} girdin.')],
        'okunmadi': [_m('u1', '{{fal}} {{suredir}} bekliyor.')],
        'memnun': [_m('m1', 'Umarım {{fal}} içine sinmiştir.')],
      },
    });

Future<(SharedPreferences, MagnusHafiza, MagnusSes)> _kur({int seed = 1}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final h = MagnusHafiza(prefs);
  final s = MagnusSes(prefs, h, rng: Random(seed))..yukleMetin(_havuz());
  return (prefs, h, s);
}

MagnusBaglam _b(DateTime now, {UserProfile? p, List<InboxItem> kutu = const [], bool en = false}) =>
    MagnusBaglam(now: now, profile: p ?? _p(), isEn: en, gelenKutusu: kutu);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('takvim', () {
    test('Diyanet tarihleri', () {
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 3, 9)), contains('ramazan_bayrami'));
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 2, 8)), contains('ramazan_ilk'));
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 2, 20)), contains('ramazan'));
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 5, 15)), contains('arefe_kurban'));
      expect(MagnusTakvim.ozelGunler(DateTime(2026, 12, 10)), contains('regaip'));
    });
    test('sabit ve hareketli günler', () {
      expect(MagnusTakvim.ozelGunler(DateTime(2026, 10, 29)), contains('cumhuriyet'));
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 5, 9)), contains('anneler_gunu'));
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 6, 20)), contains('babalar_gunu'));
      expect(MagnusTakvim.ozelGunler(DateTime(2026, 11, 11)), isEmpty);
    });
    test('kişisel günler', () {
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 4, 12), dogumTarihi: '1991-04-12').first, 'dogum_gunu');
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 3, 21), burc: 'Koç'), contains('burc_sezonu'));
    });
  });

  group('hafıza', () {
    test('günlük geliş, seri, ara ve kalıcılık', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final h = MagnusHafiza(prefs);
      final ilk = h.girisKaydet(DateTime(2026, 11, 9, 10));
      expect(ilk.ilkKez, isTrue);
      expect(h.girisKaydet(DateTime(2026, 11, 9, 12)).bugunKacinci, 2);
      final yarin = h.girisKaydet(DateTime(2026, 11, 10, 9));
      expect((yarin.bugunKacinci, yarin.seri, yarin.araGun), (1, 2, 1));
      final sonra = MagnusHafiza(prefs).girisKaydet(DateTime(2026, 11, 15, 9));
      expect((sonra.ilkKez, sonra.seri, sonra.araGun), (false, 1, 5));
    });
    test('fal sayaçları güne göre sıfırlanır', () async {
      final (_, h, _) = await _kur();
      h.falGirdi('kahve', DateTime(2026, 11, 9, 10));
      h.falCikti('kahve', DateTime(2026, 11, 9, 10), vazgecti: true, tamam: false);
      expect(h.kayit('kahve', DateTime(2026, 11, 9, 11)).bugunVazgecti, 1);
      expect(h.kayit('kahve', DateTime(2026, 11, 10)).bugunVazgecti, 0);
      expect(h.hicAcilmadi('kahve'), isFalse);
      expect(h.hicAcilmadi('tarot'), isTrue);
    });
  });

  group('sınır durumları', () {
    test('güncelleme alan eski kullanıcı ilk kez gelmiş sayılmaz', () async {
      SharedPreferences.setMockInitialValues({'ilk_giris_yapildi': true});
      final prefs = await SharedPreferences.getInstance();
      final h = MagnusHafiza(prefs);
      expect(h.girisKaydet(DateTime(2026, 11, 9)).ilkKez, isFalse);
      expect(h.ilkFalDendi, isTrue);
      expect(h.oneriyeHazir(DateTime(2026, 11, 20)), isFalse);
      expect(h.oneriyeHazir(DateTime(2026, 12, 20)), isTrue);
    });
    test('gece yarısını geçen oturumda seri artar', () async {
      final (_, h, _) = await _kur();
      h.girisKaydet(DateTime(2026, 11, 9, 23));
      h.sureEkle(const Duration(minutes: 20), DateTime(2026, 11, 10, 0, 5));
      final g = h.girisKaydet(DateTime(2026, 11, 10, 9));
      expect((g.seri, g.bugunKacinci), (2, 1));
    });
    test('takvim Türkçe büyük harfi ve Ramazan', () {
      expect(MagnusTakvim.ozelGunler(DateTime(2027, 5, 21), burc: 'İkizler'), contains('burc_sezonu'));
      expect(MagnusTakvim.ramazanda(DateTime(2027, 2, 8)), isTrue);
      expect(MagnusTakvim.ramazanda(DateTime(2027, 4, 8)), isFalse);
    });
    test('10 Kasım günü dönüşlerde susar, açılışta yalnız günün sözü', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final h = MagnusHafiza(prefs);
      final raw = jsonDecode(_havuz()) as Map<String, dynamic>;
      (raw['ozel'] as Map<String, dynamic>)['ataturk'] = [_m('o9', 'Saygıyla.')];
      final s = MagnusSes(prefs, h, rng: Random(1))..yukleMetin(jsonEncode(raw));
      final d = DateTime(2026, 11, 10, 12);
      h.girisKaydet(d.subtract(const Duration(hours: 1)));
      expect(s.giris(_b(d), h.girisKaydet(d)), 'Saygıyla.');
      for (var i = 0; i < 20; i++) {
        expect(s.sekmeDonus(_b(d.add(Duration(minutes: i * 2))), DonusKaynagi.profil), isNull);
      }
    });
    test('havuz bitince yalnız o an uygun olanlar sıfırlanır', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final h = MagnusHafiza(prefs);
      final raw = {
        'donus': [],
        'giris': [
          _m('c', 'Cuma.', [{'degisken': 'hafta_gunu', 'deger': '5'}], 'genel'),
          _m('p1', 'Pazartesi bir.', [{'degisken': 'hafta_gunu', 'deger': '1'}], 'genel'),
          _m('p2', 'Pazartesi iki.', [{'degisken': 'hafta_gunu', 'deger': '1'}], 'genel'),
        ],
        'ozel': {},
        'durum': {},
      };
      final s = MagnusSes(prefs, h, rng: Random(1))..yukleMetin(jsonEncode(raw));
      const g = GirisBilgisi(ilkKez: false, bugunKacinci: 3, araGun: 0, seri: 1);
      s.giris(_b(DateTime(2026, 11, 6, 10)), g); // cuma
      for (var i = 0; i < 4; i++) {
        s.giris(_b(DateTime(2026, 11, 9, 10)), g); // pazartesi
      }
      expect(prefs.getStringList('ses_goster_giris_genel'), contains('c'));
    });
  });

  group('seçim', () {
    final sali = DateTime(2026, 11, 17, 10);

    test('ilk kez gelene ilk selam, isim yerine konur', () async {
      final (_, h, s) = await _kur();
      expect(s.giris(_b(sali), h.girisKaydet(sali)), 'İlk selam Deniz.');
    });

    test('doğum günü yalnız günün ilk gelişinde', () async {
      final (_, h, s) = await _kur();
      h.girisKaydet(DateTime(2027, 4, 11, 9));
      final d = DateTime(2027, 4, 12, 9);
      expect(s.giris(_b(d), h.girisKaydet(d)), 'İyi ki doğdun Deniz.');
      final ikinci = s.giris(_b(d), h.girisKaydet(d));
      expect(ikinci, isNot(contains('doğdun')));
    });

    test('uzun aradan sonra gelene ayrı karşılama', () async {
      final (_, h, s) = await _kur();
      h.girisKaydet(DateTime(2026, 11, 8, 9));
      expect(s.giris(_b(sali), h.girisKaydet(sali)), '9 gün oldu.');
    });

    test('uygun metinler bitmeden tekrar yok, üst üste de yok', () async {
      final (_, h, s) = await _kur();
      h.girisKaydet(DateTime(2026, 11, 16, 8));
      final cikti = <String?>[];
      final g = GirisBilgisi(ilkKez: false, bugunKacinci: 1, araGun: 0, seri: 1);
      for (var i = 0; i < 6; i++) {
        cikti.add(s.giris(_b(sali), g));
      }
      for (var i = 0; i + 1 < cikti.length; i += 2) {
        expect({cikti[i], cikti[i + 1]}.length, 2);
      }
      for (var i = 1; i < cikti.length; i++) {
        expect(cikti[i], isNot(cikti[i - 1]));
      }
    });

    test('adı olmayana isimli metin çıkmaz', () async {
      final (_, h, s) = await _kur();
      final g = h.girisKaydet(sali);
      expect(s.giris(_b(sali, p: _p(name: '')), g), isNot(contains('İlk selam')));
    });

    test('vazgeçince türün doğru hâli kullanılır; ikinci kez ayrı cümle', () async {
      for (var seed = 0; seed < 30; seed++) {
        final (_, h, s) = await _kur(seed: seed);
        h.falGirdi('kahve', sali);
        h.falCikti('kahve', sali, vazgecti: true, tamam: false);
        final ilk = s.falDonus(_b(sali), 'kahve', const Duration(seconds: 3), vazgecti: true);
        if (ilk != null) expect(ilk, 'Neden Kahve Falından vazgeçtin?');
        h.falGirdi('tarot', sali);
        h.falCikti('tarot', sali, vazgecti: true, tamam: false);
        h.falCikti('tarot', sali, vazgecti: true, tamam: false);
        final iki = s.falDonus(_b(sali), 'tarot', const Duration(seconds: 3), vazgecti: true);
        if (iki != null) expect(iki, anyOf('Yine Tarota girdin.', 'Neden Tarottan vazgeçtin?'));
      }
    });

    test('okunmamış fal süresiyle anılır', () async {
      final item = InboxItem(
        id: 'a',
        title: 'Kahve',
        text: 'x',
        date: sali.subtract(const Duration(hours: 3)).toIso8601String(),
        fortuneTypeKey: 'coffee',
      );
      var goruldu = false;
      for (var seed = 0; seed < 40 && !goruldu; seed++) {
        final (_, h, s) = await _kur(seed: seed);
        h.girisKaydet(DateTime(2026, 11, 17, 8));
        final g = GirisBilgisi(ilkKez: false, bugunKacinci: 2, araGun: 0, seri: 1);
        goruldu = s.giris(_b(sali, kutu: [item]), g) == 'Kahve Falı 3 saattir bekliyor.';
      }
      expect(goruldu, isTrue);
    });

    test('gelen kutusunda okunan fal nadiren anılır', () async {
      var soruldu = 0;
      for (var seed = 0; seed < 300; seed++) {
        final (_, h, s) = await _kur(seed: seed);
        h.okundu('kahve', sali);
        final m = s.sekmeDonus(_b(sali), DonusKaynagi.gelenKutusu);
        if (m == 'Umarım Kahve Falı içine sinmiştir.') soruldu++;
      }
      expect(soruldu, inInclusiveRange(5, 60), reason: '$soruldu/300');
    });

    test('dönüşte her seferinde konuşmaz, peş peşe de konuşmaz', () async {
      var konustu = 0;
      for (var seed = 0; seed < 200; seed++) {
        final (_, h, s) = await _kur(seed: seed);
        h.falGirdi('kahve', sali);
        if (s.sekmeDonus(_b(sali), DonusKaynagi.profil) != null) {
          konustu++;
          expect(s.sekmeDonus(_b(sali.add(const Duration(seconds: 10))), DonusKaynagi.profil), isNull);
        }
      }
      expect(konustu, inInclusiveRange(60, 140), reason: '$konustu/200');
    });

    test('İngilizcede metin_en ve İngilizce süre', () async {
      final (_, h, s) = await _kur();
      h.girisKaydet(sali);
      expect(MagnusSes.suredir(const Duration(hours: 3), true), 'for 3 hours');
      expect(MagnusSes.suredir(const Duration(minutes: 20), false), '20 dakikadır');
      expect(MagnusSes.kalanSure(const Duration(minutes: 4, seconds: 10), false), '5 dakika');
      final m = s.giris(_b(sali, en: true), const GirisBilgisi(ilkKez: true, bugunKacinci: 1, araGun: 0, seri: 1));
      expect(m, 'EN İlk selam Deniz.');
    });
  });
}
