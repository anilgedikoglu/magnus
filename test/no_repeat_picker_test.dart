// CLAUDE.md "⚠️ NO-REPEAT KURALI → Doğru Yöntem" güvencesi.
// Faloya / Niyet / Kâhinler / Maganda / Tamua artık bu ortak seçiciyi kullanır.
// Havuz tükenince sıfırlama SON gösterilen id'yi korur → üst üste aynı metin gelmez.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/utils/no_repeat_picker.dart';

void main() {
  String idOf(Map e) => e['id'].toString();
  List<Map<String, Object>> havuz(int n) =>
      List.generate(n, (i) => {'id': i + 1});

  test('boş havuz → null', () {
    final p = pickNoRepeat<Map<String, Object>>(
        pool: <Map<String, Object>>[], shown: [], idOf: idOf);
    expect(p, isNull);
  });

  test('seçim shown\'a eklenir; verilen shown listesi mutasyona uğramaz', () {
    final shown = <String>[];
    final p = pickNoRepeat(
        pool: havuz(5), shown: shown, idOf: idOf, rng: Random(1))!;
    expect(shown, isEmpty, reason: 'orijinal liste değişmemeli');
    expect(p.shown.single, idOf(p.selected));
  });

  test('havuz bitene kadar hiç tekrar yok (N öğe → N farklı)', () {
    final rng = Random(7);
    var shown = <String>[];
    final seen = <String>{};
    for (var i = 0; i < 6; i++) {
      final p = pickNoRepeat(pool: havuz(6), shown: shown, idOf: idOf, rng: rng)!;
      final id = idOf(p.selected);
      expect(seen.contains(id), isFalse, reason: '$id tekrar geldi');
      seen.add(id);
      shown = p.shown;
    }
    expect(seen.length, 6);
  });

  test('havuz bitince sıfırlama SON id\'yi korur (üst üste yasağı)', () {
    final rng = Random(3);
    var shown = <String>[];
    String? lastId;
    for (var i = 0; i < 6; i++) {
      final p = pickNoRepeat(pool: havuz(6), shown: shown, idOf: idOf, rng: rng)!;
      lastId = idOf(p.selected);
      shown = p.shown;
    }
    // 7. seçim → havuz boş → sıfırlama. Son gösterilen tekrar GELMEMELİ.
    final p7 = pickNoRepeat(pool: havuz(6), shown: shown, idOf: idOf, rng: rng)!;
    expect(idOf(p7.selected), isNot(lastId));
    expect(p7.shown.first, lastId, reason: 'son id korunmalı');
    expect(p7.shown.length, 2);
  });

  test('100 döngü boyunca asla üst üste aynı id gelmez', () {
    final rng = Random(42);
    var shown = <String>[];
    String? prev;
    for (var i = 0; i < 100; i++) {
      final p = pickNoRepeat(pool: havuz(4), shown: shown, idOf: idOf, rng: rng)!;
      final id = idOf(p.selected);
      expect(id, isNot(prev), reason: '$i. turda üst üste $id');
      prev = id;
      shown = p.shown;
    }
  });

  test('tek öğeli havuz → zorunlu tekrar (çökme yok)', () {
    final p1 =
        pickNoRepeat(pool: havuz(1), shown: [], idOf: idOf, rng: Random(1))!;
    final p2 = pickNoRepeat(
        pool: havuz(1), shown: p1.shown, idOf: idOf, rng: Random(1))!;
    expect(idOf(p2.selected), idOf(p1.selected));
  });
}
