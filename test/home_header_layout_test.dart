// Ana menü layer 2 ↔ layer 1 bağı (Anıl, 2026-11-06): layer 2 yalnız görünen sohbet satırı
// kadar uzun; boyu değişince ızgara görünürken birlikte iner, başlık gizliyken menü yerinde
// kalır (kaydırma düzeltmesi), layer 2 ızgarayla aynı hızda kayar ve gizliyken görünmez.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/presentation/home/home_header_layout.dart';

const double _inset = 12; // sahte üst güvenli alan
const double _gap = 8; // layer 2 – ızgara aralığı

class _Harness extends StatelessWidget {
  const _Harness({required this.height, required this.ctrl, this.hold = 0});
  final ValueNotifier<double> height;
  final ScrollController ctrl;
  final double hold;

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
                HeaderSpacerSliver(
                    height: height, extra: _inset + _gap, slack: _gap, hold: hold),
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
              hold: hold,
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

  testWidgets('kaydırmada ekran okuyucu düğümü de bantla birlikte taşınır (Codex)', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        Positioned.fill(
          child: CustomScrollView(controller: ctrl, slivers: [
            HeaderSpacerSliver(height: height, extra: _inset + _gap, slack: _gap),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => const SizedBox(height: 100),
                childCount: 30,
              ),
            ),
          ]),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ScrollFollower(
            controller: ctrl,
            child: Semantics(
              label: 'bant',
              container: true,
              child: const SizedBox(height: 68),
            ),
          ),
        ),
      ]),
    ));
    Rect global(SemanticsNode n) {
      var r = n.rect;
      for (SemanticsNode? c = n; c != null; c = c.parent) {
        if (c.transform != null) r = MatrixUtils.transformRect(c.transform!, r);
      }
      return r;
    }

    final dpr = t.view.devicePixelRatio;
    final before = global(t.getSemantics(find.bySemanticsLabel('bant')));
    ctrl.jumpTo(30);
    await t.pump();
    final after = global(t.getSemantics(find.bySemanticsLabel('bant')));
    expect(after.top, closeTo(before.top - 30 * dpr, 0.01));
    handle.dispose();
  });

  testWidgets('bekleme: önce menü bandın ALTINA girer, sonra bant menüyle birlikte çıkar', (t) async {
    await t.pumpWidget(_Harness(height: height, ctrl: ctrl, hold: 120));
    Rect l2() => t.getRect(find.byKey(const ValueKey('layer2')));
    ctrl.jumpTo(80);
    await t.pump();
    expect(l2().top, 0, reason: 'bekleme bitmeden bant yerinde');
    expect(top(t, 'item0'), _inset + 56 + _gap - 80, reason: 'menü kayıyor (bandın altına)');
    ctrl.jumpTo(150);
    await t.pump();
    expect(l2().top, -30, reason: 'bekleme sonrası menüyle aynı hızda');
    ctrl.jumpTo(120 + _inset + 56 + 5);
    await t.pump();
    expect(l2().bottom, lessThanOrEqualTo(0), reason: 'tamamen çıktı');
    // Geri: bant üstten iner, beklemede yerine oturur, menü son kısmı altından çıkar.
    ctrl.jumpTo(100);
    await t.pump();
    expect(l2().top, 0);
    ctrl.jumpTo(0);
    await t.pump();
    expect(top(t, 'item0') - l2().bottom, _gap, reason: 'her şey ilk yerinde');
  });

  testWidgets('bekleme sırasında bant uzarsa menü onunla iner; gizliyken menü oynamaz', (t) async {
    await t.pumpWidget(_Harness(height: height, ctrl: ctrl, hold: 120));
    Rect l2() => t.getRect(find.byKey(const ValueKey('layer2')));
    ctrl.jumpTo(60);
    await t.pump();
    final item = top(t, 'item1');
    height.value = 104;
    await t.pump();
    expect(top(t, 'item1'), item + 48, reason: 'bant uzadı, altındaki menü de indi');
    expect(l2().top, 0);
    ctrl.jumpTo(1000);
    await t.pump();
    final before = top(t, 'item12');
    height.value = 152;
    await t.pump();
    expect(top(t, 'item12'), before, reason: 'gizli bant uzadı, menü yerinde');
    expect(l2().bottom, lessThanOrEqualTo(0));
  });

  testWidgets('belirme (reveal): gizli bant kaydırma değişmeden üstte görünür', (t) async {
    final reveal = ValueNotifier<double>(0);
    addTearDown(reveal.dispose);
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        Positioned.fill(
          child: CustomScrollView(controller: ctrl, slivers: [
            HeaderSpacerSliver(height: height, extra: _inset + _gap, slack: _gap, hold: 120),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => const SizedBox(height: 100),
                childCount: 30,
              ),
            ),
          ]),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ScrollFollower(
            controller: ctrl,
            hold: 120,
            reveal: reveal,
            child: const SizedBox(key: ValueKey('bant'), height: 68),
          ),
        ),
      ]),
    ));
    Rect bant() => t.getRect(find.byKey(const ValueKey('bant')));
    ctrl.jumpTo(1000);
    await t.pump();
    expect(bant().bottom, lessThanOrEqualTo(0), reason: 'kaydırma gizledi');
    reveal.value = 1;
    await t.pump();
    expect(bant().top, 0, reason: 'belirdi');
    expect(ctrl.offset, 1000, reason: 'menü kımıldamadı');
    reveal.value = 0.5;
    await t.pump();
    expect(bant().top, -34, reason: 'yarı yolda');
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
