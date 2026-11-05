// Menü kartı adları kelime ortasından bölünmesin (Anıl, 2026-11-06: dar telefon + büyük
// yazıda "ASTROLO / Jİ"). En geniş kelime sığmıyorsa yazı küçülür; sığıyorsa dokunulmaz.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/word_safe_text.dart';

const _style = TextStyle(fontSize: 11.5, letterSpacing: 1.0, height: 1.15);

Future<Text> _pump(WidgetTester t, String text, double width, double scale) async {
  await t.pumpWidget(MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(width: width, child: WordSafeText(text, style: _style)),
      ),
    ),
  ));
  return t.widget<Text>(find.byType(Text));
}

double _wordWidth(String w, TextStyle s, double scale) {
  final tp = TextPainter(
    text: TextSpan(text: w, style: s),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.linear(scale),
  )..layout();
  final r = tp.width;
  tp.dispose();
  return r;
}

void main() {
  testWidgets('sığmayan tek kelime küçülür ve bölünmeden sığar', (t) async {
    const word = 'ASTROLOJİ';
    final full = _wordWidth(word, _style, 1.35);
    final width = full * 0.8; // kelime kutudan %20 geniş
    final text = await _pump(t, word, width, 1.35);
    final fs = text.style!.fontSize!;
    expect(fs, lessThan(11.5));
    expect(_wordWidth(word, text.style!, 1.35), lessThanOrEqualTo(width));
    // Tek satırda kaldı (kelime bölünmedi).
    final rp = t.renderObject<RenderBox>(find.byType(RichText));
    expect(rp.size.height, lessThan(fs * 1.15 * 1.35 * 1.5));
  });

  testWidgets('kelimeler sığıyorsa yazıya dokunulmaz (iki satıra normal kırılır)', (t) async {
    final text = await _pump(t, 'KAHVE FALI', 200, 1.0);
    expect(text.style!.fontSize, 11.5);
    expect(text.style!.letterSpacing, 1.0);
  });

  test('küçültme en alt orana kadar', () {
    final k = WordSafeText.fitScale('ÇOKUZUNBİRKELİME', _style, 5, minScale: 0.55);
    expect(k, 0.55);
  });
}
