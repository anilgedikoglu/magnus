// "Falın hazır" bildirimleri: hangi öğe zamanlanır, numaralar kararlı mı; lamba sürgüsü davranışı.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/services/notification_service.dart';
import 'package:magnus_app/core/widgets/lamp_toggle.dart';
import 'package:magnus_app/data/models/inbox_item.dart';

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
            child: LampToggle(value: value, onChanged: cb, debugSeed: 1),
          ),
        ),
      );

  testWidgets('dokununca durum değişir; iz dışına dokunuş sayılmaz', (t) async {
    final got = <bool>[];
    await t.pumpWidget(host(false, got.add));
    await t.pump(const Duration(milliseconds: 16));
    await t.tap(find.byType(LampToggle));
    await t.pump(const Duration(milliseconds: 16));
    expect(got, [true]);
    final box = t.getRect(find.byType(LampToggle));
    await t.tapAt(box.topLeft + const Offset(2, 2));
    await t.pump(const Duration(milliseconds: 16));
    expect(got, [true], reason: 'sahne kenarı düğme değil');
  });

  testWidgets('düğmeyi karşıya sürükleyip bırakmak açar', (t) async {
    final got = <bool>[];
    await t.pumpWidget(host(false, got.add));
    await t.pump(const Duration(milliseconds: 16));
    final box = t.getRect(find.byType(LampToggle));
    // Düğme kapalıyken solda: merkez − 104 tasarım px (260/520 = 0.5 ölçek).
    final start = box.center - const Offset(52, 0);
    final g = await t.startGesture(start);
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(10, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await t.pump(const Duration(milliseconds: 16));
    expect(got, [true]);
  });
}
