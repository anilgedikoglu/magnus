// GlassTabBar regresyon testleri.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/glass_tab_bar.dart';

const _labels = ['Kullanıcı Bilgileri', 'Ana Menü', 'Gelen Kutusu'];
const _pill = ValueKey('glassTabBarPill');

Widget _host(int selected, ValueChanged<int> onTap, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), disableAnimations: reduce),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: GlassTabBar(selected: selected, onTap: onTap, labels: _labels),
            ),
          ),
        ),
      ),
    );

/// Kapsülün merkezi hangi slotta? (0..2, kesirli)
double _pillSlot(WidgetTester tester) {
  final bar = tester.getRect(find.byType(GlassTabBar));
  final pill = tester.getRect(find.byKey(_pill));
  const inset = 5.0;
  final slot = (bar.width - 2 * inset) / 3;
  return (pill.center.dx - bar.left - inset - slot / 2) / slot;
}

void main() {
  testWidgets('3 sekme: etiketler, seçili durum ve dokunuş', (tester) async {
    final taps = <int>[];
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(1, taps.add));
    for (final l in _labels) {
      expect(find.bySemanticsLabel(l), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Ana Menü')),
      matchesSemantics(
          label: 'Ana Menü', isButton: true, isSelected: true,
          hasSelectedState: true, isInMutuallyExclusiveGroup: true, hasTapAction: true),
    );
    await tester.tap(find.bySemanticsLabel('Kullanıcı Bilgileri'));
    await tester.tap(find.bySemanticsLabel('Gelen Kutusu'));
    expect(taps, [0, 2]);
    handle.dispose();
  });

  testWidgets('seçim değişince kapsül yayla kayar ve hedef slota oturur', (tester) async {
    await tester.pumpWidget(_host(1, (_) {}));
    expect(_pillSlot(tester), closeTo(1, 0.01));
    await tester.pumpWidget(_host(2, (_) {}));
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _pillSlot(tester);
    expect(mid, greaterThan(1.05), reason: 'kayma başlamış olmalı');
    expect(mid, lessThan(1.98), reason: 'anında sıçramamalı (animasyonlu)');
    await tester.pumpAndSettle();
    expect(_pillSlot(tester), closeTo(2, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced-motion: kapsül anında yerine geçer', (tester) async {
    await tester.pumpWidget(_host(0, (_) {}, reduce: true));
    await tester.pumpWidget(_host(2, (_) {}, reduce: true));
    await tester.pump();
    expect(_pillSlot(tester), closeTo(2, 0.01));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
