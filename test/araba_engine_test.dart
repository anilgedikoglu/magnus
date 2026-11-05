// "Arabam Ne?" motoru: aralıklar, kademe sırası, F yılı, tekrarsızlık, kalıcılık.
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

  ArabaTimeline gen(int seed, {String g = 'erkek', int age = 26}) =>
      ArabaEngine.generate(pool, gender: g, age: age, baseYear: base, seed: seed);

  test('havuz: kademeler dolu, id benzersiz', () {
    expect({for (final c in pool) c.id}.length, pool.length);
    for (final k in ['K1', 'K2', 'K3', 'K4', 'K5', 'K6', 'K7', 'E1', 'E2', 'E3', 'E4', 'F']) {
      expect(pool.where((c) => c.tier == k).length, greaterThanOrEqualTo(10), reason: k);
    }
  });

  test('5 aralık, sıralı ve çakışmasız, toplam ≤ 50 yıl, tekrarsız model', () {
    for (var seed = 0; seed < 300; seed++) {
      final t = gen(seed, age: 18 + seed % 40);
      final cars = t.slots.where((s) => !s.isGap).toList();
      expect(cars.length, 5);
      expect(t.slots.first.start, base);
      for (var i = 0; i < t.slots.length; i++) {
        final s = t.slots[i];
        expect(s.end, greaterThanOrEqualTo(s.start));
        if (i > 0) expect(s.start, t.slots[i - 1].end + 1);
        if (!s.isGap) expect(s.end - s.start + 1, inInclusiveRange(2, 12));
        if (s.isGap) expect(s.end - s.start + 1, inInclusiveRange(1, 2));
      }
      expect(t.slots.last.end, lessThanOrEqualTo(base + 50));
      final ids = cars.map((s) => s.carId).toList();
      expect(ids.toSet().length, 5);
    }
  });

  test('kademe neredeyse hiç düşmez (en fazla -1), F yalnız 2040+', () {
    var drops = 0, total = 0;
    for (var seed = 0; seed < 300; seed++) {
      final t = gen(seed);
      int? prev;
      for (final s in t.slots.where((s) => !s.isGap)) {
        final c = byId[s.carId]!;
        if (c.tier == 'F') expect(s.start, greaterThanOrEqualTo(2040));
        if (prev != null) {
          expect(c.level, greaterThanOrEqualTo(prev - 1), reason: 'seed $seed');
          if (c.level < prev) drops++;
          total++;
        }
        prev = c.level;
      }
    }
    expect(drops / total, lessThan(0.10));
  });

  test('gelir artar: son aralığın ortalama seviyesi ilkinden yüksek; elektrik sonraya kayar', () {
    var firstSum = 0, lastSum = 0, earlyEv = 0, earlyN = 0, lateEv = 0, lateN = 0, k7 = 0, n = 0;
    for (var seed = 0; seed < 300; seed++) {
      final cars = gen(seed).slots.where((s) => !s.isGap).toList();
      firstSum += byId[cars.first.carId]!.level;
      lastSum += byId[cars.last.carId]!.level;
      for (final s in cars) {
        final c = byId[s.carId]!;
        n++;
        if (c.tier == 'K7') k7++;
        final ev = c.fuel == 'elektrik' || c.fuel == 'hidrojen';
        if (s.start - base < 10) {
          earlyN++;
          if (ev) earlyEv++;
        } else if (s.start - base >= 25) {
          lateN++;
          if (ev) lateEv++;
        }
      }
    }
    expect(lastSum, greaterThan(firstSum));
    expect(lateEv / lateN, greaterThan(earlyEv / earlyN + 0.3));
    expect(k7 / n, lessThan(0.03));
  });

  test('cinsiyet eğilimi: kadın kullanıcıda kadın eğilimli, erkekte erkek eğilimli daha sık', () {
    var kadinKadin = 0, erkekKadin = 0;
    for (var seed = 0; seed < 600; seed++) {
      for (final s in gen(seed, g: 'kadin').slots.where((s) => !s.isGap)) {
        if (byId[s.carId]!.lean == 'kadin') kadinKadin++;
      }
      for (final s in gen(seed, g: 'erkek').slots.where((s) => !s.isGap)) {
        if (byId[s.carId]!.lean == 'kadin') erkekKadin++;
      }
    }
    expect(kadinKadin, greaterThan(erkekKadin * 1.3));
  });

  test('arabasız dönem oranı ~%15', () {
    var gaps = 0;
    for (var seed = 0; seed < 1000; seed++) {
      if (gen(seed).slots.any((s) => s.isGap)) gaps++;
    }
    expect(gaps / 1000, inInclusiveRange(0.11, 0.19));
  });

  test('deterministik: aynı seed aynı çizelge', () {
    final a = gen(7), b = gen(7);
    expect(a.toJson().toString(), b.toJson().toString());
  });

  test('kalıcılık: aynı kayıt geri gelir, açılan kutular ve hesaplandı bayrağı kalır; cinsiyet değişince yeniden', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final t1 = await ArabaEngine.load(prefs, _p(), pool, nowYear: base);
    final idx = t1.slots.indexWhere((s) => !s.isGap);
    await ArabaEngine.reveal(prefs, t1, idx);
    final t2 = await ArabaEngine.load(prefs, _p(), pool, nowYear: base + 3);
    expect(t2.seed, t1.seed);
    expect(t2.baseYear, base);
    expect(t2.isRevealed(idx), isTrue);
    expect(t2.computed, isTrue);
    expect(t2.slots.map((s) => s.carId).toList(), t1.slots.map((s) => s.carId).toList());
    final t3 = await ArabaEngine.load(prefs, _p(gender: 'kadın'), pool, nowYear: base, seed: 5);
    expect(t3.seed, 5);
    expect(t3.revealed, isEmpty);
  });

  test('tüm aralıklar geçmişte kalınca (yıllar sonra) yeni çizelge üretilir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final t1 = await ArabaEngine.load(prefs, _p(), pool, nowYear: base, seed: 11);
    final ayni = await ArabaEngine.load(prefs, _p(), pool, nowYear: t1.slots.last.end);
    expect(ayni.seed, 11); // son aralık sürüyor → aynı çizelge
    final yeni = await ArabaEngine.load(prefs, _p(), pool, nowYear: t1.slots.last.end + 1, seed: 12);
    expect(yeni.seed, 12);
    expect(yeni.baseYear, t1.slots.last.end + 1);
    expect(yeni.slots.first.start, t1.slots.last.end + 1);
  });
}
