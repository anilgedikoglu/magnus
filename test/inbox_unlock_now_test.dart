// Gelen kutusu: hazırlanan fal ödüllü reklamla hemen hazır olur (kalıcı); okunan/tamamlanan fal
// sayısı (geçiş reklamı eşiği) MagnusHafiza'da doğru sayılır.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/magnus_ses/magnus_hafiza.dart';
import 'package:magnus_app/data/models/inbox_item.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/data/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

InboxItem _item(String id, DateTime unlock) => InboxItem(
      id: id,
      title: 'Kahve Falı',
      text: 'metin',
      date: DateTime.now().toIso8601String(),
      fortuneTypeKey: 'coffee',
      unlockAt: unlock.toIso8601String(),
    );

void main() {
  test('unlockNow: kilitli fal hemen hazır olur, kalıcıdır, diğerlerine dokunmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final n = c.read(inboxProvider.notifier);
    await n.addItem(_item('a', DateTime.now().add(const Duration(minutes: 6))));
    await n.addItem(_item('b', DateTime.now().add(const Duration(minutes: 6))));
    expect(c.read(inboxProvider).every((e) => e.isLocked), isTrue);

    await n.unlockNow('a');
    final a = c.read(inboxProvider).firstWhere((e) => e.id == 'a');
    final b = c.read(inboxProvider).firstWhere((e) => e.id == 'b');
    expect(a.isLocked, isFalse);
    expect(a.unlockProgress, 1.0);
    expect(b.isLocked, isTrue);

    // Kalıcı: depodan yeniden okununca da açık.
    expect(StorageService(prefs).loadInbox().firstWhere((e) => e.id == 'a').isLocked, isFalse);
    // Bildirim: açılan fal "gelecekte açılacaklar" listesinden çıkar (NotificationSync yeniden kurar).
    final bekleyen = c.read(inboxProvider).where((e) {
      final t = DateTime.tryParse(e.unlockAt ?? '');
      return t != null && t.isAfter(DateTime.now());
    }).map((e) => e.id);
    expect(bekleyen, ['b']);
  });

  test('unlockNow: zaten açık faldaki unlockAt değişmez; bilinmeyen id sorun çıkarmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final n = c.read(inboxProvider.notifier);
    final gecmis = DateTime.now().subtract(const Duration(hours: 1));
    await n.addItem(_item('x', gecmis));
    await n.unlockNow('x');
    await n.unlockNow('yok');
    expect(c.read(inboxProvider).single.unlockAt, gecmis.toIso8601String());
  });

  test('MagnusHafiza.tamamlananFal: okunan + 25 sn ve üstü anlık fal sayılır, kalıcıdır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final h = MagnusHafiza(prefs);
    expect(h.tamamlananFal, 0);
    h.okundu('kahve', DateTime(2026, 11, 9));
    h.falTamamlandi();
    expect(h.tamamlananFal, 2);
    expect(MagnusHafiza(prefs).tamamlananFal, 2, reason: 'uygulama yeniden açılınca korunur');
  });
}
