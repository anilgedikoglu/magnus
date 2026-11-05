// Kahve falı konu kutuları ilk açılışta da TAM genişlikte (Anıl, 2026-11-06: ilk tıklayışta
// kutular ince dikey çubuk gibi başlayıp sonra açılıyordu — genişlik ikon görselinden
// geliyordu; görsel henüz yüklenmemişken 0'dı). Test ortamında görsel yüklenmez → tam o an.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/coffee/coffee_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('konu kutuları görsel yüklenmeden de hücreyi doldurur (ince çubuk değil)',
      (t) async {
    SharedPreferences.setMockInitialValues({'language_picked': true});
    final prefs = await SharedPreferences.getInstance();
    t.view.devicePixelRatio = 3;
    t.view.physicalSize = const Size(402 * 3, 874 * 3);
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: CoffeeScreen()),
    ));
    await t.pump();
    final icons = find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('fal_konu/'));
    expect(icons, findsNWidgets(4));
    for (final e in icons.evaluate()) {
      // İkonu saran kutu (gradyanlı, çerçeveli Container).
      final box = find.ancestor(of: find.byWidget(e.widget), matching: find.byType(Container)).last;
      final w = t.getSize(box).width;
      expect(w, greaterThan(120), reason: 'kutu hücre genişliğinde (ince çubuk değil)');
    }
    await t.pumpWidget(const SizedBox());
  });
}
