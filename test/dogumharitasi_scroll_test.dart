// Doğum Haritası: yazı kaydırılınca çerçeve yerinde kalır, yalnız içindeki yazı kayar.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/data/services/storage_service.dart';
import 'package:magnus_app/presentation/dogumharitasi/dogumharitasi_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(rootBundle.clear);

  testWidgets('çerçeve sabit, yazı içinde kayar', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(375, 667);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({'language_picked': true});
    final prefs = await SharedPreferences.getInstance();
    await StorageService(prefs).saveProfile(UserProfile(
      name: 'Deniz', age: 34, gender: 'kadin', job: 'ozelsektoru', maritalStatus: 'bekar',
      birthDate: '1991-04-12', birthCity: 'İzmir', zodiacSign: 'Koç', birthTime: '08:40',
      risingSign: 'Yengeç', moonSign: 'Akrep', planet: 'Mars', onboardingComplete: true,
    ));
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: DogumHaritasiScreen()),
    ));
    final frame = find.byKey(const ValueKey('dogumMetinCerceve'));
    for (var i = 0; i < 400 && frame.evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(frame, findsOneWidget);

    final scroll = find.descendant(of: frame, matching: find.byType(SingleChildScrollView));
    expect(scroll, findsOneWidget, reason: 'kaydırma çerçevenin İÇİNDE');
    final position = t.widget<SingleChildScrollView>(scroll);
    expect(position.scrollDirection, Axis.vertical);

    final before = t.getRect(frame);
    await t.drag(frame, const Offset(0, -120));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.getRect(frame), before);
    final state = t.state<ScrollableState>(
      find.descendant(of: scroll, matching: find.byType(Scrollable)),
    );
    expect(state.position.pixels, greaterThan(0), reason: 'yazı kaydı');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });
}
