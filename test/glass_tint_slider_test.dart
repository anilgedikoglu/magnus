// Cam saydamlık ayarı: ölçülen tablo (glass_tint.dart) + iOS 26 cam kaydırıcı.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/glass_tint.dart';
import 'package:magnus_app/core/widgets/liquid_glass_slider.dart';

void main() {
  test('saydamlık tablosu: uçlar ve orta ölçümle uyumlu, opaklık monoton artar', () {
    final clear = glassTintColor(0);
    final mid = glassTintColor(kGlassTintDefault);
    final tinted = glassTintColor(1);
    // Ölçüm: şeffaf α≈0.39 / gri≈115, orta α≈0.75 / ≈78, renkli α≈0.95 / ≈51.
    expect(clear.a, closeTo(0.39, 0.02));
    expect(clear.r * 255, closeTo(115, 3));
    expect(mid.a, closeTo(0.75, 0.03));
    expect(mid.r * 255, closeTo(78, 4));
    expect(tinted.a, closeTo(0.945, 0.02));
    expect(tinted.r * 255, closeTo(51, 3));
    var prev = -1.0;
    for (var i = 0; i <= 100; i++) {
      final a = glassTintColor(i / 100).a;
      expect(a, greaterThanOrEqualTo(prev - 1e-9), reason: 'opaklık %$i');
      prev = a;
    }
    // Aralık dışı kırpılır.
    expect(glassTintColor(-1), glassTintColor(0));
    expect(glassTintColor(2), glassTintColor(1));
  });

  Widget host(double value, ValueChanged<double> onChanged, ValueChanged<double> onEnd) =>
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SizedBox(
              width: 340,
              child: LiquidGlassSlider(
                value: value,
                onChanged: onChanged,
                onChangeEnd: onEnd,
                semanticLabel: 'Alt bar cam saydamlığı',
              ),
            ),
          ),
        ),
      );

  testWidgets('kaydırıcı: sürükleme değeri değiştirir, bırakınca son değer kaydedilir', (
    tester,
  ) async {
    var v = 0.5;
    final ends = <double>[];
    await tester.pumpWidget(host(v, (x) => v = x, ends.add));
    final knob = find.byKey(const ValueKey('liquidGlassSliderKnob'));
    final rest = tester.getSize(knob);
    expect(rest.width, closeTo(37, 0.5));
    expect(rest.height, closeTo(24, 0.5));

    final g = await tester.startGesture(tester.getCenter(knob));
    await tester.pump(); // tikleyici ilk karede başlar
    await tester.pump(const Duration(milliseconds: 200));
    // Basılıyken topuz cam merceğe büyür (58×37).
    final pressed = tester.getSize(knob);
    expect(pressed.width, greaterThan(50));
    expect(pressed.height, greaterThan(32));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(-12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(v, lessThan(0.5));
    expect(ends, hasLength(1));
    expect(ends.single, closeTo(v, 1e-9));
  });

  testWidgets('kaydırıcı: dokunulan noktaya atlar; uçlarda 0 ve 1', (tester) async {
    var v = 0.5;
    await tester.pumpWidget(host(v, (x) => v = x, (_) {}));
    final rect = tester.getRect(find.byType(LiquidGlassSlider));
    await tester.tapAt(Offset(rect.right - 50, rect.center.dy)); // rayın sağ ucu (simgenin solu)
    await tester.pumpAndSettle();
    expect(v, 1.0);
    await tester.pumpWidget(host(v, (x) => v = x, (_) {}));
    await tester.tapAt(Offset(rect.left + 50, rect.center.dy)); // rayın sol ucu
    await tester.pumpAndSettle();
    expect(v, 0.0);
  });
}
