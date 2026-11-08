// Gerçek uygulama: fal ekranına giriş ve hemen çıkış Magnus'un hafızasına yazılır.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/app.dart';
import 'package:magnus_app/core/magnus_ses/magnus_hafiza.dart';
import 'package:magnus_app/core/widgets/startup_disclaimer.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/data/services/storage_service.dart';
import 'package:magnus_app/presentation/shell/main_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _bekle(WidgetTester t, {int adim = 12}) async {
  for (var i = 0; i < adim; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  setUp(rootBundle.clear);

  testWidgets('fala girip hemen çıkmak, geri ve go ile hafızaya yazılır', (t) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    StartupDisclaimer.debugSkip = true;
    StartupDisclaimer.perdeAcik.value = false;
    t.view.devicePixelRatio = 2;
    t.view.physicalSize = const Size(780, 1688);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({'language_picked': true});
    final prefs = await SharedPreferences.getInstance();
    await StorageService(prefs).saveProfile(UserProfile(
      name: 'Deniz', age: 34, gender: 'kadin', job: 'ozelsektoru', maritalStatus: 'evli',
      birthDate: '1991-04-12', birthCity: 'İzmir', zodiacSign: 'Koç', birthTime: '08:40',
      onboardingComplete: true,
    ));
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MagnusApp(),
    ));
    await _bekle(t, adim: 25);

    Map<String, dynamic> kayit() {
      final j = jsonDecode(prefs.getString(MagnusHafiza.anahtar)!) as Map<String, dynamic>;
      return (j['fal'] as Map<String, dynamic>)['evim'] as Map<String, dynamic>;
    }

    final router = GoRouter.of(t.element(find.byType(MainTabsScreen)));

    router.push('/evim');
    await _bekle(t);
    expect(kayit()['a'], 1);
    router.pop();
    await _bekle(t);
    expect(kayit()['bv'], 1, reason: 'geri ile hemen çıktı');

    router.push('/evim');
    await _bekle(t);
    router.go('/home');
    await _bekle(t);
    expect(kayit()['a'], 2);
    expect(kayit()['bv'], 2, reason: 'go ile çıkış da sayılır');

    // pageBuilder ile tanımlı rotalar da izlenir.
    for (final (yol, tur) in const [
      ('/astroloji', 'astroloji'),
      ('/biyoritim', 'biyoritim'),
      ('/dogumharitasi', 'dogumharitasi'),
      ('/kaderkitabi', 'kaderkitabi'),
      ('/numeroloji', 'numeroloji'),
      ('/astrotakvim', 'astrotakvim'),
      ('/durugoru', 'durugoru'),
    ]) {
      router.push(yol);
      await _bekle(t, adim: 4);
      final j = jsonDecode(prefs.getString(MagnusHafiza.anahtar)!) as Map<String, dynamic>;
      expect((j['fal'] as Map<String, dynamic>).containsKey(tur), isTrue, reason: yol);
      router.go('/home');
      await _bekle(t, adim: 4);
    }

    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 20));
  });
}
