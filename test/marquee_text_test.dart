// Kayan yazı: sığan metin sabit; sığmayan tek satırda dikişsiz kayar; hareket azaltmada durur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/marquee_text.dart';

Widget _host(String text, {double width = 200, bool reduceMotion = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: width,
            child: MarqueeText(text, style: const TextStyle(fontSize: 10)),
          ),
        ),
      ),
    );

double _dx(WidgetTester t) {
  final tr = t.widget<Transform>(find.descendant(of: find.byType(MarqueeText), matching: find.byType(Transform)));
  return tr.transform.getTranslation().x;
}

void main() {
  testWidgets('sığan metin: tek kopya, hareket yok', (t) async {
    await t.pumpWidget(_host('Kia EV9'));
    expect(find.text('Kia EV9'), findsOneWidget);
    expect(find.descendant(of: find.byType(MarqueeText), matching: find.byType(Transform)), findsNothing);
  });

  testWidgets('sığmayan metin: tek satır, iki kopya, sürekli kayar ve tur sonunda başa döner', (t) async {
    const uzun = 'Mercedes-Benz EQS 580 4MATIC Edition One'; // 40 karakter × 10 px = 400 px > 200 px
    await t.pumpWidget(_host(uzun));
    expect(find.text(uzun), findsNWidgets(2)); // dikişsiz döngü için iki kopya
    final h = t.getSize(find.byType(MarqueeText)).height;
    expect(h, lessThanOrEqualTo(12)); // alt satıra inmedi (tek satır ≈ 10 px)

    final x0 = _dx(t);
    await t.pump(const Duration(seconds: 1));
    final x1 = _dx(t);
    expect(x1, lessThan(x0)); // sola kayıyor
    expect(x0 - x1, closeTo(28, 3)); // yavaş: ~28 px/sn

    // Bir tur = (400 + 48) px / 28 px/sn = 16 sn → başa (aynı görüntüye) döner.
    await t.pump(const Duration(seconds: 15));
    expect(_dx(t), closeTo(x0, 2));
  });

  testWidgets('hareket azaltma açık: kaymaz, tek kopya', (t) async {
    const uzun = 'Mercedes-Benz EQS 580 4MATIC Edition One';
    await t.pumpWidget(_host(uzun, reduceMotion: true));
    expect(find.text(uzun), findsOneWidget);
    expect(find.descendant(of: find.byType(MarqueeText), matching: find.byType(Transform)), findsNothing);
  });
}
