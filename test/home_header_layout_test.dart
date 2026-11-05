// Ana menü layer 2 ↔ layer 1 bağı (Anıl, 2026-11-06): layer 2 yalnız görünen sohbet satırı
// kadar uzun; boyu değişince ızgara görünürken birlikte iner, başlık gizliyken menü yerinde
// kalır (kaydırma düzeltmesi), layer 2 ızgarayla aynı hızda kayar ve gizliyken görünmez.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/presentation/home/home_header_layout.dart';

const double _inset = 12; // sahte üst güvenli alan
const double _gap = 8; // layer 2 – ızgara aralığı

class _Harness extends StatelessWidget {
  const _Harness({required this.height, required this.ctrl});
  final ValueNotifier<double> height;
  final ScrollController ctrl;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              controller: ctrl,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                HeaderSpacerSliver(height: height, extra: _inset + _gap, slack: _gap),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => SizedBox(height: 100, key: ValueKey('item$i')),
                    childCount: 60,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScrollFollower(
              controller: ctrl,
              child: ValueListenableBuilder<double>(
                valueListenable: height,
                builder: (context, h, _) =>
                    SizedBox(key: const ValueKey('layer2'), height: _inset + h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  late ValueNotifier<double> height;
  late ScrollController ctrl;

  setUp(() {
    height = ValueNotifier<double>(56); // 1 satır
    ctrl = ScrollController();
  });

  tearDown(() {
    height.dispose();
    ctrl.dispose();
  });

  double top(WidgetTester t, String key) => t.getTopLeft(find.byKey(ValueKey(key))).dy;

  testWidgets('başlık görünürken: satır eklenince ızgara aynı miktarda aşağı iner, boşluk yok',
      (t) async {
    await t.pumpWidget(_Harness(height: height, ctrl: ctrl));
    expect(top(t, 'item0'), _inset + 56 + _gap);
    height.value = 104; // 2 satır
    await t.pump();
    expect(top(t, 'item0'), _inset + 104 + _gap, reason: 'menü layer 2\'nin hemen altında');
    expect(ctrl.offset, 0);
    // Layer 2'nin alt kenarı ile ilk kart arası hep aynı aralık.
    final l2 = t.getRect(find.byKey(const ValueKey('layer2')));
    expect(top(t, 'item0') - l2.bottom, _gap);
  });

  testWidgets('kısmen kaydırılmışken: layer 2 ve ızgara birlikte hareket eder', (t) async {
    await t.pumpWidget(_Harness(height: height, ctrl: ctrl));
    ctrl.jumpTo(30);
    await t.pump();
    final l2 = t.getRect(find.byKey(const ValueKey('layer2')));
    expect(l2.top, -30, reason: 'ızgarayla aynı hızda yukarı');
    height.value = 104;
    await t.pump();
    final l2b = t.getRect(find.byKey(const ValueKey('layer2')));
    expect(top(t, 'item0') - l2b.bottom, _gap, reason: 'aralık korunur');
  });

  testWidgets('başlık gizliyken boy değişirse menü yerinde kalır, başlık görünmez', (t) async {
    await t.pumpWidget(_Harness(height: height, ctrl: ctrl));
    ctrl.jumpTo(1000);
    await t.pump();
    final before = top(t, 'item12');
    height.value = 152; // 3 satır (gizliyken geldi)
    await t.pump();
    expect(top(t, 'item12'), before, reason: 'menü zıplamaz');
    expect(ctrl.offset, 1000 + 96, reason: 'ofset boy farkı kadar düzeltildi');
    final l2 = t.getRect(find.byKey(const ValueKey('layer2')));
    expect(l2.bottom, lessThanOrEqualTo(0), reason: 'gizli başlık bir piksel bile görünmez');
    // Geri yukarı kaydırınca yeni boyuyla gelir ve ızgaranın hemen üstünde durur.
    ctrl.jumpTo(0);
    await t.pump();
    expect(top(t, 'item0'), _inset + 152 + _gap);
  });

  testWidgets('fırlatma sürerken gizli başlık uzarsa akış kesintisiz sürer (sıçrama yok)',
      (t) async {
    await t.pumpWidget(_Harness(height: height, ctrl: ctrl));
    ctrl.jumpTo(800);
    await t.pump();
    // İçeriğin ekrandaki yeri (ilk öğenin üst kenarı; görünmese de hesaplanabilir).
    double content() => _inset + _gap + height.value - ctrl.offset;
    await t.flingFrom(const Offset(200, 400), const Offset(0, -300), 1500);
    await t.pump(const Duration(milliseconds: 16));
    await t.pump(const Duration(milliseconds: 16));
    final p0 = content();
    await t.pump(const Duration(milliseconds: 16));
    final p1 = content();
    height.value = 152;
    await t.pump(const Duration(milliseconds: 16));
    final p2 = content();
    final d1 = p1 - p0;
    final d2 = p2 - p1;
    expect(d1, lessThan(0), reason: 'fırlatma sürüyor');
    expect((d2 - d1).abs(), lessThan(6), reason: 'boy değişimi akışa 96 px sıçrama katmadı');
    await t.pumpAndSettle();
  });

  testWidgets('üstte esneme: layer 2 aşağı inmez', (t) async {
    await t.pumpWidget(_Harness(height: height, ctrl: ctrl));
    final g = await t.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(0, 120));
    await t.pump();
    expect(ctrl.offset, lessThan(0));
    expect(t.getRect(find.byKey(const ValueKey('layer2'))).top, 0);
    await g.up();
    await t.pumpAndSettle();
  });
}
