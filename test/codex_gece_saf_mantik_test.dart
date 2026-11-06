import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/presentation/iching/iching_screen.dart';
import 'package:magnus_app/presentation/kadercarki/kadercarki_screen.dart';
import 'package:magnus_app/presentation/kaderkitabi/kader_book_scene.dart';

void main() {
  test('Cark: sinirin iki yani, tam tur periyodu ve iki donus yonu', () {
    const epsilon = 1e-7;
    for (var boundary = 0; boundary < 6; boundary++) {
      final angle = math.pi - boundary * math.pi / 3;
      final before = kaderSegUnderPointer(angle - epsilon);
      final after = kaderSegUnderPointer(angle + epsilon);
      expect(after, (before + 5) % 6);
      for (final delta in [-epsilon, epsilon]) {
        final current = angle + delta;
        for (final turns in [-100, -1, 0, 1, 100]) {
          expect(kaderSegUnderPointer(current + turns * 2 * math.pi),
              kaderSegUnderPointer(current));
        }
        for (var target = 0; target < 6; target++) {
          for (final dir in [-1, 1]) {
            final end = kaderSpinEnd(current, target, dir, 0);
            expect(kaderSegUnderPointer(end), target);
            expect((end - current) * dir, inInclusiveRange(0, 2 * math.pi));
          }
        }
      }
    }
  });

  test('I-Ching: 64 heksagramda metin sirasi degisse de alttan uste ayni sonuc', () {
    for (var mask = 0; mask < 64; mask++) {
      final expected = List.generate(6, (i) => mask & (1 << i) != 0);
      final rows = List.generate(6, (i) =>
          '${i + 1}. sıra: ${expected[i] ? 'Yazı, Tura, Tura' : 'Yazı, Yazı, Tura'}');
      expect(ichingCizgileri(rows.reversed.join('\r\n')), expected);
      expect(ichingCizgileri(rows.take(5).join('\n')), isNull);
    }
  });

  testWidgets('Kitap: bos, tek kelime ve sigmayan bosluksuz metin kayipsiz bolunur',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    const page = Size(118, 196);
    await tester.runAsync(() => GoogleFonts.pendingFonts([
          kaderPageStyle(page),
        ]));
    for (final text in ['', 'Kader', List.filled(4096, 'A').join()]) {
      final (left, right, scale) =
          splitKaderPages(text, page, TextScaler.noScaling);
      expect(left + right, text);
      expect(scale, inInclusiveRange(0.6, 1.0));
    }
  });
}
