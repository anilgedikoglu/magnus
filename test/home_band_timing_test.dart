// Regresyon (Anıl, 2026-11-09): "app açılınca 3 sn gecikme kaldır" + "fal gönderir göndermez yazı gelsin".
// Kural: sohbet mesajları beklemeden gelir.
//  1) Açılışta 6 sn'lik yasal perde menünün üstünde durur → selamlama perde KALKINCA hemen gelir
//     (perdenin arkasında harcanmaz).
//  2) Fal gönderilip menüye dönülünce gelen mesaj anında görünür, eldeki yazıyı beklemez.
//  3) Menüden çıkmadan karta dokunuşa cevap (hak bitti) anında gelir.
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
Future<void> _gercekBekle(WidgetTester t, {int adim = 60}) async {
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

String _yazi(WidgetTester t) => t.widget<Text>(find.byKey(_band)).data!;

void main() {
  // Önbellekteki yükleme önceki testin sahte zamanına bağlı kalıyor: her testte temizle.
  setUp(rootBundle.clear);

  testWidgets('açılış: chat perde kalkınca beklemeden gelir (perde arkasında gelmez)', (t) async {
    await _ac(t, perde: true);
    expect(StartupDisclaimer.perdeAcik.value, isTrue);

    await _kare(t, 4000);
    expect(_bandVar(), isFalse, reason: 'perde açıkken selamlama harcanmamalı');

    await _kare(t, 2000); // 6 sn: perde sönmeye başlar
    await _kare(t, 500); // 400 ms sönme bitti → menü görünür
    expect(StartupDisclaimer.perdeAcik.value, isFalse);
    expect(_bandVar(), isTrue, reason: 'menü görünür görünmez selamlama gelir');
    await _kapat(t);
  });

  testWidgets('perde yokken selamlama ilk karelerde gelir', (t) async {
    await _ac(t, perde: false);
    await _kare(t, 100);
    expect(_bandVar(), isTrue, reason: 'açılışta 3 sn beklenmez');
    await _kapat(t);
  });

  testWidgets('fal gönderilince mesaj anında gelir, selamlamanın süresini beklemez', (t) async {
    await _ac(t, perde: false);
    await _kare(t, 200);
    final selam = _yazi(t);

    final c = ProviderScope.containerOf(t.element(find.byType(MainTabsScreen)));
    c.read(kahveSentProvider.notifier).state = true; // kahve gönderildi → menüye dönüldü
    await _kare(t, 100);
    expect(_yazi(t), isNot(selam), reason: 'gönderir göndermez yazı değişir');
    await _kapat(t);
  });

  testWidgets('karta dokunuşa cevap (hak bitti): chat ANINDA gelir', (t) async {
    final bugun = DateTime.now().toIso8601String().substring(0, 10);
    await _ac(t, perde: false, prefsEk: {'kahve_bugun_tarih': bugun});
    await _kare(t, 200);
    final selam = _yazi(t);

    final kart = find.text('Kahve Falı');
    expect(kart, findsWidgets);
    await t.tap(kart.first, warnIfMissed: false);
    await _kare(t, 150);
    expect(_yazi(t), isNot(selam), reason: 'menüden çıkılmadı, dokunuşa cevap anında');
    await _kapat(t);
  });
}
