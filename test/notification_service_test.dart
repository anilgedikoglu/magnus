// "Falın hazır" bildirimleri: hangi öğe zamanlanır, numaralar kararlı mı; lamba sürgüsü davranışı.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/services/notification_service.dart';
import 'package:magnus_app/core/widgets/glass_tab_bar.dart' show kGlassBarHeight;
import 'package:magnus_app/core/widgets/lamp_toggle.dart';
import 'package:magnus_app/data/models/inbox_item.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

InboxItem _item(String id, DateTime? unlock) => InboxItem(
      id: id,
      title: 'Kahve Falı',
      text: 'x',
      date: '2026-11-08T10:00:00',
      fortuneTypeKey: 'coffee',
      unlockAt: unlock?.toIso8601String(),
    );

void main() {
  final now = DateTime(2026, 11, 8, 12);

  test('yalnız kilidi ileride açılan fallar zamanlanır', () {
    final items = [
      _item('gecmis', now.subtract(const Duration(minutes: 1))),
      _item('gelecek', now.add(const Duration(minutes: 6))),
      _item('kilitsiz', null),
    ];
    expect(pendingForNotification(items, now).map((e) => e.id), ['gelecek']);
  });

  test('bildirim numarası kararlı, pozitif, 31 bit', () {
    final a = notificationIdFor('fal-123');
    expect(a, notificationIdFor('fal-123'));
    expect(a, isNot(notificationIdFor('fal-124')));
    expect(a, inInclusiveRange(0, 0x7fffffff));
  });

  Widget host(bool value, ValueChanged<bool> cb) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 260,
            child: LampToggle(value: value, onChanged: cb, onLabel: 'AÇIK', offLabel: 'KAPALI'),
          ),
        ),
      );

  test('bildirimler varsayılan açık; kapatılmışsa kapalı kalır', () async {
    SharedPreferences.setMockInitialValues({});
    expect(NotificationsEnabledNotifier(await SharedPreferences.getInstance()).state, isTrue);
    SharedPreferences.setMockInitialValues({'bildirimler_acik': false});
    expect(NotificationsEnabledNotifier(await SharedPreferences.getInstance()).state, isFalse);
  });

  test('izin yalnız bir kez sorulur; reddedilirse kapanır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final n = NotificationsEnabledNotifier(prefs);
    await n.askOnce(); // test ortamında izin verilmez
    expect(n.state, isFalse);
    expect(prefs.getBool('bildirimler_acik'), isFalse);
    expect(prefs.getBool('bildirim_izni_soruldu'), isTrue);
  });

  testWidgets('dış biçim cam bar ölçüsünde: tam en, kGlassBarHeight boy', (t) async {
    await t.pumpWidget(host(false, (_) {}));
    await t.pump(const Duration(milliseconds: 16));
    final box = t.getRect(find.byType(LampToggle));
    expect(box.width, 260);
    expect(box.height, kGlassBarHeight);
  });

  testWidgets('sürgüde yalnız durumun yazısı görünür', (t) async {
    double opacityOf(String text) =>
        t.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;
    await t.pumpWidget(host(false, (_) {}));
    await t.pump(const Duration(milliseconds: 16));
    expect(opacityOf('KAPALI'), 1);
    expect(opacityOf('AÇIK'), 0);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(host(true, (_) {}));
    await t.pump(const Duration(milliseconds: 16));
    expect(opacityOf('AÇIK'), 1);
    expect(opacityOf('KAPALI'), 0);
  });

  testWidgets('kenar ışığı hedefe tek yönde, atlamadan oturur', (t) async {
    double theta() {
      final w = find.byWidgetPredicate(
        (x) => x is CustomPaint && x.painter.runtimeType.toString() == '_LampPainter',
      );
      return (t.widget<CustomPaint>(w).painter as dynamic).sim.theta as double;
    }

    double wrap(double d) => math.atan2(math.sin(d), math.cos(d));

    Future<void> kosu(bool from, bool to) async {
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(host(from, (_) {}));
      await t.pump(const Duration(milliseconds: 16));
      await t.pumpWidget(host(to, (_) {}));
      var prev = theta();
      final deltas = <double>[];
      for (var i = 0; i < 150; i++) {
        await t.pump(const Duration(milliseconds: 16));
        final now = theta();
        deltas.add(wrap(now - prev));
        prev = now;
      }
      final hareket = deltas.where((d) => d.abs() > 1e-5).toList();
      expect(hareket, isNotEmpty);
      final isaret = hareket.first.sign;
      for (final d in hareket) {
        expect(d.sign, isaret, reason: 'ışık geri dönmemeli: $d');
      }
    }

    await kosu(false, true);
    await kosu(true, false);
  });

  testWidgets('dokununca durum değişir', (t) async {
    final got = <bool>[];
    await t.pumpWidget(host(false, got.add));
    await t.pump(const Duration(milliseconds: 16));
    await t.tap(find.byType(LampToggle));
    await t.pump(const Duration(milliseconds: 16));
    expect(got, [true]);
  });

  testWidgets('kapalıyken sağ yarıdaki sürgüyü sola sürükleyip bırakmak açar', (t) async {
    final got = <bool>[];
    await t.pumpWidget(host(false, got.add));
    await t.pump(const Duration(milliseconds: 16));
    final box = t.getRect(find.byType(LampToggle));
    final start = box.center + const Offset(65, 0); // kapalıyken sürgü sağ yarının ortasında
    final g = await t.startGesture(start);
    for (var i = 0; i < 14; i++) {
      await g.moveBy(const Offset(-10, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await t.pump(const Duration(milliseconds: 16));
    expect(got, [true]);
  });
}
