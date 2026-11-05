import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/focus_ripple.dart';

void main() {
  late List<String> haptics;

  setUp(() {
    haptics = [];
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
      return null;
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget host({bool reduced = false, int beats = 3}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: FocusRipple(color: const Color(0xFFFF55FF), hapticBeats: beats)),
        ),
      );

  test('kalp atışı zarfı: güçlü vuruş zayıftan büyük, aralarda sönük', () {
    expect(FocusRipple.beat(0.06), greaterThan(0.95));
    expect(FocusRipple.beat(0.26), inInclusiveRange(0.5, 0.65));
    expect(FocusRipple.beat(0.6), lessThan(0.01));
  });

  testWidgets('titreşim yalnız ilk N vuruşta, sonra susar', (tester) async {
    await tester.pumpWidget(host(beats: 3));
    // 8 nabız döngüsü (1500 ms) boyunca ilerlet.
    for (var i = 0; i < 8 * 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(haptics.length, 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('azaltılmış harekette animasyon ve titreşim yok', (tester) async {
    await tester.pumpWidget(host(reduced: true));
    await tester.pump(const Duration(seconds: 5));
    expect(haptics, isEmpty);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
