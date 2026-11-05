// Kısmetim açıklama havuzları: TR/EN eşit, cümle bütün, yıldan yıla değişir, aynı yıl sabit.
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/services/kismet_lines.dart';

void main() {
  final pools = {
    'spouse': (KismetLines.spouseTr, KismetLines.spouseEn, KismetLines.spouse),
    'partner': (KismetLines.partnerTr, KismetLines.partnerEn, KismetLines.partner),
    'gap': (KismetLines.gapTr, KismetLines.gapEn, KismetLines.gap),
  };

  test('TR ve EN aynı uzunlukta, tekrarsız, her cümle noktalamayla biter', () {
    expect(KismetLines.spouseTr.length, greaterThanOrEqualTo(40));
    for (final e in pools.entries) {
      final (tr, en, _) = e.value;
      expect(tr.length, en.length, reason: e.key);
      expect(tr.toSet().length, tr.length, reason: '${e.key} TR tekrar');
      expect(en.toSet().length, en.length, reason: '${e.key} EN tekrar');
      for (final s in [...tr, ...en]) {
        expect(RegExp(r'[.!?]$').hasMatch(s), isTrue, reason: s);
      }
    }
  });

  test('art arda yıllar farklı; havuz uzunluğu kadar yıl boyunca tekrar yok; aynı yıl sabit', () {
    for (final seed in [0, 1, 7, 123456789, 2147483647]) {
      for (final e in pools.entries) {
        final (tr, _, pick) = e.value;
        final seen = <String>{};
        for (var y = 2026; y < 2026 + tr.length; y++) {
          final s = pick(seed, y, false);
          expect(seen.add(s), isTrue, reason: '${e.key} seed=$seed y=$y tekrar');
          expect(pick(seed, y, false), s); // aynı yıl → aynı cümle
          expect(pick(seed, y + 1, false), isNot(s)); // sonraki yıl farklı
        }
      }
    }
  });

  test('İngilizce seçim Türkçe ile aynı sıradaki cümle', () {
    for (var y = 2026; y < 2066; y++) {
      final i = KismetLines.spouseTr.indexOf(KismetLines.spouse(42, y, false));
      expect(KismetLines.spouse(42, y, true), KismetLines.spouseEn[i]);
    }
  });
}
