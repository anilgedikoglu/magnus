// Süresi dolan reklam gösterilmez: AdMob yüklenen reklamı 1 saat sonra geçersiz sayar.
// Kilitli karttaki işaret yalnız teklif yapılabiliyorsa çıkar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/core/services/ad_service.dart';
import 'package:magnus_app/data/models/inbox_item.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/inbox/widgets/inbox_item_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('55 dakikada süresi dolmuş sayılır', () {
    final t = DateTime(2026, 11, 9, 12);
    expect(AdService.suresiDoldu(t, t.add(const Duration(minutes: 54, seconds: 59))), isFalse);
    expect(AdService.suresiDoldu(t, t.add(const Duration(minutes: 55))), isTrue);
  });

  group('Kilitli kart işareti', () {
    late AdService eski;
    setUp(() => eski = AdService.instance);
    tearDown(() => AdService.instance = eski);

    Future<void> kur(WidgetTester t, {required bool dokunusVar}) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({'language_picked': true});
      final prefs = await SharedPreferences.getInstance();
      final simdi = DateTime.now();
      final item = InboxItem(
        id: 'x',
        title: 'Kahve',
        text: 'metin',
        date: simdi.subtract(const Duration(minutes: 1)).toIso8601String(),
        fortuneTypeKey: 'coffee',
        unlockAt: simdi.add(const Duration(minutes: 3)).toIso8601String(),
      );
      await t.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: InboxItemCard(
              item: item,
              onTap: () {},
              onDismissed: () {},
              onLockedTap: dokunusVar ? () {} : null,
            ),
          ),
        ),
      ));
      await t.pump();
    }

    Future<void> kapat(WidgetTester t) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
    }

    testWidgets('reklam hazır değilse işaret yok', (t) async {
      AdService.instance = AdService.forTest();
      await kur(t, dokunusVar: true);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      await kapat(t);
    });

    testWidgets('teklif yapılabiliyorsa işaret çıkar', (t) async {
      AdService.instance = AdService.forTest()..setAdsDisabled(true);
      await kur(t, dokunusVar: true);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      await kapat(t);
    });

    testWidgets('kilitli karta dokunuş bağlı değilse işaret yok', (t) async {
      AdService.instance = AdService.forTest()..setAdsDisabled(true);
      await kur(t, dokunusVar: false);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      await kapat(t);
    });
  });
}
