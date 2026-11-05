// GlassTabBar regresyon testleri (3 slot: Ana Menü · Gelen Kutusu · Kullanıcı Bilgileri).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/bar_minimize.dart';
import 'package:magnus_app/core/widgets/glass_tab_bar.dart';

const _labels = ['Ana Menü', 'Gelen Kutusu', 'Kullanıcı Bilgileri'];
const _pill = ValueKey('glassTabBarPill');
const _dot = ValueKey('glassTabBarInboxDot');
const _inset = 5.0;

Widget _host(
  int selected,
  ValueChanged<int> onTap, {
  bool reduce = false,
  InboxBadge badge = InboxBadge.none,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: const Size(390, 844), disableAnimations: reduce),
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: GlassTabBar(
            selected: selected,
            onTap: onTap,
            labels: _labels,
            badge: badge,
          ),
        ),
      ),
    ),
  ),
);

double _slotWidth(WidgetTester tester) =>
    (tester.getRect(find.byType(GlassTabBar)).width - 2 * _inset) / kGlassBarSlots;

/// Kapsülün merkezi hangi slotta? (0..2, kesirli)
double _pillSlot(WidgetTester tester) {
  final bar = tester.getRect(find.byType(GlassTabBar));
  final pill = tester.getRect(find.byKey(_pill));
  final slot = _slotWidth(tester);
  return (pill.center.dx - bar.left - _inset - slot / 2) / slot;
}

Color _dotColor(WidgetTester tester) {
  final box = tester.widget<Container>(find.byKey(_dot)).decoration! as BoxDecoration;
  return box.color!;
}

void main() {
  testWidgets('3 slot: etiketler, seçili durum ve dokunuş', (tester) async {
    final taps = <int>[];
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(0, taps.add));
    for (final l in _labels) {
      expect(find.bySemanticsLabel(l), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Ana Menü')),
      matchesSemantics(
        label: 'Ana Menü',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Kullanıcı Bilgileri'));
    await tester.tap(find.bySemanticsLabel('Gelen Kutusu'));
    await tester.tap(find.bySemanticsLabel('Ana Menü'));
    expect(taps, [2, 1, 0]);
    handle.dispose();
  });

  testWidgets('seçim değişince kapsül yayla kayar ve hedef slota oturur', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0, (_) {}));
    expect(_pillSlot(tester), closeTo(0, 0.01));
    await tester.pumpWidget(_host(1, (_) {}));
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _pillSlot(tester);
    expect(mid, greaterThan(0.05), reason: 'kayma başlamış olmalı');
    expect(mid, lessThan(0.98), reason: 'anında sıçramamalı (animasyonlu)');
    await tester.pumpAndSettle();
    expect(_pillSlot(tester), closeTo(1, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('kapsül gittiği yöne uzar, varınca eski boyuna döner', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0, (_) {}));
    final slot = _slotWidth(tester);
    final start = tester.getRect(find.byKey(_pill));
    expect(start.width, closeTo(slot, 0.5));

    // Sağa (0 → 1): sağ kenar önden koşar.
    await tester.pumpWidget(_host(1, (_) {}));
    await tester.pump(const Duration(milliseconds: 50));
    final r = tester.getRect(find.byKey(_pill));
    expect(r.width, greaterThan(slot * 1.08), reason: 'giderken uzamalı');
    expect(r.width, lessThan(slot * 1.4), reason: 'yalnız azıcık uzamalı');
    expect(r.right - start.right, greaterThan(r.left - start.left),
        reason: 'sağa giderken uzama sağ tarafta');
    await tester.pumpAndSettle();
    final end = tester.getRect(find.byKey(_pill));
    expect(end.width, closeTo(slot, 0.5), reason: 'varınca kısalır');

    // Sola (1 → 0): sol kenar önden koşar.
    await tester.pumpWidget(_host(0, (_) {}));
    await tester.pump(const Duration(milliseconds: 50));
    final l = tester.getRect(find.byKey(_pill));
    expect(l.width, greaterThan(slot * 1.08));
    expect(end.left - l.left, greaterThan(end.right - l.right),
        reason: 'sola giderken uzama sol tarafta');
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_pill)).width, closeTo(slot, 0.5));
  });

  testWidgets('zarf rozeti: hazırlanıyor turuncu, hazır yeşil, yoksa nokta yok', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0, (_) {}));
    expect(find.byKey(_dot), findsNothing);

    await tester.pumpWidget(_host(0, (_) {}, badge: InboxBadge.preparing));
    expect(find.byKey(_dot), findsOneWidget);
    expect(_dotColor(tester), const Color(0xFFFFA62B));

    await tester.pumpWidget(_host(0, (_) {}, badge: InboxBadge.ready));
    expect(_dotColor(tester), const Color(0xFF44FF88));
  });

  testWidgets('reduced-motion: kapsül anında yerine geçer', (tester) async {
    await tester.pumpWidget(_host(0, (_) {}, reduce: true));
    await tester.pumpWidget(_host(2, (_) {}, reduce: true));
    await tester.pump();
    expect(_pillSlot(tester), closeTo(2, 0.01));
    expect(tester.getRect(find.byKey(_pill)).width, closeTo(_slotWidth(tester), 0.5));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('küçük bar: merkezden 0.837 ölçek, ikonlara dokunuş doğru slotta', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 366,
            height: kGlassBarHeight,
            child: GlassTabBar(
              selected: 0,
              onTap: taps.add,
              labels: _labels,
              minimize: const AlwaysStoppedAnimation(1.0),
            ),
          ),
        ),
      ),
    ));
    final outer = tester.getRect(find.byType(GlassTabBar));
    final pill = tester.getRect(find.byKey(_pill));
    // Kapsül yüksekliği (56 − 2·5) ölçekle küçülür; merkez sabit.
    expect(pill.height, closeTo((kGlassBarHeight - 2 * _inset) * kBarCompactScale, 0.5));
    expect(pill.center.dy, closeTo(outer.center.dy, 0.5));
    // Küçük barın sağ ucundaki profil ikonu: ölçeklenmiş slot merkezi.
    final w = outer.width * kBarCompactScale;
    final left = outer.center.dx - w / 2;
    final slot = (w - 2 * _inset * kBarCompactScale) / kGlassBarSlots;
    await tester.tapAt(Offset(left + _inset * kBarCompactScale + slot * 2.5, outer.center.dy));
    await tester.tapAt(Offset(left + _inset * kBarCompactScale + slot * 1.5, outer.center.dy));
    expect(taps, [2, 1]);
    // Küçük barın DIŞI (eski tam boy alanın ucu) bara dokunmaz.
    await tester.tapAt(Offset(outer.left + 3, outer.center.dy));
    expect(taps, [2, 1]);
  });

  testWidgets('seçili ikon iOS mavisi, diğerleri beyaz; kapsülle birlikte geçer', (tester) async {
    Color iconColor(int i) =>
        ((tester.widget<CustomPaint>(find.byKey(ValueKey('glassTabBarIcon$i'))).painter!
                as dynamic)
            .color as Color);
    await tester.pumpWidget(_host(0, (_) {}));
    expect(iconColor(0), kGlassBarSelectedColor);
    expect(iconColor(1), Colors.white);
    expect(iconColor(2), Colors.white);
    await tester.pumpWidget(_host(1, (_) {}));
    await tester.pump(const Duration(milliseconds: 60));
    // Geçiş sırasında: kaynak ve hedef ikon ara tonda (beyaz ile mavi arasında).
    expect(iconColor(1), isNot(Colors.white));
    expect(iconColor(1), isNot(kGlassBarSelectedColor));
    expect(iconColor(0), isNot(kGlassBarSelectedColor));
    await tester.pumpAndSettle();
    expect(iconColor(1), kGlassBarSelectedColor);
    expect(iconColor(0), Colors.white);
    expect(iconColor(2), Colors.white);
  });
}
