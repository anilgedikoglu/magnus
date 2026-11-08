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

  test('aynı arabayla devam nadir olur', () {
    var pairs = 0, same = 0;
    for (var seed = 0; seed < 1000; seed++) {
      final s = gen(seed).slots;
      for (var i = 1; i < s.length; i++) {
        if (s[i].isGap || s[i - 1].isGap) continue;
        pairs++;
        if (s[i].carId == s[i - 1].carId) same++;
      }
    }
    expect(same / pairs, inInclusiveRange(0.002, 0.10), reason: '$same/$pairs');
  });

  test('gerçekçilik: ilk araba çoğunlukla sınıf 1-3; lüks ulaşılabilir, süper lüks azınlıkta', () {
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
    expect(anyLux / n, inInclusiveRange(0.15, 0.60), reason: 'lüks $anyLux/$n');
    expect(anySuper / n, inInclusiveRange(0.01, 0.20), reason: 'süper lüks $anySuper/$n');
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
    expect(sum / cnt, greaterThan(poolMean + 0.5), reason: 'seçilen ${sum / cnt} havuz $poolMean');
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

  // ── v3: marka tabanlı başlangıç + ±1 kademeli ilerleme (Anıl + Codex, 2026-11-06) ──
  test('markalar A-Z sıralı, benzersiz, popüler markalar var', () {
    final b = ArabaEngine.brands(pool);
    expect(b.length, greaterThan(20));
    expect(b.toSet().length, b.length);
    final sorted = [...b]..sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
    expect(b, sorted);
    final lower = b.map((e) => e.toLowerCase()).toSet();
    for (final m in ['fiat', 'renault', 'mercedes-benz', 'bmw']) {
      expect(lower, contains(m), reason: m);
    }
  });

  test('marka başlangıç sınıfı: ekonomik marka düşük, premium yüksek', () {
    int lv(String br) => ArabaEngine.brandStartLevel(pool, br);
    expect(lv('Fiat'), lessThan(lv('Mercedes-Benz')));
    expect(lv('Renault'), lessThanOrEqualTo(lv('BMW')));
    expect(lv('Fiat'), inInclusiveRange(1, 3));
    expect(lv('BilinmeyenMarka'), 2); // bilinmeyen → 2
  });

  test('arabam yok → ilk araba sınıf 1; marka seçilince ilk araba marka sınıfında', () {
    for (var seed = 0; seed < 150; seed++) {
      final yok = ArabaEngine.generate(pool,
          gender: 'erkek', age: 30, baseYear: base, seed: seed, currentBrand: null);
      final lv = [for (final s in yok.slots) if (!s.isGap) byId[s.carId]!.level];
      expect(lv.first, 1, reason: 'arabam yok ilk sınıf 1');
    }
    final startMb = ArabaEngine.brandStartLevel(pool, 'Mercedes-Benz');
    for (var seed = 0; seed < 150; seed++) {
      final t = ArabaEngine.generate(pool,
          gender: 'erkek', age: 42, baseYear: base, seed: seed, currentBrand: 'Mercedes-Benz');
      final lv = [for (final s in t.slots) if (!s.isGap) byId[s.carId]!.level];
      expect((lv.first - startMb).abs(), lessThanOrEqualTo(1), reason: 'ilk araba marka sınıfında');
    }
  });

  test('kademeli ilerleme: ardışık arabalar arasında uçuk zıplama yok (fark ≤2)', () {
    for (var seed = 0; seed < 600; seed++) {
      final t = ArabaEngine.generate(pool,
          gender: 'erkek', age: 30, baseYear: base, seed: seed, currentBrand: 'Fiat');
      final lv = [for (final s in t.slots) if (!s.isGap) byId[s.carId]!.level];
      for (var i = 1; i < lv.length; i++) {
        final d = (lv[i] - lv[i - 1]).abs();
        expect(d, lessThanOrEqualTo(2), reason: 'seed=$seed uçuk zıplama');
      }
    }
  });

  test('zaman ilerledikçe araba çok büyük ihtimalle pahalılaşır ama kesin değildir', () {
    var pairs = 0, up = 0, notUp = 0;
    for (var seed = 0; seed < 1500; seed++) {
      final lv = [for (final s in gen(seed).slots) if (!s.isGap) byId[s.carId]!.level];
      for (var i = 1; i < lv.length; i++) {
        pairs++;
        lv[i] > lv[i - 1] ? up++ : notUp++;
      }
    }
    expect(up / pairs, greaterThan(0.70), reason: '$up/$pairs');
    expect(notUp, greaterThan(0), reason: 'kesin pahalılaşma olmamalı');
  });

  test('aynı araba 10 yılı geçmez, 8+ yıl çok nadir; son aralıkta devam yok', () {
    var long = 0, runs = 0;
    for (var seed = 0; seed < 2000; seed++) {
      final s = gen(seed).slots;
      var i = 0;
      while (i < s.length) {
        if (s[i].isGap) {
          i++;
          continue;
        }
        var j = i;
        while (j + 1 < s.length && s[j + 1].carId == s[i].carId) {
          j++;
        }
        final years = s[j].end - s[i].start + 1;
        expect(years, lessThanOrEqualTo(10), reason: 'seed=$seed');
        runs++;
        if (years >= 8) long++;
        i = j + 1;
      }
      expect(s.last.carId, isNot(s[s.length - 2].carId), reason: 'seed=$seed');
    }
    expect(long / runs, lessThan(0.06), reason: '$long/$runs');
  });

  test('uzak gelecekte sıradan araba çok nadir', () {
    var far = 0, cheap = 0;
    for (var seed = 0; seed < 2000; seed++) {
      for (final s in gen(seed).slots) {
        if (s.isGap || s.start - base < 18) continue;
        far++;
        if (byId[s.carId]!.level <= 3) cheap++;
      }
    }
    expect(far, greaterThan(100));
    expect(cheap / far, lessThan(0.12), reason: '$cheap/$far');
  });

  test('aynı model ailesi çizelgede iki kez çıkmaz', () {
    for (var seed = 0; seed < 800; seed++) {
      final cars = [for (final s in gen(seed).slots) if (!s.isGap) s.carId!].toSet().map((id) => byId[id]!);
      final fams = cars.map((c) => '${c.brand} ${c.name.replaceFirst(c.brand, '').trim().split(' ').first}'.toLowerCase());
      expect(fams.toSet().length, cars.length, reason: 'seed=$seed');
    }
  });

  test('15+ yıl sonrası yalnız marka yazılır, yakın yıllarda model; uzakta art arda aynı marka olmaz', () {
    final car = pool.firstWhere((c) => c.brand == 'Honda');
    expect(ArabaEngine.displayName(car, const ArabaSlot(2040, 2044, 1), base), car.model);
    expect(ArabaEngine.displayName(car, const ArabaSlot(2041, 2044, 1), base), 'Honda');
    for (var seed = 0; seed < 1500; seed++) {
      final s = gen(seed).slots;
      for (var i = 1; i < s.length; i++) {
        if (s[i].isGap || s[i - 1].isGap || s[i].carId == s[i - 1].carId) continue;
        if (s[i].start - base < ArabaEngine.brandOnlyAfter) continue;
        expect(byId[s[i].carId]!.brand, isNot(byId[s[i - 1].carId]!.brand), reason: 'seed=$seed');
      }
    }
  });

  test('marka değişince imza değişir → yeniden üretilir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = await ArabaEngine.load(prefs, _p(), pool, nowYear: base, seed: 1, currentBrand: 'Fiat');
    final ayni = await ArabaEngine.load(prefs, _p(), pool, nowYear: base, currentBrand: 'Fiat');
    expect(ayni.seed, 1, reason: 'aynı marka → aynı çizelge');
    final yeni = await ArabaEngine.load(prefs, _p(), pool, nowYear: base, seed: 2, currentBrand: 'Mercedes-Benz');
    expect(yeni.seed, 2, reason: 'marka değişti → yeniden');
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
