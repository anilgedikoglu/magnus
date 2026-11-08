// GEÇİCİ görsel doğrulama — gerçek bg görseli üstünde kare yakalar, sonra silinir.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/starfield_overlay.dart';

void main() {
  testWidgets('starfield görsel yakalama', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688); // 390x844 mantıksal
    addTearDown(tester.view.reset);

    const key = ValueKey('sky');
    const bg = 'assets/images/signinbackground.png';
    // Transform hep ağaçta → zoom değişince StarfieldOverlay State'i korunur.
    Widget scene({double zoom = 1, Offset pivot = Offset.zero}) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: key,
            child: ClipRect(
              child: Transform.scale(
                scale: zoom,
                origin: pivot,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(bg, fit: BoxFit.cover),
                  const SkyDarkenOverlay(),
                  const StarfieldOverlay(),
                ]),
              ),
            ),
          ),
        );

    await tester.pumpWidget(scene());
    await tester.runAsync(() async {
      await precacheImage(
          const AssetImage(bg), tester.element(find.byType(Stack).first));
    });
    await tester.pump();

    final s = StarfieldOverlay.debugFirstShot();
    // Kaymanın %35'i ve %65'i: hareket + kuyruk uzunluğu görülsün.
    var elapsed = 0.0;
    for (final (name, frac) in [('a35', 0.35), ('b65', 0.65)]) {
      final target = s.start + s.duration * frac;
      await tester.pump(Duration(microseconds: ((target - elapsed) * 1e6).round()));
      elapsed = target;
      await expectLater(find.byKey(key), matchesGoldenFile('goldens/shot_${name}_tam.png'));
      final hx = (s.x0 + s.dx * frac) * 390, hy = (s.y0 + s.dy * frac) * 844;
      await tester.pumpWidget(scene(zoom: 4, pivot: Offset(hx - 195, hy - 422)));
      await expectLater(find.byKey(key), matchesGoldenFile('goldens/shot_${name}_zoom4x.png'));
      await tester.pumpWidget(scene());
    }
  });
}
