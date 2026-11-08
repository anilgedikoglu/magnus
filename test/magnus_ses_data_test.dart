// assets/data/magnus_ses.json: adetler, tekrar, değişkenler, özel gün kapsamı ve her metnin eksiksiz çözülmesi.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/magnus_ses/magnus_fal_adlari.dart';
import 'package:magnus_app/core/utils/variable_replacer.dart';
import 'package:magnus_app/data/models/user_profile.dart';

const _anilinOrnekleri = [
  'Hangisini tercih edeceksin?',
  'Eee ne düşünüyorsun?',
  'Seçimini bekliyorum...',
  'Nasıl devam edelim?',
  '"Gelecek" seni bekliyor...',
  'Seçim yapmak hep çok zordur...',
  'Seni bekliyorum...',
  'Talimatını bekliyorum.',
  'Aklından geçenleri biliyorum...',
  'Evet, ne diyorsun?',
  'Nasıl ilerlesek?',
  'Ben hazırım.',
];

const _ozelAnahtarlar = [
  'yilbasi', 'sevgililer', 'kadinlar_gunu', 'canakkale', 'nevruz', 'nisan23', 'mayis1', 'anneler_gunu', 'mayis19',
  'babalar_gunu', 'temmuz15', 'agustos30', 'cumhuriyet', 'ataturk', 'ogretmenler', 'ramazan_ilk', 'ramazan', 'kadir',
  'arefe_ramazan', 'ramazan_bayrami', 'arefe_kurban', 'kurban_bayrami', 'regaip', 'mirac', 'berat', 'mevlid',
  'hicri_yilbasi', 'asure', 'dogum_gunu', 'burc_sezonu',
];

const _durumAnahtarlar = [
  'vazgecti', 'vazgecti_tekrar', 'okunmadi', 'okunmadi_cok', 'hazirlaniyor', 'hazir_oldu', 'memnun', 'memnun_anlik',
  'tekrar_bakti', 'oneri_hic', 'oneri_bugun', 'uzun_kaldi', 'cok_uzun_kaldi', 'gece_kusu', 'gezgin', 'ilk_fal',
  'inbox_donus', 'inbox_bos', 'profil_donus',
];

const _girisGruplar = [
  'ilk_kez', 'ziyaret_2', 'ziyaret_3', 'ziyaret_4', 'ziyaret_5', 'ziyaret_cok', 'vakit', 'gun', 'genel', 'kisi', 'mevsim',
  'uzun_ara_kisa', 'uzun_ara', 'uzun_ara_cok', 'seri',
];

const _degiskenler = {
  'isim', 'isime', 'isimi', 'isimden', 'isimcigim', 'burc', 'gun', 'ay', 'mevsim', 'ziyaret', 'seri', 'ara_gun',
  'fal', 'fali', 'fala', 'faldan', 'falin', 'suredir', 'kalan', 'adet', 'app_dakika',
};

const _degiskenDegerleri = {
  'ziyaret': '3', 'seri': '4', 'ara_gun': '9', 'fal': 'Kahve Falı', 'fali': 'Kahve Falını', 'fala': 'Kahve Falına',
  'faldan': 'Kahve Falından', 'falin': 'Kahve Falının', 'suredir': '3 saattir', 'kalan': '5 dakika', 'adet': '2',
  'app_dakika': '20',
};

void main() {
  final j = jsonDecode(File('assets/data/magnus_ses.json').readAsStringSync()) as Map<String, dynamic>;
  List<Map<String, dynamic>> l(dynamic x) => (x as List).cast<Map<String, dynamic>>();
  final donus = l(j['donus']), giris = l(j['giris']);
  final ozel = (j['ozel'] as Map<String, dynamic>).map((k, v) => MapEntry(k, l(v)));
  final durum = (j['durum'] as Map<String, dynamic>).map((k, v) => MapEntry(k, l(v)));
  final hepsi = [...donus, ...giris, ...ozel.values.expand((e) => e), ...durum.values.expand((e) => e)];

  test('istenen adetler', () {
    expect(donus.length, 500);
    expect(giris.length, 500);
  });

  test('Anıl\'ın örnekleri havuzda', () {
    final metinler = donus.map((e) => e['metin']).toSet();
    for (final o in _anilinOrnekleri) {
      expect(metinler, contains(o));
    }
  });

  test('kimlikler benzersiz, Türkçe ve İngilizce dolu', () {
    expect(hepsi.map((e) => e['id']).toSet().length, hepsi.length);
    for (final e in hepsi) {
      expect('${e['metin']}'.trim(), isNotEmpty, reason: '${e['id']}');
      expect('${e['metin_en']}'.trim(), isNotEmpty, reason: '${e['id']}');
    }
  });

  test('aynı havuzda aynı cümle yok', () {
    String n(dynamic t) => '$t'.toLowerCase().replaceAll(RegExp(r'[^a-zçğıöşü0-9 ]'), '').trim();
    for (final havuz in [donus, giris]) {
      expect(havuz.map((e) => n(e['metin'])).toSet().length, havuz.length);
    }
  });

  test('her tetik, grup ve özel günün metni var', () {
    for (final k in _ozelAnahtarlar) {
      expect(ozel[k], isNotNull, reason: k);
      expect(ozel[k], isNotEmpty, reason: k);
    }
    for (final k in _durumAnahtarlar) {
      expect(durum[k], isNotEmpty, reason: k);
    }
    for (final g in _girisGruplar) {
      expect(giris.where((e) => e['grup'] == g), isNotEmpty, reason: g);
    }
    for (final g in const ['genel', 'davet', 'mistik', 'esprili', 'vakit']) {
      expect(donus.where((e) => e['grup'] == g), isNotEmpty, reason: g);
    }
    for (var gun = 1; gun <= 7; gun++) {
      expect(giris.where((e) => (e['kosullar'] as List).any((k) => k['degisken'] == 'hafta_gunu' && k['deger'] == '$gun')),
          isNotEmpty, reason: 'gün $gun');
    }
  });

  test('yalnız izinli değişkenler; İngilizcede Türkçe ekli isim yok', () {
    final re = RegExp(r'\{\{([^}]+)\}\}');
    for (final e in hepsi) {
      for (final m in re.allMatches('${e['metin']} ${e['metin_en']}')) {
        expect(_degiskenler, contains(m.group(1)), reason: '${e['id']}: ${m.group(0)}');
      }
      expect('${e['metin_en']}', isNot(matches(RegExp(r'\{\{isim(e|i|den|cigim)\}\}'))), reason: '${e['id']}');
    }
  });

  test('her metin iki profille, iki dilde eksiksiz çözülür ve cümle olarak biter', () {
    final bitis = RegExp(r'''[.!?…"'”)]$''');
    final profiller = [
      UserProfile(name: 'Deniz', age: 34, gender: 'kadin', job: 'ozelsektoru', maritalStatus: 'evli', birthDate: '1991-04-12', zodiacSign: 'Koç'),
      UserProfile(name: 'Ali', age: 19, gender: 'erkek', job: 'ogrenci', maritalStatus: 'iliskisiyok', birthDate: '2006-09-02', zodiacSign: 'Başak'),
    ];
    for (final p in profiller) {
      final vars = {...p.toVariableMap(), ..._degiskenDegerleri};
      for (final e in hepsi) {
        for (final alan in const ['metin', 'metin_en']) {
          final t = VariableReplacer.replace('${e[alan]}', vars);
          expect(t, isNot(contains('{{')), reason: '${e['id']} $alan');
          for (final parca in t.split('\n')) {
            expect(parca.trim(), matches(bitis), reason: '${e['id']} $alan: $parca');
          }
        }
      }
    }
  });

  test('fal adları: her rota ve anlık tür tanımlı', () {
    for (final t in kRotaFal.values) {
      expect(kFalAdlari, contains(t));
    }
    for (final t in kAnlikFallar) {
      expect(kFalAdlari, contains(t));
    }
  });
}
