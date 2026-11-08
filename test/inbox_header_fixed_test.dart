// Gelen Kutusu: başlık sabit ve opak, liste kaydırılınca başlığın üstüne binmez.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/inbox_item.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/data/services/storage_service.dart';
import 'package:magnus_app/presentation/inbox/inbox_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('başlık yerinde kalır, liste başlığın altında kesilir', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(402, 874);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({'language_picked': true});
    final prefs = await SharedPreferences.getInstance();
    final st = StorageService(prefs);
    for (var i = 0; i < 30; i++) {
      await st.addInboxItem(InboxItem(
        id: 'x$i',
        title: 'Fal $i',
        text: 'Örnek önizleme metni.',
        date: '2026-11-08T23:00:00',
        fortuneTypeKey: 'coffee',
        isRead: true,
      ));
    }
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: InboxScreen()),
    ));
    await t.pump();

    final appBar = find.byType(AppBar);
    final list = find.byType(ListView);
    final titleBefore = t.getRect(find.text('GELEN KUTUSU'));
    expect(t.getTopLeft(list).dy, greaterThanOrEqualTo(t.getBottomLeft(appBar).dy),
        reason: 'liste başlık bandının altından başlar');
    expect(t.widget<AppBar>(appBar).backgroundColor?.a, 1, reason: 'bant opak');

    await t.drag(list, const Offset(0, -600));
    await t.pump(const Duration(milliseconds: 300));
    expect(t.getRect(find.text('GELEN KUTUSU')), titleBefore);
    await t.pumpWidget(const SizedBox());
  });
}
