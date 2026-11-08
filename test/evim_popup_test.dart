// Evim Neresi? popup'ları: tek satır giriş, "Geç" yok, yıl tekerleği görünümü, küçük ekranda taşma yok.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/liquid_glass_panel.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/evim/evim_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester t, Size size, Map<String, Object> values) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues(Map.of(values));
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(const SizedBox()); // ProviderScope yeniden kurulsun
  await t.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: EvimScreen()),
  ));
  for (var i = 0; i < 12; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

const _asked = <String, Object>{'evim_il_asked': true, 'evim_il': 'İstanbul'};
const _big = Size(430, 932);
const _small = Size(375, 667);

void main() {
  // Önbellekteki yükleme önceki testin sahte zamanına bağlı kalıyor: her testte temizle.
  setUp(rootBundle.clear);

  testWidgets('il popup: kısa tek satır giriş, Geç yok, LG panel', (t) async {
    await _pump(t, _big, const {});
    expect(find.text('Gelecekte nerede yaşayacağını söyleyeceğim.'), findsOneWidget);
    expect(find.text('Geç'), findsNothing);
    expect(find.byType(LiquidGlassPanel), findsOneWidget);
    final text = t.widget<Text>(find.text('Gelecekte nerede yaşayacağını söyleyeceğim.'));
    expect(text.maxLines, 1);
  });

  testWidgets('yıl popup: tekerlek çizimi var, büyük ekranda panel uzar', (t) async {
    await _pump(t, _big, _asked);
    expect(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_YearDrumPainter'),
      findsOneWidget,
    );
    final big = t.getSize(find.byType(LiquidGlassPanel)).height;
    await _pump(t, _small, _asked);
    final small = t.getSize(find.byType(LiquidGlassPanel)).height;
    expect(big, greaterThan(small + 30), reason: '$big / $small');
  });

  testWidgets('küçük ekranda iki popup da taşmaz', (t) async {
    await _pump(t, _small, const {});
    expect(t.takeException(), isNull);
    await _pump(t, _small, _asked);
    expect(t.takeException(), isNull);
  });
}
