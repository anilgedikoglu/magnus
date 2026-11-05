// "Evim Neresi?" motoru: veri bütünlüğü, tek hayat senaryosu kuralları, kalıcılık.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/services/ev_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _p({
  String marital = 'iliskisi_yok',
  String birth = '1998-03-02',
  int age = 28,
  String job = 'ozelsektoru',
  String? city = 'Ankara',
}) =>
    UserProfile(
        name: 'Deniz', age: age, gender: 'kadin', job: job, maritalStatus: marital, birthDate: birth, birthCity: city);

late EvimData data;
const base = 2026;

(int, int) _bounds(int age) {
  if (age < 18) return (4, 8);
  if (age <= 25) return (2, 3);
  if (age <= 35) return (3, 5);
  if (age <= 50) return (5, 8);
  if (age <= 60) return (6, 12);
  return (10, 20);
}

void main() {
  setUpAll(() => data = EvimData.parse(File('assets/data/evim.json').readAsStringSync()));

  test('veri: 81 il kapsamı, komşuluk simetrik, kıyı alanları tutarlı, yurt dışı makul', () {
    expect(data.iller.length, 81);
    expect(data.komsu.length, 81);
    expect(data.ilceler.length, greaterThan(250));
    for (final il in data.iller) {
      expect(data.byIl[il]!.isNotEmpty, isTrue);
      final n = data.komsu[il]!;
      expect(n.isNotEmpty, isTrue, reason: il);
      for (final x in n) {
        expect(data.komsu[x], contains(il), reason: '$il ↔ $x simetrik değil');
      }
    }
    for (final e in data.ilceler) {
      if (e.kiyi == 'kenar') expect(e.km, lessThanOrEqualTo(2), reason: e.ilce);
      if (e.kiyi == 'yakin') expect(e.km, inInclusiveRange(3, 30), reason: e.ilce);
      if (e.kiyi == 'ic') expect(e.km, greaterThan(30), reason: e.ilce);
    }
    expect(data.yurtdisi.length, inInclusiveRange(20, 40));
    for (final k in ['sehir', 'sakin', 'genel', 'yurtdisi', 'emekli']) {
      expect(data.anlati[k]!.length, greaterThanOrEqualTo(4));
    }
    expect(data.matchIl('istanbul'), 'İstanbul');
    expect(data.matchIl('Afyon'), 'Afyonkarahisar');
    expect(data.matchIl('IĞDIR'), 'Iğdır');
    expect(data.matchIl('Xyz'), isNull);
  });

  test('segmentler boşluksuz, uzunluklar yaş kurallarına uygun; aynı tohum aynı sonuç', () {
    for (var seed = 0; seed < 400; seed++) {
      final t = EvimEngine.generate(data, _p(), 'Ankara', baseYear: base, seed: seed);
      expect(t.segments.first.start, base);
      expect(t.segments.last.end, base + 50);
      for (var i = 0; i < t.segments.length; i++) {
        final s = t.segments[i];
        if (i > 0) expect(s.start, t.segments[i - 1].end + 1);
        if (i < t.segments.length - 1 && !s.abroad) {
          final (lo, hi) = _bounds(s.start - 1998);
          expect(s.length, inInclusiveRange(lo, hi), reason: 'seed $seed seg $i yaş ${s.start - 1998}');
        } else if (i == t.segments.length - 1 && !s.abroad) {
          expect(s.length, lessThanOrEqualTo(_bounds(s.start - 1998).$2));
        }
      }
      final t2 = EvimEngine.generate(data, _p(), 'Ankara', baseYear: base, seed: seed);
      expect(jsonEncode(t2.toJson()), jsonEncode(t.toJson()));
      for (var y = base; y <= base + 50; y++) {
        expect(t.segmentFor(y).id, t2.segmentFor(y).id);
      }
    }
  });

  test('ardışık Türkiye segmentlerinde çoğunlukla aynı / komşu il (≥%70); anlamsız sıçrama azdır', () {
    var total = 0, near = 0;
    for (var seed = 0; seed < 400; seed++) {
      final t = EvimEngine.generate(data, _p(), 'Ankara', baseYear: base, seed: seed);
      for (var i = 1; i < t.segments.length; i++) {
        final a = t.segments[i - 1], b = t.segments[i];
        if (a.abroad || b.abroad) continue;
        total++;
        if (a.il == b.il || data.komsu[a.il]!.contains(b.il)) near++;
      }
    }
    expect(near / total, greaterThanOrEqualTo(0.70), reason: '$near/$total');
  });

  test('ilk segmentte mevcut il ağırlığı ~%94 (yakın yıllarda aynı şehir)', () {
    var same = 0, neighbor = 0;
    const n = 1000;
    for (var seed = 0; seed < n; seed++) {
      final t = EvimEngine.generate(data, _p(), 'Ankara', baseYear: base, seed: seed);
      final s = t.segments.first;
      if (s.il == 'Ankara') same++;
      if (data.komsu['Ankara']!.contains(s.il)) neighbor++;
    }
    expect(same / n, inInclusiveRange(0.92, 0.99));
    expect(neighbor / n, inInclusiveRange(0.0, 0.05));
  });

  test('İstanbul: ilk 10 yılda aynı şehir çok olası, büyükten küçük şehre geçiş nadir', () {
    var stayAll10 = 0, toSmall10 = 0, toSmallAll = 0;
    const n = 1000;
    for (var seed = 0; seed < n; seed++) {
      final t = EvimEngine.generate(data, _p(), 'İstanbul', baseYear: base, seed: seed);
      final tr10 = t.segments.where((s) => !s.abroad && s.start < base + 10).toList();
      if (tr10.every((s) => s.il == 'İstanbul')) stayAll10++;
      if (tr10.any((s) => EvimEngine.sizeOf(s.il) == 1)) toSmall10++;
      if (t.segments.any((s) => !s.abroad && EvimEngine.sizeOf(s.il) == 1 && s.start - base < 30)) toSmallAll++;
    }
    expect(stayAll10 / n, greaterThan(0.75), reason: 'ilk 10 yıl hep İstanbul: $stayAll10/$n');
    expect(toSmall10 / n, lessThan(0.04), reason: 'ilk 10 yılda küçük şehir: $toSmall10/$n');
    expect(toSmallAll / n, lessThan(0.15), reason: '30 yılda küçük şehir: $toSmallAll/$n');
  });

  test('yurt dışı: senaryoların <%8\'inde, 20-50 yaş ve ≥ bu yıl+5, en çok 1 segment; 60+ yaşta hiç yok', () {
    for (final job in ['ogrenci', 'ozelsektoru', 'kamusektoru']) {
      var abroadScenarios = 0;
      const n = 800;
      for (var seed = 0; seed < n; seed++) {
        final t = EvimEngine.generate(data, _p(job: job, birth: '2004-01-01', age: 22), 'İzmir',
            baseYear: base, seed: seed);
        final ab = t.segments.where((s) => s.abroad).toList();
        expect(ab.length, lessThanOrEqualTo(1));
        if (ab.isNotEmpty) {
          abroadScenarios++;
          final s = ab.single;
          expect(s.start, greaterThanOrEqualTo(base + 5));
          expect(s.start - 2004, inInclusiveRange(20, 50));
          expect(s.length, inInclusiveRange(3, 8));
          expect(s.sehir, isNotEmpty);
          // sonra Türkiye'ye dönüş (son segment değilse)
          final idx = t.segments.indexOf(s);
          if (idx < t.segments.length - 1) expect(t.segments[idx + 1].abroad, isFalse);
        }
      }
      expect(abroadScenarios / n, lessThan(0.08), reason: '$job: $abroadScenarios/$n');
    }
    for (var seed = 0; seed < 400; seed++) {
      final t = EvimEngine.generate(data, _p(birth: '1966-05-05', age: 60, job: 'ozelsektoru'), 'İzmir',
          baseYear: base, seed: seed);
      expect(t.segments.any((s) => s.abroad), isFalse);
    }
  });

  test('ev sahibi → kiracı dönüşü nadir (≤%15); 25 yaş altı ilk durum dağılımı ~40/50/10', () {
    var fromOwner = 0, toRenter = 0;
    for (var seed = 0; seed < 500; seed++) {
      final t = EvimEngine.generate(data, _p(marital: 'evli', birth: '1990-01-01', age: 36), 'Ankara',
          baseYear: base, seed: seed);
      for (var i = 1; i < t.segments.length; i++) {
        final a = t.segments[i - 1], b = t.segments[i];
        if (a.abroad || b.abroad || a.durum != 'sahip') continue;
        fromOwner++;
        if (b.durum == 'kiraci') toRenter++;
        expect(b.durum, isNot('aile'));
      }
    }
    expect(fromOwner, greaterThan(500));
    expect(toRenter / fromOwner, lessThanOrEqualTo(0.15), reason: '$toRenter/$fromOwner');

    final c = <String, int>{'aile': 0, 'kiraci': 0, 'sahip': 0};
    const n = 1500;
    for (var seed = 0; seed < n; seed++) {
      final t = EvimEngine.generate(data, _p(birth: '2007-01-01', age: 19), 'Ankara', baseYear: base, seed: seed);
      c[t.segments.first.durum] = c[t.segments.first.durum]! + 1;
    }
    expect(c['aile']! / n, inInclusiveRange(0.33, 0.47));
    expect(c['kiraci']! / n, inInclusiveRange(0.43, 0.57));
    expect(c['sahip']! / n, inInclusiveRange(0.05, 0.16));
  });

  test('kıyısız ilçede "denize çok yakın" yok; yazlık hep kıyıda; yazlık oranı makul', () {
    var yaz = 0, seg = 0;
    for (var seed = 0; seed < 400; seed++) {
      final t = EvimEngine.generate(data, _p(marital: 'evli', birth: '1976-01-01', age: 50), 'Ankara',
          baseYear: base, seed: seed);
      for (final s in t.segments.where((s) => !s.abroad)) {
        seg++;
        if (s.kiyi == 'ic') expect(EvimLabels.seaKey(s.km), isNot('cok_yakin'));
        if (s.km > 100) expect(EvimLabels.sea(s.km, false), 'Denizden uzak, iç kesimlerde');
        if (s.hasYazlik) {
          yaz++;
          expect(s.yazKm, lessThanOrEqualTo(2));
          expect(s.durum, isNot('aile'));
        }
      }
    }
    expect(yaz / seg, inInclusiveRange(0.03, 0.25));
    expect(EvimLabels.seaKey(0), 'cok_yakin');
    expect(EvimLabels.seaKey(2), 'cok_yakin');
    expect(EvimLabels.seaKey(10), 'yakin');
    expect(EvimLabels.seaKey(30), 'kisa_yol');
    expect(EvimLabels.seaKey(100), 'biraz_uzak');
    expect(EvimLabels.seaKey(101), 'uzak');
  });

  test('50 yaş üstü: uzak doğu/sınır illeri çıkmaz; 62+ yaşta emeklilik düzeni (sahil/memleket) görülür', () {
    var coast = 0, home = 0, stay = 0, total = 0;
    for (var seed = 0; seed < 500; seed++) {
      final t = EvimEngine.generate(data, _p(birth: '1970-01-01', age: 56, city: 'Sivas'), 'Ankara',
          baseYear: base, seed: seed);
      for (var i = 0; i < t.segments.length; i++) {
        final s = t.segments[i];
        if (s.abroad) continue;
        if (s.start - 1970 >= 50) expect(EvimEngine.farIller, isNot(contains(s.il)), reason: 'seed $seed ${s.il}');
        if (s.start - 1970 >= 62) {
          total++;
          if (s.il == 'Sivas') home++;
          if (['İzmir', 'Aydın', 'Muğla', 'Balıkesir', 'Antalya', 'Mersin', 'Çanakkale'].contains(s.il) &&
              s.kiyi == 'kenar') {
            coast++;
          }
          if (i > 0 && t.segments[i - 1].il == s.il) stay++; // mevcut ilde kal
        }
      }
    }
    expect(total, greaterThan(300));
    expect(stay / total, greaterThan(0.35)); // mevcut ilde kal en büyük pay
    expect(coast / total, greaterThan(0.10));
    expect(home / total, greaterThan(0.08));
  });

  test('kalıcılık: aynı kayıt, açılan kutular kalıcı, il/medeni hal değişince yeniden üretilir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final t1 = await EvimEngine.load(prefs, data, _p(), 'Ankara', nowYear: base, seed: 7);
    final s1 = t1.segmentFor(base + 12);
    await EvimEngine.reveal(prefs, t1, s1.id, 'yer');
    final t2 = await EvimEngine.load(prefs, data, _p(), 'Ankara', nowYear: base + 1, seed: 999); // bir yıl sonra
    final s2 = t2.segmentFor(base + 12);
    expect(s2.il, s1.il);
    expect(s2.ilce, s1.ilce);
    expect(s2.tip, s1.tip);
    expect(t2.isRevealed(s1.id, 'yer'), isTrue);
    expect(t2.isRevealed(s1.id, 'tip'), isFalse);
    expect(t2.lastYear, base + 1 + 50);
    // il değişti → yeni senaryo, açılanlar sıfır
    final t3 = await EvimEngine.load(prefs, data, _p(), 'İzmir', nowYear: base + 1, seed: 5);
    expect(t3.signature, startsWith('İzmir'));
    expect(t3.revealed, isEmpty);
    // il tercihi
    expect(EvimEngine.storedIl(prefs, data), isNull);
    await EvimEngine.saveIl(prefs, 'Konya');
    expect(EvimEngine.storedIl(prefs, data), 'Konya');
    expect(prefs.getBool(EvimEngine.prefsAskedKey), isTrue);
  });
}
