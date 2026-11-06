// TabSwipe: ana sekmeler arası yatay kaydırma — yön kilidi, çok parmak, devre dışı.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/tab_swipe.dart';

void main() {
  late List<String> calls;
  var enabled = true;

  Widget host() => MaterialApp(
        home: TabSwipe(
          enabled: () => enabled,
          onSwipeLeft: () => calls.add('sol'),
          onSwipeRight: () => calls.add('sag'),
          child: const ColoredBox(color: Colors.black, child: SizedBox.expand()),
        ),
      );

  setUp(() {
    calls = [];
    enabled = true;
  });

  testWidgets('yatay kaydırma: sola ve sağa', (tester) async {
    await tester.pumpWidget(host());
    await tester.dragFrom(const Offset(300, 400), const Offset(-120, 4));
    await tester.dragFrom(const Offset(100, 400), const Offset(120, -6));
    expect(calls, ['sol', 'sag']);
  });

  testWidgets('dikey başlayan hareket sonra sola dönse de sekme değişmez', (tester) async {
    await tester.pumpWidget(host());
    final g = await tester.startGesture(const Offset(300, 400));
    await g.moveBy(const Offset(0, -80)); // önce dikey kaydırma → yön kilitlenir
    await g.moveBy(const Offset(-150, 80)); // sonra sola, başlangıç yüksekliğine
    await g.up();
    expect(calls, isEmpty);
  });

  testWidgets('eşiğin altındaki yatay hareket yok sayılır', (tester) async {
    await tester.pumpWidget(host());
    await tester.dragFrom(const Offset(300, 400), const Offset(-35, 0));
    expect(calls, isEmpty);
  });

  testWidgets('ikinci parmak inerse iptal', (tester) async {
    await tester.pumpWidget(host());
    final a = await tester.startGesture(const Offset(300, 400), pointer: 1);
    final b = await tester.startGesture(const Offset(200, 500), pointer: 2);
    await a.moveBy(const Offset(-150, 0));
    await b.moveBy(const Offset(-150, 0));
    await a.up();
    await b.up();
    expect(calls, isEmpty);
  });

  testWidgets('enabled false → hiçbir şey', (tester) async {
    enabled = false;
    await tester.pumpWidget(host());
    await tester.dragFrom(const Offset(300, 400), const Offset(-150, 0));
    expect(calls, isEmpty);
  });

  // Cam kaydırıcısı düzeltmesi: içteki bir kontrol (daha derin Listener) dokunuşta bayrağı
  // kaldırır; TabSwipe pointer-down'da enabled'ı false görür → o kontrolün üstünde başlayan
  // yatay sürükleme sekme değiştirmez. Kontrol dışında kaydırma hâlâ çalışır.
  testWidgets('içteki kontrolde başlayan yatay sürükleme sekme değiştirmez', (tester) async {
    var onControl = false;
    await tester.pumpWidget(MaterialApp(
      home: TabSwipe(
        enabled: () => !onControl,
        onSwipeRight: () => calls.add('sag'),
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          Positioned(
            left: 100,
            top: 380,
            width: 160,
            height: 60,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => onControl = true,
              onPointerUp: (_) => onControl = false,
              onPointerCancel: (_) => onControl = false,
              child: const SizedBox.expand(),
            ),
          ),
        ]),
      ),
    ));
    // Kaydırıcının üstünde başlayan sürükleme → sekme değişmez.
    await tester.dragFrom(const Offset(150, 410), const Offset(150, 0));
    expect(calls, isEmpty);
    // Kaydırıcı dışında başlayan sürükleme → sekme değişir (800×600 test ekranında).
    await tester.dragFrom(const Offset(150, 520), const Offset(150, 0));
    expect(calls, ['sag']);
  });
}
