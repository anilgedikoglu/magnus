// Kader Kitabı: sonraki açılım varsa sağ sayfanın altında ok, yoksa ok yok.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/presentation/kaderkitabi/kader_book_scene.dart';

void main() {
  Widget host(bool arrow) => MaterialApp(
        home: Scaffold(
          body: KaderBookScene(
            leftText: 'Sol',
            rightText: 'Sag',
            animate: false,
            showNextArrow: arrow,
          ),
        ),
      );

  const key = ValueKey('kaderNextArrow');

  testWidgets('sonraki sayfa varsa ok, parşömenin sağ altında', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 700);
    addTearDown(t.view.reset);
    await t.pumpWidget(host(true));
    await t.pump(const Duration(milliseconds: 16));
    expect(find.byKey(key), findsWidgets);
    final r = t.getRect(find.byKey(key).last);
    expect(r.center.dx, greaterThan(195), reason: 'sağ sayfa');
  });

  testWidgets('son sayfada ok yok', (t) async {
    await t.pumpWidget(host(false));
    await t.pump(const Duration(milliseconds: 16));
    expect(find.byKey(key), findsNothing);
  });
}
