// Fal detayı tarot başlığı ayrıştırma: TR ve EN başlıklardan doğru kart görselleri
// (İngilizce kullanıcıda kart görselleri hiç çıkmıyordu — 2026-11 inceleme bulgusu).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/filmed_image.dart';
import 'package:magnus_app/data/models/inbox_item.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/data/services/fortune_service.dart';
import 'package:magnus_app/presentation/inbox/inbox_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> _cardAssets(WidgetTester t, InboxItem item, {String lang = 'tr'}) async {
  SharedPreferences.setMockInitialValues({'app_locale': lang, 'locale': lang});
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: InboxDetailScreen(item: item)),
  ));
  await t.pump();
  return t
      .widgetList<FilmedImage>(find.byType(FilmedImage))
      .map((f) => f.asset)
      .toList();
}

InboxItem _tarot(String title) => InboxItem(
      id: 't',
      title: title,
      text: 'Metin.',
      date: '2026-11-05T00:23:00',
      fortuneTypeKey: 'tarot',
    );

void main() {
  test('İngilizce kart adı → Türkçe görsel anahtarı', () {
    expect(FortuneService.trCardNameForEn('The Moon'), 'Ay');
    expect(FortuneService.trCardNameForEn('Death'), 'Ölüm');
    expect(FortuneService.trCardNameForEn('The Star'), 'Yıldız');
    expect(FortuneService.trCardNameForEn('The Lovers'), 'Aşıklar');
    expect(FortuneService.trCardNameForEn('Böyle Kart Yok'), isNull);
  });

  testWidgets('TR klasik tarot başlığı → 3 kart görseli', (t) async {
    final assets = await _cardAssets(t, _tarot('Tarot Falın: Ay, Ters Ölüm, Yıldız'));
    expect(assets, [
      'assets/images/tarot/ay.jpg',
      'assets/images/tarot/olum.jpg',
      'assets/images/tarot/yildiz.jpg',
    ]);
  });

  testWidgets('EN klasik tarot başlığı → aynı 3 kart görseli', (t) async {
    final assets = await _cardAssets(
        t, _tarot('Your Tarot Reading: The Moon, Reversed Death, The Star'),
        lang: 'en');
    expect(assets, [
      'assets/images/tarot/ay.jpg',
      'assets/images/tarot/olum.jpg',
      'assets/images/tarot/yildiz.jpg',
    ]);
    expect(find.text('Reversed Death'), findsOneWidget);
  });

  testWidgets('EN tek kart (Love Card) → tek kart görseli, klasik sanılmaz', (t) async {
    final assets = await _cardAssets(t, _tarot('Love Card Reading: Ay'), lang: 'en');
    expect(assets, ['assets/images/tarot3/aya.jpg']);
  });
}
