// Kehanet menüsü: 5 kart her ekran boyunda kaydırmasız sığar, yüzen barın altında kalmaz.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:magnus_app/core/widgets/floating_bar_spacer.dart';
import 'package:magnus_app/presentation/kehanet/kehanet_menu_screen.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const sizes = [
    Size(320, 568),
    Size(375, 667),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
  ];

  for (final size in sizes) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()} yazı x$scale', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        addTearDown(t.view.reset);
        await t.pumpWidget(ProviderScope(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const KehanetMenuScreen(),
          ),
        ));
        await t.pump(const Duration(milliseconds: 16));

        expect(t.takeException(), isNull);
        final scrollable = t.state<ScrollableState>(find.byType(Scrollable));
        expect(scrollable.position.maxScrollExtent, closeTo(0, 0.01));
        expect(scrollable.position.physics, isA<NeverScrollableScrollPhysics>());

        final cards = find.byType(GestureDetector).evaluate().where(
              (e) => (e.widget as GestureDetector).onTap != null,
            );
        final barTop = t.getTopLeft(find.byType(FloatingBarSpacer)).dy;
        final labels = ['Faloya', 'Maganda', 'Tamua', 'Yana'];
        for (final l in labels) {
          expect(find.text(l), findsOneWidget);
          expect(t.getBottomLeft(find.text(l)).dy, lessThanOrEqualTo(barTop));
        }
        expect(cards.length, greaterThanOrEqualTo(5));
      });
    }
  }
}
