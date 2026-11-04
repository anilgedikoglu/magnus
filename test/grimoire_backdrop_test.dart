// GrimoireBackdrop: tek/çift, küçük/büyük ekran ölçülerinde hatasız çizilmeli
// (grain nokta dizisi tek uzunlukta RangeError veriyordu — 2026-11).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/grimoire_backdrop.dart';

void main() {
  for (final size in const [
    Size(391, 845), // tek boyutlar
    Size(390, 844),
    Size(320, 568), // küçük telefon
    Size(1024, 1366), // tablet (üst sınır)
    Size(1, 1), // uç durum
  ]) {
    testWidgets('GrimoireBackdrop ${size.width}x${size.height} hatasız', (t) async {
      t.view.devicePixelRatio = 1.0;
      t.view.physicalSize = size;
      addTearDown(t.view.reset);
      await t.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: GrimoireBackdrop(child: SizedBox.expand()),
      ));
      expect(t.takeException(), isNull);
      expect(find.byType(GrimoireBackdrop), findsOneWidget);
    });
  }

  testWidgets('görsel yüklenemezse çökmez (errorBuilder)', (t) async {
    await t.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: GrimoireBackdrop(asset: 'assets/images/yok_boyle_bir_gorsel.png',
          child: SizedBox.expand()),
    ));
    await t.pump();
    expect(t.takeException(), isNull);
  });
}
