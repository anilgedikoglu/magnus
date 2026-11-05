// Kullanıcı Bilgileri: bilgi kartına dokununca düzenleyici ekran ortasında açılır pencere
// olarak DEĞİL, polarite/modalite/element dairelerinin olduğu alanda açılır (Anıl, 2026-11-05).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/app.dart';
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
    await t.tap(find.text('Medeni Hal'));
    await _settle(t);

    // Açılır pencere YOK; düzenleyici daire alanında, daireler gizli.
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(ModalBarrier).evaluate().length, barriers); // yeni pencere/bariyer yok
    expect(find.text('Modalite'), findsNothing);
    final save = find.text('Kaydet');
    expect(save, findsOneWidget);
    expect(t.getTopLeft(save).dy, greaterThan(cardBottom));
    // Bilgi kartları görünür ve dokunulabilir kalır (ekran örtülmez).
    expect(find.text('Doğum Tarihi'), findsOneWidget);

    // Başka karta dokununca düzenleyici o alana geçer.
    await t.tap(find.text('Doğum Tarihi'));
    await _settle(t);
    expect(find.text('Kaydet'), findsOneWidget);

    // İptal → daireler geri gelir.
    await t.tap(find.text('İptal'));
    await _settle(t);
    expect(find.text('Kaydet'), findsNothing);
    expect(find.text('Modalite'), findsOneWidget);

    // Sekmeden çıkınca açık düzenleyici kapanır.
    await t.tap(find.text('Medeni Hal'));
    await _settle(t);
    expect(find.text('Kaydet'), findsOneWidget);
    c.read(mainTabProvider.notifier).state = MainTab.home;
    await _settle(t);
    c.read(mainTabProvider.notifier).state = MainTab.profile;
    await _settle(t);
    expect(find.text('Kaydet'), findsNothing);
    expect(find.text('Modalite'), findsOneWidget);

    await t.pumpWidget(const SizedBox.shrink());
    await _settle(t, steps: 3);
  });
}
