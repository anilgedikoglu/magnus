// Ana menü karşılama metinleri: eski özellik vaadi yok, yer tutucular çözülür, koşullar doğru çalışır.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/utils/variable_replacer.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/presentation/home/greeting_filter.dart';

UserProfile _profile({String gender = 'kadin', String marital = 'evli', String job = 'ogrenci'}) =>
    UserProfile(
      name: 'Deniz',
      age: 36,
      gender: gender,
      maritalStatus: marital,
      job: job,
      birthDate: '1990-05-14',
    );

void main() {
  final data = jsonDecode(File('assets/data/karsilamalar.json').readAsStringSync())
      as Map<String, dynamic>;
  final all = [
    ...(data['karsilamalar'] as List).cast<Map<String, dynamic>>(),
    ...(data['biliyormuydun'] as List).cast<Map<String, dynamic>>(),
  ];

  test('uygulamada olmayan özellikler anılmıyor', () {
    final bad = RegExp(r'\baltın(ın|lar|ı)?\b|\belmas|Magnus Plus|Simyacı|"Kazan"|\|\d+s\||gold\b|diamond',
        caseSensitive: false);
    final found = [
      for (final e in all)
        if (bad.hasMatch('${e['metin']} ${e['metin_en']}')) e['id']
    ];
    expect(found, isEmpty);
  });

  test('yer tutucular çözülür, tırnakla sarılı metin yok', () {
    final vars = {..._profile().toVariableMap(), 'ziyaret': '7'};
    for (final e in all) {
      for (final key in const ['metin', 'metin_en']) {
        final t = VariableReplacer.replace('${e[key]}', vars);
        expect(t.contains('{{'), isFalse, reason: '${e['id']} $key: $t');
        expect(t.trim().startsWith("'"), isFalse, reason: '${e['id']} $key: $t');
      }
    }
  });

  test('gün, vakit ve kişi koşulları', () {
    final friday = DateTime(2026, 11, 6, 21); // cuma akşam
    Map<String, String> k(String d, String v) => {'degisken': d, 'deger': v};
    final p = _profile();
    expect(greetingMatches([k('hafta_gunu', '5')], p, friday), isTrue);
    expect(greetingMatches([k('hafta_gunu', '1')], p, friday), isFalse);
    expect(greetingMatches([k('vakit', 'aksam')], p, friday), isTrue);
    expect(greetingMatches([k('vakit', 'gece'), k('vakit', 'aksam')], p, friday), isTrue,
        reason: 'aynı değişken VEYA');
    expect(greetingMatches([k('vakit', 'aksam'), k('cinsiyet', 'erkek')], p, friday), isFalse,
        reason: 'farklı değişken VE');
    expect(greetingMatches([k('meslek', 'ogrenci')], p, friday), isTrue);
    expect(greetingMatches(null, p, friday), isTrue);
    expect(vakitOf(3), 'gece');
    expect(vakitOf(23), 'gece');
    expect(vakitOf(5), 'sabah');
    expect(vakitOf(12), 'ogle');
  });

  test('her ziyaret havuzunda, her profil ve vakitte kısa metin kalır', () {
    final pool = (data['karsilamalar'] as List).cast<Map<String, dynamic>>();
    final profiles = [_profile(), _profile(gender: 'erkek', marital: 'iliskisi_yok', job: 'kamusektoru')];
    for (final p in profiles) {
      for (final hour in const [8, 14, 19, 2]) {
        final now = DateTime(2026, 11, 4, hour);
        for (var z = 1; z <= 6; z++) {
          final n = pool.where((e) =>
              e['ziyaret'] == z &&
              greetingMatches(e['kosullar'] as List?, p, now) &&
              '${e['metin']}'.trim().length <= 110);
          expect(n.length, greaterThan(15), reason: 'ziyaret $z saat $hour');
        }
      }
    }
  });
}
