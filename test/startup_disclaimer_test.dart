// Açılış yasal bilgilendirmesi: 6 sn görünür (Oyuncu Dükkânı ile aynı), dokunuşu engeller,
// sonra söner ve ağaçtan çıkar. TR / EN metin dile göre.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/l10n/legal_texts.dart';
import 'package:magnus_app/core/widgets/startup_disclaimer.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester t, String lang, VoidCallback onTap) async {
  SharedPreferences.setMockInitialValues({'app_locale': lang, 'locale': lang});
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      builder: (context, child) => StartupDisclaimer(child: child!),
      home: Scaffold(body: Center(child: ElevatedButton(onPressed: onTap, child: const Text('UYGULAMA')))),
    ),
  ));
}

bool _shows(String s) => find.textContaining(s, findRichText: true).evaluate().isNotEmpty;

void main() {
  setUp(() => StartupDisclaimer.debugSkip = false);

  testWidgets('6 sn görünür ve dokunuşu engeller, sonra kaybolur', (t) async {
    var taps = 0;
    await _pump(t, 'tr', () => taps++);
    expect(StartupDisclaimer.showFor, const Duration(seconds: 6));
    expect(_shows('YASAL BİLGİLENDİRME'), isTrue);
    expect(_shows('eğlence amaçlı'), isTrue);

    await t.tap(find.text('UYGULAMA'), warnIfMissed: false);
    expect(taps, 0); // perde açıkken alttaki uygulama dokunuş almaz

    await t.pump(const Duration(milliseconds: 5900));
    expect(_shows('YASAL BİLGİLENDİRME'), isTrue); // 6 sn dolmadan kalkmaz

    await t.pump(const Duration(milliseconds: 200)); // 6 sn doldu → sönmeye başlar
    await t.pump(const Duration(milliseconds: 500)); // 400 ms sönme bitti
    await t.pump();
    expect(_shows('YASAL BİLGİLENDİRME'), isFalse);

    await t.tap(find.text('UYGULAMA'));
    expect(taps, 1);
  });

  testWidgets('İngilizce dilde İngilizce metin', (t) async {
    await _pump(t, 'en', () {});
    expect(_shows(kLegalNoticeEn.first.$1), isTrue);
    expect(_shows(kLegalNoticeTr.first.$1), isFalse);
    await t.pump(const Duration(seconds: 7));
  });

  test('TR ve EN metin paralel (aynı bölüm sayısı, boş paragraf yok)', () {
    expect(kLegalNoticeEn.length, kLegalNoticeTr.length);
    for (var i = 1; i < kLegalNoticeTr.length; i++) {
      expect(kLegalNoticeTr[i].$2, isNotEmpty);
      expect(kLegalNoticeEn[i].$2, isNotEmpty);
    }
  });
}
