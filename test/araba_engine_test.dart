// "Arabam Ne?" motoru v2: büyük Türkiye havuzu, yaşa göre gerçekçi sınıf, lüks nadir, yaygınlık ağırlığı,
// aynı arabayla devam, yakıt yıllara göre, eski/gelecek kuralları, kalıcılık.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/services/araba_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _p({String gender = 'erkek', String birth = '2000-03-02'}) => UserProfile(
    name: 'Deniz', age: 26, gender: gender, job: 'ogrenci', maritalStatus: 'iliskisi_yok', birthDate: birth);

void main() {
  const base = 2026;
  late List<ArabaCar> pool;
  late Map<int, ArabaCar> byId;

  setUpAll(() {
    pool = ArabaEngine.parsePool(File('assets/data/arabam.json').readAsStringSync());
    byId = {for (final c in pool) c.id: c};
  });

  ArabaTimeline gen(int seed, {String g = 'erkek', int age = 28, bool married = false}) =>
      ArabaEngine.generate(pool, gender: g, age: age, married: married, baseYear: base, seed: seed);

  test('havuz: yüzlerce marka/model, 7 sınıf dolu, id benzersiz, popüler markalar var', () {
    expect(pool.length, greaterThanOrEqualTo(800));
    expect(pool.map((c) => c.id).toSet().length, pool.length);
    for (var lv = 1; lv <= 7; lv++) {
      expect(pool.any((c) => c.level == lv), isTrue, reason: 'sınıf $lv');
    }
    final brands = {for (final c in pool) c.brand.toLowerCase()};
    for (final b in ['togg', 'fiat', 'renault', 'honda', 'nissan', 'citroën', 'toyota', 'hyundai', 'volkswagen']) {
      expect(brands, contains(b), reason: b);
    }
    final low = pool.where((c) => c.level <= 3).length / pool.length;
    expect(low, greaterThanOrEqualTo(0.5));
  });

  test('5 aralık sıralı ve çakışmasız; aynı model yalnız ARDIŞIK aralıkta (devam) tekrar eder', () {
    for (var seed = 0; seed < 500; seed++) {
      final t = gen(seed);
      final cars = t.slots.where((s) => !s.isGap).toList();
      expect(cars.length, ArabaEngine.rangeCount);
      expect(t.slots.first.start, base);
      for (var i = 1; i < t.slots.length; i++) {
        expect(t.slots[i].start, t.slots[i - 1].end + 1);
      }
      expect(t.slots.last.end, lessThanOrEqualTo(base + ArabaEngine.horizon));
      for (var i = 0; i < t.slots.length; i++) {
        for (var j = i + 2; j < t.slots.length; j++) {
          final a = t.slots[i].carId, b = t.slots[j].carId;
          if (a == null || b == null || a != b) continue;
          for (var k = i + 1; k < j; k++) {
            expect(t.slots[k].carId, a, reason: 'seed=$seed kesintili tekrar');
          }
        }
      }
    }
  });

  test('aynı arabayla devam ara sıra olur (~%12-35)', () {
    var pairs = 0, same = 0;
    for (var seed = 0; seed < 1000; seed++) {
      final s = gen(seed).slots;
      for (var i = 1; i < s.length; i++) {
        if (s[i].isGap || s[i - 1].isGap) continue;
        pairs++;
        if (s[i].carId == s[i - 1].carId) same++;
      }
    }
    expect(same / pairs, inInclusiveRange(0.12, 0.35), reason: '$same/$pairs');
  });

  test('gerçekçilik: 28 yaşında ilk araba çoğunlukla sınıf 1-3; lüks (6+) nadir, süper lüks çok nadir', () {
    var firstLow = 0, anyLux = 0, anySuper = 0;
    const n = 2000;
    for (var seed = 0; seed < n; seed++) {
      final t = gen(seed);
      final levels = [for (final s in t.slots) if (!s.isGap) byId[s.carId]!.level];
      if (levels.first <= 3) firstLow++;
      if (levels.any((l) => l >= 6)) anyLux++;
      if (levels.any((l) => l == 7)) anySuper++;
    }
    expect(firstLow / n, greaterThanOrEqualTo(0.85), reason: '$firstLow');
    expect(anyLux / n, lessThan(0.08), reason: 'lüks $anyLux/$n');
    expect(anySuper / n, lessThan(0.015), reason: 'süper lüks $anySuper/$n');
  });

  test('yaygınlık: seçilen arabaların ortalama yaygınlığı havuz ortalamasından belirgin yüksek', () {
    final poolMean = pool.map((c) => c.popularity).reduce((a, b) => a + b) / pool.length;
    var sum = 0, cnt = 0;
    for (var seed = 0; seed < 800; seed++) {
      for (final s in gen(seed).slots) {
        if (s.isGap) continue;
        sum += byId[s.carId]!.popularity;
        cnt++;
      }
    }
    expect(sum / cnt, greaterThan(poolMean + 1.0), reason: 'seçilen ${sum / cnt} havuz $poolMean');
  });

  test('yakıt: 2040+ aralıklarda elektrik payı yakın yıllardakinden çok yüksek', () {
    var nearE = 0, near = 0, farE = 0, far = 0;
    for (var seed = 0; seed < 1500; seed++) {
      for (final s in gen(seed).slots) {
        if (s.isGap) continue;
        final e = byId[s.carId]!.fuel == 'elektrik';
        if (s.start < 2030) {
          near++;
          if (e) nearE++;
        } else if (s.start >= 2040) {
          far++;
          if (e) farE++;
        }
      }
    }
    expect(farE / far, greaterThan(nearE / near + 0.2), reason: 'yakın ${nearE / near} uzak ${farE / far}');
  });

  test('eski modeller düşük sınıfta; gelecek modeller kendi yılından önce çıkmaz', () {
    for (var seed = 0; seed < 1500; seed++) {
      for (final s in gen(seed, age: 20).slots) {
        if (s.isGap) continue;
        final c = byId[s.carId]!;
        if (c.status == 'eski') expect(c.level, lessThanOrEqualTo(2));
        if (c.status == 'gelecek') {
          expect(s.start, greaterThanOrEqualTo(c.fromYear ?? base), reason: c.model);
        }
      }
    }
  });

  test('cinsiyet eğilimi: kadın kullanıcıda kadın eğilimli modeller daha sık', () {
    double share(String g) {
      var k = 0, all = 0;
      for (var seed = 0; seed < 1200; seed++) {
        for (final s in gen(seed, g: g).slots) {
          if (s.isGap) continue;
          all++;
          if (byId[s.carId]!.lean == 'kadin') k++;
        }
      }
      return k / all;
    }

    expect(share('kadin'), greaterThan(share('erkek')));
  });

  test('arabasız dönem oranı ~%15', () {
    var gaps = 0;
    for (var seed = 0; seed < 1000; seed++) {
      if (gen(seed).slots.any((s) => s.isGap)) gaps++;
    }
    expect(gaps / 1000, inInclusiveRange(0.10, 0.20));
  });

  test('deterministik: aynı seed aynı çizelge', () {
    final a = gen(77), b = gen(77);
    expect(a.slots.map((s) => s.carId).toList(), b.slots.map((s) => s.carId).toList());
  });

  test('kalıcılık: aynı kayıt geri gelir, açılan kutular ve hesaplandı bayrağı kalır; cinsiyet değişince yeniden', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final t1 = await ArabaEngine.load(prefs, _p(), pool, nowYear: base);
    final idx = t1.slots.indexWhere((s) => !s.isGap);
    await ArabaEngine.reveal(prefs, t1, idx);
    final t2 = await ArabaEngine.load(prefs, _p(), pool, nowYear: base + 3);
    expect(t2.seed, t1.seed);
    expect(t2.isRevealed(idx), isTrue);
    expect(t2.computed, isTrue);
    final t3 = await ArabaEngine.load(prefs, _p(gender: 'kadın'), pool, nowYear: base, seed: 5);
    expect(t3.seed, 5);
    expect(t3.revealed, isEmpty);
  });

  test('eski şema (v1) kaydı okunmaz, yeni havuzla yeniden üretilir', () async {
    SharedPreferences.setMockInitialValues({
      ArabaEngine.prefsKey: '{"v":1,"seed":3,"base":2026,"sig":"erkek","slots":[],"rev":[],"computed":true}',
    });
    final prefs = await SharedPreferences.getInstance();
    final t = await ArabaEngine.load(prefs, _p(), pool, nowYear: base, seed: 9);
    expect(t.seed, 9);
  });

  test('tüm aralıklar geçmişte kalınca (yıllar sonra) yeni çizelge üretilir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final t1 = await ArabaEngine.load(prefs, _p(), pool, nowYear: base, seed: 11);
    final ayni = await ArabaEngine.load(prefs, _p(), pool, nowYear: t1.slots.last.end);
    expect(ayni.seed, 11);
    final yeni = await ArabaEngine.load(prefs, _p(), pool, nowYear: t1.slots.last.end + 1, seed: 12);
    expect(yeni.seed, 12);
    expect(yeni.slots.first.start, t1.slots.last.end + 1);
  });
}
