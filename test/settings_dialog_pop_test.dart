// Regresyon: Kullanıcı Bilgileri → ayarlar penceresi → Kapat sonrası ekran SİMSİYAH oluyordu.
// Neden: pencere kök navigatörde açılıyor, kapat ise dış context ile Navigator.pop(context)
// çağırıp sekme DAL navigatöründeki tek sayfayı (MainTabs) kapatıyordu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/app.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/data/services/storage_service.dart';
import 'package:magnus_app/presentation/settings/settings_screen.dart';
import 'package:magnus_app/presentation/shell/main_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle(WidgetTester t, {int steps = 12}) async {
  for (var i = 0; i < steps; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('ayarlar penceresi kapanınca Kullanıcı Bilgileri ekranı yerinde kalır', (t) async {
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

    await t.tap(find.byIcon(Icons.settings_outlined));
    await _settle(t);
    expect(find.byType(Dialog), findsOneWidget);

    await t.tap(find.text('Kapat').last);
    await _settle(t);

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(MainTabsScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget);

    // Ağaç kapanırken bekleyen zamanlayıcılar temizlensin.
    await t.pumpWidget(const SizedBox.shrink());
    await _settle(t, steps: 3);
  });
}
