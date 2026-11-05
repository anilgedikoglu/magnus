// Kader Çarkı: ok, seçilen dilimde durmalı — iki yönde de (2026-11-06 hatası: ters savrulmada
// ok hedefin aynasında duruyor, ekran başka dilimin falını açıyordu).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/presentation/kadercarki/kadercarki_screen.dart';

void main() {
  test('her başlangıç açısı, hedef ve yönde ok seçilen dilimin merkezinde durur', () {
    final rnd = Random(7);
    for (var k = 0; k < 2000; k++) {
      final current = (rnd.nextDouble() - 0.5) * 200; // birçok tur, negatif de
      final target = rnd.nextInt(6);
      final dir = rnd.nextBool() ? 1 : -1;
      final turns = 4 + rnd.nextInt(6);
      final end = kaderSpinEnd(current, target, dir, turns);
      expect(kaderSegUnderPointer(end), target, reason: 'k=$k dir=$dir');
      // Yön doğru ve en az [turns] tur.
      expect((end - current) * dir, greaterThanOrEqualTo(turns * 2 * pi - 1e-9));
      expect((end - current) * dir, lessThan((turns + 1) * 2 * pi));
      // Dilimin MERKEZİ: yarım dilim (30°) kadar iki yana oynatınca da aynı dilim.
      expect(kaderSegUnderPointer(end + 0.45), target);
      expect(kaderSegUnderPointer(end - 0.45), target);
    }
  });
}
