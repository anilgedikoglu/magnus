// Kahve falı: fincan görünmeyince uyarı popup değil, yuvaların altında; ilk görsel değişince silinir.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/data/services/photo_subject_detector.dart';
import 'package:magnus_app/presentation/coffee/coffee_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _picker = MethodChannel('plugins.flutter.io/image_picker');
const _warning = ValueKey('coffeeNotCupWarning');

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    PhotoSubjectDetector.debugSonuc = (_, __) async => false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_picker, (_) async => 'assets/images/magnusicon.png');
  });
  tearDown(() {
    PhotoSubjectDetector.debugSonuc = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_picker, null);
  });

  testWidgets('uyarı yuvaların altında çıkar, popup açılmaz, ilk görsel değişince silinir', (t) async {
    SharedPreferences.setMockInitialValues({'language_picked': true});
    final prefs = await SharedPreferences.getInstance();
    t.view.devicePixelRatio = 3;
    t.view.physicalSize = const Size(402 * 3, 874 * 3);
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: CoffeeScreen()),
    ));
    await _settle(t);

    await t.tap(find.text('Genel'));
    await _settle(t);
    await t.tap(find.text('Dosyadan'));
    await _settle(t);
    for (final n in ['1', '2', '3']) {
      await t.tap(find.text(n));
      await _settle(t);
    }

    await t.tap(find.text('Falımı Gönder'));
    await _settle(t);
    expect(find.byKey(_warning), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    expect(t.getTopLeft(find.byKey(_warning)).dy,
        greaterThan(t.getBottomLeft(find.text('1')).dy), reason: 'yuvaların altında');

    await t.tap(find.text('2'));
    await _settle(t);
    expect(find.byKey(_warning), findsOneWidget, reason: 'yalnız ilk görsel siler');

    await t.tap(find.text('1'));
    await _settle(t);
    expect(find.byKey(_warning), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
