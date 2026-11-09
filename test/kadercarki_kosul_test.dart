// Kader Çarkı metin filtresi: "wheel mod" kategori etiketidir; meslek, medeni durum ve yaş
// koşulları gerçek veriyle çalışır, her profile her dilimde uygun metin kalır.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/presentation/kadercarki/kadercarki_screen.dart';

UserProfile _profil({String job = 'ozelsektoru', String marital = 'evli', int age = 34}) => UserProfile(
      name: 'Deniz',
      age: age,
      gender: 'kadin',
      job: job,
      maritalStatus: marital,
      birthDate: '1991-04-12',
      birthCity: 'İzmir',
      zodiacSign: 'Koç',
      birthTime: '08:40',
      onboardingComplete: true,
    );

Map<String, dynamic> _metin(List<List<String>> kosullar) => {
      'id': 1,
      'metin': 'x',
      'kosullar': [
        {'degisken': 'wheel mod', 'deger': 'fal'},
        for (final k in kosullar) {'degisken': k[0], 'deger': k[1]},
      ],
    };

void main() {
  test('yalnız wheel mod koşullu metin herkese uygundur', () {
    expect(kaderCarkiMetniUygun(_metin(const []), _profil()), isTrue);
  });

  test('meslek eşleşir; Türkçe büyük İ bozulmaz', () {
    final m = _metin(const [['meslek', 'iş arıyor']]);
    expect(kaderCarkiMetniUygun(m, _profil(job: 'isariyor')), isTrue);
    expect(kaderCarkiMetniUygun(m, _profil(job: 'ogrenci')), isFalse);
    expect(kaderCarkiMetniUygun(_metin(const [['meslek', 'kendi işini yapıyor']]), _profil(job: 'kendiisi')), isTrue);
  });

  test('aynı değişken OR, farklı değişken AND', () {
    final m = _metin(const [
      ['medeni durum', 'evli'],
      ['medeni durum', 'nişanlı'],
      ['meslek', 'kamu sektörü'],
    ]);
    expect(kaderCarkiMetniUygun(m, _profil(job: 'kamusektoru', marital: 'nisanli')), isTrue);
    expect(kaderCarkiMetniUygun(m, _profil(job: 'ogrenci', marital: 'evli')), isFalse);
    expect(kaderCarkiMetniUygun(m, _profil(job: 'kamusektoru', marital: 'dul')), isFalse);
  });

  test('yaş sınırları', () {
    expect(kaderCarkiMetniUygun(_metin(const [['yasmax', '40']]), _profil(age: 40)), isTrue);
    expect(kaderCarkiMetniUygun(_metin(const [['yasmax', '40']]), _profil(age: 41)), isFalse);
    expect(kaderCarkiMetniUygun(_metin(const [['yasmin', '24']]), _profil(age: 23)), isFalse);
  });

  test('gerçek veride her profil ve her dilim için uygun metin kalır', () {
    const dilimler = ['alev', 'hayvan', 'kure', 'renk', 'tas', 'zar'];
    const meslekler = ['evhanimi', 'calismiyor', 'isariyor', 'ogrenci', 'akademisyen', 'kendiisi',
        'kamusektoru', 'ozelsektoru', 'emekli'];
    const medeni = ['iliskisi_yok', 'iliski_var', 'platonik', 'flort', 'karisik', 'yeni_ayrilmis',
        'nisanli', 'evli', 'ayri_yasiyor', 'bosanmis', 'dul'];
    for (final d in dilimler) {
      final liste = (jsonDecode(File('assets/data/kadercarki_$d.json').readAsStringSync())
              as Map<String, dynamic>)['kadercarki_$d'] as List;
      for (final j in meslekler) {
        for (final m in medeni) {
          final uygun = liste.where((e) =>
              kaderCarkiMetniUygun(e as Map<String, dynamic>, _profil(job: j, marital: m)));
          expect(uygun.length, greaterThanOrEqualTo(2), reason: '$d / $j / $m');
        }
      }
    }
  });
}
