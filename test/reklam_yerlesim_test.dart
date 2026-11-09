// Reklam yerleşimi: kehanet günlük hakkı, Aşk Uyumu tutarlılığı, "bir tane daha" düğmesinin koşulları.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/core/services/ad_service.dart';
import 'package:magnus_app/core/services/kehanet_hak.dart';
import 'package:magnus_app/core/widgets/bir_tane_daha.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/askuyumu/askuyumu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Kehanet hakkı', () {
    final t = DateTime(2026, 11, 9, 12);

    Future<KehanetHak> yeni() async {
      SharedPreferences.setMockInitialValues({});
      return KehanetHak(await SharedPreferences.getInstance());
    }

    test('günde 3 giriş, sonra biter', () async {
      final h = await yeni();
      for (var i = 0; i < 3; i++) {
        expect(h.girebilir(t), isTrue);
        await h.kullan(t);
      }
      expect(h.girebilir(t), isFalse);
    });

    test('ödül 3 giriş ekler', () async {
      final h = await yeni();
      for (var i = 0; i < 3; i++) {
        await h.kullan(t);
      }
      await h.odulEkle(t);
      expect(h.kalan(t), 3);
    });

    test('ertesi gün yenilenir, sıfırın altına inmez', () async {
      final h = await yeni();
      for (var i = 0; i < 5; i++) {
        await h.kullan(t);
      }
      expect(h.kalan(t), 0);
      expect(h.kalan(DateTime(2026, 11, 10, 8)), 3);
    });
  });

  group('Aşk Uyumu tohumu', () {
    final g = DateTime(2026, 11, 9, 10);

    test('aynı gün aynı burç aynı sonuç', () {
      expect(askUyumuTohumu('Koç', 'Aslan', g), askUyumuTohumu('Koç', 'Aslan', DateTime(2026, 11, 9, 23)));
    });

    test('başka burç ve başka gün farklı', () {
      expect(askUyumuTohumu('Koç', 'Aslan', g), isNot(askUyumuTohumu('Koç', 'Yay', g)));
      expect(askUyumuTohumu('Koç', 'Aslan', g), isNot(askUyumuTohumu('Koç', 'Aslan', DateTime(2026, 11, 10))));
    });
  });

  group('Bir tane daha düğmesi', () {
    late AdService eski;
    setUp(() => eski = AdService.instance);
    tearDown(() => AdService.instance = eski);
    final bugun = DateTime.now().toIso8601String().substring(0, 10);

    Future<void> kur(WidgetTester t, Map<String, Object> seed) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({'language_picked': true, ...seed});
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: Scaffold(body: BirTaneDaha(falTuru: 'kahve', hakAnahtari: 'kahve_bugun_tarih')),
        ),
      ));
      await t.pump();
      await t.pump();
    }

    testWidgets('bugünkü hak kullanılmışsa ve teklif varsa görünür', (t) async {
      AdService.instance = AdService.forTest()..setAdsDisabled(true);
      await kur(t, {'kahve_bugun_tarih': bugun});
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('hak kullanılmadıysa görünmez', (t) async {
      AdService.instance = AdService.forTest()..setAdsDisabled(true);
      await kur(t, {'kahve_bugun_tarih': '2020-01-01'});
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('reklam hazır değilse görünmez', (t) async {
      AdService.instance = AdService.forTest();
      await kur(t, {'kahve_bugun_tarih': bugun});
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });
  });
}
