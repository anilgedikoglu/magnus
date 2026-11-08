// Kader Çarkı: çark parmağı takip eder. Üst yarıda sağa sürükleme saat yönünde, alt yarıda ters yönde döndürür.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/kadercarki/kadercarki_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('yön parmağın çark merkezine göre konumundan gelir', () {
    expect(kaderDragSign(100, 400), 1);
    expect(kaderDragSign(700, 400), -1);
  });

  Future<double> sagaSurukle(WidgetTester t, double dyFromCenter) async {
    SharedPreferences.setMockInitialValues({'language_picked': true});
    final prefs = await SharedPreferences.getInstance();
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(402, 874);
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: KaderCarkiScreen()),
    ));
    for (var i = 0; i < 8; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump(const Duration(milliseconds: 16));
    }
    final wheel = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_WheelPainter',
    );
    double angle() => (t.widget<CustomPaint>(wheel).painter as dynamic).angle as double;
    final center = t.getCenter(wheel);
    final before = angle();
    // Yavaş sürükleme: savrulma başlamaz, yalnız yön ölçülür.
    await t.timedDragFrom(center + Offset(0, dyFromCenter), const Offset(40, 0), const Duration(seconds: 2));
    await t.pump();
    final delta = angle() - before;
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    return delta;
  }

  testWidgets('üst yarıda sağa sürükleme saat yönünde döndürür', (t) async {
    expect(await sagaSurukle(t, -100), greaterThan(0));
  });

  testWidgets('alt yarıda sağa sürükleme ters yönde döndürür', (t) async {
    expect(await sagaSurukle(t, 100), lessThan(0));
  });
}
