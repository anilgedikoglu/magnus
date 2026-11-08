// Liquid Glass teması: varsayılan Flat, seçim kalıcı, saydamlık iki temayı da etkiler, yüzeyler temaya uyar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/glass_tab_bar.dart' show GlassBarRimPainter;
import 'package:magnus_app/core/widgets/glass_theme.dart';
import 'package:magnus_app/core/widgets/glass_tint.dart';
import 'package:magnus_app/core/widgets/liquid_glass_panel.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('varsayılan Flat; seçim kalıcı', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final n = GlassStyleNotifier(prefs);
    expect(n.state, GlassStyle.flat);
    await n.set(GlassStyle.candy);
    expect(GlassStyleNotifier(prefs).state, GlassStyle.candy);
  });

  test('saydamlık kaydırıcısı Candy camı da etkiler; Candy daha geçirgen ve daha renkli', () {
    expect(glassTintColor(0.2, candy: true).a, lessThan(glassTintColor(0.9, candy: true).a));
    expect(glassTintColor(0.55, candy: true).a, lessThan(glassTintColor(0.55).a));
    final c = glassTintColor(0.55, candy: true);
    expect(c.b, greaterThan(glassTintColor(0.55).b));
  });

  testWidgets('LG panel temaya uyar: kenar çizimi değişir', (t) async {
    Type rim() => t
        .widgetList<CustomPaint>(
          find.descendant(of: find.byType(LiquidGlassPanel), matching: find.byType(CustomPaint)),
        )
        .map((w) => w.painter)
        .whereType<CustomPainter>()
        .last
        .runtimeType;

    Widget app(GlassStyle s) => MaterialApp(
          home: GlassTheme(
            style: s,
            child: const Center(child: SizedBox(width: 200, height: 80, child: LiquidGlassPanel(child: SizedBox()))),
          ),
        );

    await t.pumpWidget(app(GlassStyle.flat));
    expect(rim(), GlassBarRimPainter);
    await t.pumpWidget(app(GlassStyle.candy));
    expect(rim(), CandyRimPainter);
  });
}
