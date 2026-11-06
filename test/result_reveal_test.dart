// Ortak sonuç açılışı: içerik yukarıdan aşağı açılır, dokununca hemen tamamlanır,
// reduced-motion'da animasyonsuz.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/result_reveal.dart';

Widget _app({bool reduce = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: ResultReveal(
          haptic: false,
          child: SizedBox(height: 900, child: Text('kaderin yazısı')),
        ),
      ),
    );

void main() {
  testWidgets('açılırken maske var, dokununca hemen tamamlanır', (t) async {
    await t.pumpWidget(_app());
    await t.pump(const Duration(milliseconds: 150));
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.text('kaderin yazısı'), findsOneWidget, reason: 'metin ağaçta, okunabilir');
    await t.tapAt(const Offset(10, 10));
    await t.pump();
    expect(find.byType(ShaderMask), findsNothing, reason: 'dokunuş açılışı bitirdi');
  });

  testWidgets('kendiliğinden biter', (t) async {
    await t.pumpWidget(_app());
    await t.pump(const Duration(milliseconds: 2300));
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('reduced-motion: animasyonsuz', (t) async {
    await t.pumpWidget(_app(reduce: true));
    await t.pump();
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('açılış bitince ve dokununca içerik yeniden kurulmaz (durum korunur)', (t) async {
    _Sayac.kurulum = 0;
    await t.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: ResultReveal(haptic: false, child: _Sayac()),
    ));
    await t.pump(const Duration(milliseconds: 150));
    await t.tapAt(const Offset(10, 10));
    await t.pump();
    await t.pump(const Duration(seconds: 3));
    expect(_Sayac.kurulum, 1);
  });
}

class _Sayac extends StatefulWidget {
  const _Sayac();
  static int kurulum = 0;
  @override
  State<_Sayac> createState() => _SayacState();
}

class _SayacState extends State<_Sayac> {
  @override
  void initState() {
    super.initState();
    _Sayac.kurulum++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 400);
}
