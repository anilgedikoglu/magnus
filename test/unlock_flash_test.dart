import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/unlock_flash.dart';

Widget _host(bool revealed, {bool reduced = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: UnlockFlash(
            revealed: revealed,
            color: const Color(0xFFFF55FF),
            child: const SizedBox(width: 200, height: 44),
          ),
        ),
      ),
    );

void main() {
  stateKorumaTestleri();
  testWidgets('baştan açık kutu parlamaz', (tester) async {
    await tester.pumpWidget(_host(true));
    expect(find.byType(CustomPaint), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('kapalı → açık geçişte bir kez parlar ve söner', (tester) async {
    await tester.pumpWidget(_host(false));
    await tester.pumpWidget(_host(true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.descendant(of: find.byType(UnlockFlash), matching: find.byType(CustomPaint)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.descendant(of: find.byType(UnlockFlash), matching: find.byType(CustomPaint)), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('azaltılmış harekette parlama yok', (tester) async {
    await tester.pumpWidget(_host(false, reduced: true));
    await tester.pumpWidget(_host(true, reduced: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.descendant(of: find.byType(UnlockFlash), matching: find.byType(CustomPaint)), findsNothing);
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
  Widget build(BuildContext context) => const SizedBox(width: 200, height: 44);
}

void stateKorumaTestleri() {
  testWidgets('flaş başlarken ve biterken çocuğun durumu korunur (yeniden kurulmaz)', (tester) async {
    _Sayac.kurulum = 0;
    Widget h(bool r) => Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: UnlockFlash(revealed: r, color: const Color(0xFFFF55FF), child: const _Sayac())),
        );
    await tester.pumpWidget(h(false));
    await tester.pumpWidget(h(true));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(_Sayac.kurulum, 1);
  });
}
