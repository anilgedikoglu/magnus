// Regresyon (Anıl, 2026-11-07): "chat menü açıldığı anda açılıyor, 3 saniye sonra dedik".
// Kural: menü GÖRÜNDÜKTEN 3 sn sonra chat bandı iner.
//  1) Açılışta 6 sn'lik yasal perde menünün üstünde durur → sayaç perde KALKINCA başlar
//     (eskiden perdenin arkasında dolup perde kalkınca menü + chat aynı anda görünüyordu).
//  2) Fal gönderilip menüye DÖNÜLÜNCE gelen mesaj da 3 sn sonra iner (eskiden anında).
//  3) Menüden çıkmadan karta dokunuşa cevap (hak bitti) ANINDA iner.
// Kutu hep yerinde; mesaj gelince içindeki 'homeChatText' belirir.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/app.dart';
import 'package:magnus_app/core/widgets/startup_disclaimer.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/data/services/storage_service.dart';
import 'package:magnus_app/presentation/shell/main_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _band = ValueKey('homeChatText');
bool _bandVar() => find.byKey(_band).evaluate().isNotEmpty;

/// Gerçek zamanlı async işleri (prefs, rootBundle) bitirir; SAHTE saati İLERLETMEZ.
Future<void> _gercekBekle(WidgetTester t, {int adim = 15}) async {
  for (var i = 0; i < adim; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump();
  }
}

Future<void> _ac(WidgetTester t, {required bool perde, Map<String, Object> prefsEk = const {}}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  StartupDisclaimer.debugSkip = !perde;
  StartupDisclaimer.perdeAcik.value = false;
  t.view.devicePixelRatio = 2.0;
  t.view.physicalSize = const Size(780, 1688);
  addTearDown(t.view.reset);

  SharedPreferences.setMockInitialValues({'language_picked': true, ...prefsEk});
  final prefs = await SharedPreferences.getInstance();
  await StorageService(prefs).saveProfile(UserProfile(
    name: 'Deniz', age: 34, gender: 'kadin', job: 'ozelsektoru', maritalStatus: 'bekar',
    birthDate: '1991-04-12', birthCity: 'İzmir', zodiacSign: 'Koç', birthTime: '08:40',
    onboardingComplete: true,
  ));
  await t.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const MagnusApp(),
  ));
  await _gercekBekle(t);
}

/// Gerçek cihaz gibi ~16 ms'lik karelerle [ms] kadar ilerle (Ticker animasyonları her karede ilerler;
/// tek büyük pump'ta ilk kare animasyonun BAŞLANGICI sayılır ve değer hiç değişmez).
Future<void> _kare(WidgetTester t, int ms) async {
  for (var i = 0; i < (ms / 16).ceil(); i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _kapat(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(seconds: 20));
}

void main() {
  // Önbellekteki yükleme önceki testin sahte zamanına bağlı kalıyor: her testte temizle.
  setUp(rootBundle.clear);

  testWidgets('açılış: chat perde KALKTIKTAN 3 sn sonra iner (perde arkasında inmez)', (t) async {
    await _ac(t, perde: true);
    expect(StartupDisclaimer.perdeAcik.value, isTrue);

    await _kare(t, 4000); // eski hata: 3. sn'de perdenin arkasında inerdi
    expect(_bandVar(), isFalse, reason: 'perde açıkken chat inmemeli');

    await _kare(t, 2000); // 6 sn: perde sönmeye başlar
    await _kare(t, 500); // 400 ms sönme bitti → menü görünür
    expect(StartupDisclaimer.perdeAcik.value, isFalse);
    expect(_bandVar(), isFalse, reason: 'menü göründüğü AN chat yok');

    await _kare(t, 2700);
    expect(_bandVar(), isFalse, reason: 'menü göründükten 3 sn dolmadan chat inmez');

    await _kare(t, 500);
    expect(_bandVar(), isTrue, reason: 'menü göründükten 3 sn sonra chat iner');
    await _kapat(t);
  });

  testWidgets('menüye dönüş (fal gönderildi): chat anında DEĞİL, 3 sn sonra iner', (t) async {
    await _ac(t, perde: false);
    await _kare(t, 200);
    expect(_bandVar(), isFalse);

    final c = ProviderScope.containerOf(t.element(find.byType(MainTabsScreen)));
    c.read(kahveSentProvider.notifier).state = true; // kahve gönderildi → menüye dönüldü
    await _kare(t, 200);
    expect(_bandVar(), isFalse, reason: 'menü önce görünür, chat hemen inmez (eskiden ANINDA inerdi)');

    await _kare(t, 2500); // dönüşten ~2,7 sn
    expect(_bandVar(), isFalse, reason: '3 sn dolmadan inmez');

    await _kare(t, 500);
    expect(_bandVar(), isTrue, reason: '3 sn sonra "falın hazırlanıyor" mesajıyla iner');
    await _kapat(t);
  });

  testWidgets('selamlamadan sonra gelen dönüş mesajı tam 3 sn sonra görünür', (t) async {
    await _ac(t, perde: false);
    await _kare(t, 7500); // selamlama çıktı, okuma süresi doldu
    String yazi() => t.widget<Text>(find.byKey(_band)).data!;
    final selam = yazi();

    final c = ProviderScope.containerOf(t.element(find.byType(MainTabsScreen)));
    c.read(kahveSentProvider.notifier).state = true;
    await _kare(t, 2800);
    expect(yazi(), selam, reason: '3 sn dolmadan değişmez');
    await _kare(t, 400);
    expect(yazi(), isNot(selam), reason: '3 sn sonra yeni mesaj');
    await _kapat(t);
  });

  testWidgets('karta dokunuşa cevap (hak bitti): chat ANINDA iner', (t) async {
    final bugun = DateTime.now().toIso8601String().substring(0, 10);
    await _ac(t, perde: false, prefsEk: {'kahve_bugun_tarih': bugun});
    expect(_bandVar(), isFalse);

    final kart = find.text('Kahve Falı');
    expect(kart, findsWidgets);
    await t.tap(kart.first, warnIfMissed: false);
    await _kare(t, 150);
    expect(_bandVar(), isTrue, reason: 'menüden çıkılmadı, dokunuşa cevap anında (3 sn beklemez)');
    await _kapat(t);
  });
}
