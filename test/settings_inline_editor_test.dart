// Kullanıcı Bilgileri: bilgi kartına dokununca düzenleyici ekran ortasında açılır pencere
// olarak DEĞİL açılır. 2026-11-05 (Anıl, kart düzeni): 1. kartın ALTINDA ara panel olarak
// açılır, halkalar (2. kart) ve ayarlar (3. kart) AŞAĞI itilir; biri açıkken diğerine
// dokunulursa önce açık olan kapanır, sonra yenisi açılır.
import 'package:flutter/material.dart';
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

Future<void> _settle(WidgetTester t, {int steps = 12}) async {
  for (var i = 0; i < steps; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('bilgi kartı düzenleyicisi daire alanında açılır, kapanınca daireler döner',
      (t) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    StartupDisclaimer.debugSkip = true; // açılış perdesi ayrı testte
    t.view.devicePixelRatio = 2.0;
    t.view.physicalSize = const Size(780, 1688);
    addTearDown(t.view.reset);

    SharedPreferences.setMockInitialValues({'language_picked': true});
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
    await _settle(t, steps: 25);
    final c = ProviderScope.containerOf(t.element(find.byType(MainTabsScreen)));
    c.read(mainTabProvider.notifier).state = MainTab.profile;
    await _settle(t);

    final donutTop = t.getTopLeft(find.text('Modalite')).dy;
    final cardBottom = t.getBottomLeft(find.text('Medeni Hal')).dy;
    expect(donutTop, greaterThan(cardBottom));

    final barriers = find.byType(ModalBarrier).evaluate().length;
    await t.ensureVisible(find.text('Medeni Hal')); // kart düzeni kaydırılabilir
    await t.tap(find.text('Medeni Hal'));
    await _settle(t);

    // Açılır pencere YOK; düzenleyici 1. kartın altında, halkalar AŞAĞI itildi (kaybolmadı).
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(ModalBarrier).evaluate().length, barriers); // yeni pencere/bariyer yok
    final save = find.text('Kaydet');
    expect(save, findsOneWidget);
    expect(t.getTopLeft(save).dy, greaterThan(cardBottom));
    expect(t.getTopLeft(find.text('Modalite')).dy, greaterThan(t.getBottomLeft(save).dy));
    // Bilgi kartları görünür ve dokunulabilir kalır (ekran örtülmez).
    expect(find.text('Doğum Tarihi'), findsOneWidget);

    // Başka karta dokununca düzenleyici o alana geçer.
    await t.ensureVisible(find.text('Doğum Tarihi'));
    await t.tap(find.text('Doğum Tarihi'));
    await _settle(t);
    expect(find.text('Kaydet'), findsOneWidget);

    // İptal → daireler geri gelir.
    await t.ensureVisible(find.text('İptal'));
    await t.tap(find.text('İptal'));
    await _settle(t);
    expect(find.text('Kaydet'), findsNothing);
    expect(find.text('Modalite'), findsOneWidget);

    // Sekmeden çıkınca açık düzenleyici kapanır.
    await t.ensureVisible(find.text('Medeni Hal')); // kart düzeni kaydırılabilir
    await t.tap(find.text('Medeni Hal'));
    await _settle(t);
    expect(find.text('Kaydet'), findsOneWidget);
    c.read(mainTabProvider.notifier).state = MainTab.home;
    await _settle(t);
    c.read(mainTabProvider.notifier).state = MainTab.profile;
    await _settle(t);
    expect(find.text('Kaydet'), findsNothing);
    expect(find.text('Modalite'), findsOneWidget);

    // Doğum Yeri (metin) + klavye: gövde küçülür, panel klavyenin üstüne kayar ve
    // DOKUNULABİLİR (Codex: Transform ile alan dışına taşan kısım dokunuş almıyordu).
    await t.ensureVisible(find.text('Doğum Yeri'));
    await t.tap(find.text('Doğum Yeri'));
    await _settle(t);
    t.view.viewInsets = const FakeViewPadding(bottom: 700); // ~350 mantıksal klavye
    await _settle(t);
    final iptal = find.text('İptal');
    expect(t.getBottomLeft(iptal).dy, lessThan(844 - 350));
    await t.tap(iptal);
    t.view.resetViewInsets();
    await _settle(t);
    expect(find.text('Kaydet'), findsNothing);
    expect(find.text('Medeni Hal'), findsOneWidget);
    expect(find.text('Modalite'), findsOneWidget);

    // Aynı kutuya İKİNCİ dokunuş açık paneli kapatır (X gerekmez; Anıl, 2026-11-06).
    await t.ensureVisible(find.text('Medeni Hal'));
    await t.tap(find.text('Medeni Hal'));
    await _settle(t);
    expect(find.text('Kaydet'), findsOneWidget);
    await t.ensureVisible(find.text('Medeni Hal').first);
    await t.tap(find.text('Medeni Hal').first); // kutunun kendisi (panel başlığı altta)
    await _settle(t);
    expect(find.text('Kaydet'), findsNothing);
    expect(find.text('Modalite'), findsOneWidget);
    // Başka kutu açıkken farklı kutu: önce kapanır, sonra yenisi açılır (değişmedi).
    await t.tap(find.text('Medeni Hal'));
    await _settle(t);
    await t.ensureVisible(find.text('Doğum Tarihi'));
    await t.tap(find.text('Doğum Tarihi'));
    await _settle(t);
    expect(find.text('Kaydet'), findsOneWidget);
    await t.ensureVisible(find.text('Doğum Tarihi').first);
    await t.tap(find.text('Doğum Tarihi').first);
    await _settle(t);
    expect(find.text('Kaydet'), findsNothing);

    await t.pumpWidget(const SizedBox.shrink());
    await _settle(t, steps: 3);
    await t.pump(const Duration(seconds: 3)); // metin alanı/odak gecikme zamanlayıcıları
  });
}
