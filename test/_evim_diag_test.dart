// Evim motoru v2 (vade havuzlu, 2026-11-06): çeşitlilik + uzun vade kıyı/yurt dışı doğrulaması.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/services/ev_engine.dart';

UserProfile _p({int age = 30, String city = 'İstanbul', String job = 'ozelsektoru'}) => UserProfile(
    name: 'D', age: age, gender: 'kadin', job: job,
    maritalStatus: 'evli', birthDate: '${2026 - age}-01-01', birthCity: city);

void main() {
  late EvimData data;
  const base = 2026;
  const coastIl = {'İzmir', 'Aydın', 'Muğla', 'Antalya', 'Balıkesir', 'Çanakkale', 'Mersin'};
  setUpAll(() => data = EvimData.parse(File('assets/data/evim.json').readAsStringSync()));

  test('ilk segment mevcut şehir; 50 yılda çeşitlilik (tek şehirde takılmaz)', () {
    for (var seed = 0; seed < 300; seed++) {
      final t = EvimEngine.generate(data, _p(city: 'İstanbul'), 'İstanbul', baseYear: base, seed: seed);
      expect(t.segments.first.il, 'İstanbul'); // yakın vade = mevcut şehir
      final yerler = <String>{for (final s in t.segments) s.abroad ? 'AB:${s.ulke}' : s.il};
      expect(yerler.length, greaterThanOrEqualTo(3), reason: 'seed $seed çeşitlilik zayıf: $yerler');
    }
  });

  test('uzun vadede (15+ yıl) çoğunlukla Ege/Akdeniz kıyı ya da yurt dışı', () {
    var long = 0, nice = 0;
    for (var seed = 0; seed < 500; seed++) {
      final t = EvimEngine.generate(data, _p(city: 'İstanbul'), 'İstanbul', baseYear: base, seed: seed);
      for (final s in t.segments.where((s) => s.start - base >= 15)) {
        long++;
        if (s.abroad || (coastIl.contains(s.il) && s.kiyi == 'kenar')) nice++;
      }
    }
    expect(nice / long, greaterThan(0.5), reason: 'uzun vade kıyı/yurt dışı: $nice/$long');
  });

  test('yurt dışı artık orta/uzun vadede makul sıklıkta (ama en çok 2 segment)', () {
    var withAb = 0;
    const n = 500;
    for (var seed = 0; seed < n; seed++) {
      final t = EvimEngine.generate(data, _p(city: 'İstanbul'), 'İstanbul', baseYear: base, seed: seed);
      final ab = t.segments.where((s) => s.abroad).toList();
      expect(ab.length, lessThanOrEqualTo(2));
      for (final s in ab) {
        expect(s.start, greaterThanOrEqualTo(base + 4)); // yakın vadede yok
        expect(s.end, greaterThanOrEqualTo(s.start)); // negatif uzunluk bug'ı yok
      }
      if (ab.isNotEmpty) withAb++;
    }
    expect(withAb / n, greaterThan(0.2));
  });

  test('segmentler boşluksuz ve end>=start (tüm yaş/şehirlerde)', () {
    for (final city in ['İstanbul', 'Ankara', 'Sivas', 'İzmir', 'Van']) {
      for (var seed = 0; seed < 150; seed++) {
        final t = EvimEngine.generate(data, _p(city: city, age: 24 + seed % 50), city, baseYear: base, seed: seed);
        expect(t.segments.first.start, base);
        expect(t.segments.last.end, base + 50);
        for (var i = 0; i < t.segments.length; i++) {
          expect(t.segments[i].end, greaterThanOrEqualTo(t.segments[i].start), reason: '$city seed $seed seg $i');
          if (i > 0) expect(t.segments[i].start, t.segments[i - 1].end + 1);
        }
      }
    }
  });
}
