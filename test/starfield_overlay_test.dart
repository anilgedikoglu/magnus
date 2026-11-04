// StarfieldOverlay / SkyDarkenOverlay regresyon testleri.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/starfield_overlay.dart';

void main() {
  testWidgets(
      'ilk kayan yıldız + ilk hale + aurora boyunca hatasız çizer, sürekli kare ister',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Stack(children: [
        Positioned.fill(child: SkyDarkenOverlay()),
        Positioned.fill(child: StarfieldOverlay()),
      ]),
    ));
    final shot = StarfieldOverlay.debugFirstShot();
    final halo = StarfieldOverlay.debugFirstHalo();
    final end = [shot.start + shot.duration, halo.start + halo.duration]
        .reduce((a, b) => a > b ? a : b);
    final steps = ((end + 1) / 0.1).ceil();
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    // Animasyon aktif → ticker bir sonraki kareyi planlamış olmalı.
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('reduced-motion: statik çizer, kare planlamaz (pil dostu)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: StarfieldOverlay(),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('küçük starCount (60 altı) clamp hatası vermez', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: StarfieldOverlay(starCount: 10),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
