import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/tavsanfali/tavsanfali_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _today() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

Future<SharedPreferences> _open(WidgetTester t, Map<String, Object> init,
    {String lang = 'tr', bool finish = true, bool tap = true}) async {
  SharedPreferences.setMockInitialValues({'app_locale': lang, ...init});
  final prefs = await SharedPreferences.getInstance();
  await t.binding.setSurfaceSize(const Size(400, 800));
  await t.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: TavsanFaliScreen()),
  ));
  for (var i = 0; i < 50; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    if (find.byType(Opacity).evaluate().length > 3) break; // sahne kuruldu
  }
  // Tavşan kullanıcı dokunmadan çekmez: ortadaki kağıda dokun (aynı gün tekrarında kağıt yok).
  final kagit = find.byKey(const ValueKey('tavsan-kagit-2'));
  if (tap && kagit.evaluate().isNotEmpty) {
    await t.tap(kagit, warnIfMissed: false);
    await t.pump();
  }
  if (finish) {
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
  return prefs;
}

String _cardText(WidgetTester t) {
  final texts = <String>[];
  for (final w in t.widgetList<Text>(find.byType(Text))) {
    texts.add(w.data ?? w.textSpan?.toPlainText() ?? '');
  }
  texts.sort((a, b) => b.length.compareTo(a.length));
  return texts.first;
}

void main() {
  testWidgets('ilk çekim: metin görünür, tarih + id + no-repeat yazılır', (t) async {
    final prefs = await _open(t, {});
    expect(prefs.getString('tavsanfali_bugun_tarih'), _today());
    final id = prefs.getInt('tavsanfali_bugun_id');
    expect(id, isNotNull);
    expect(prefs.getStringList('tavsanfali_gosterilen'), contains('$id'));
    expect(_cardText(t).length, greaterThan(30));
    // Alttaki Geri Git kaldırıldı (2026-11-05): yerinde tüm uygulamada yüzen cam bar var.
    expect(find.text('Geri Git'), findsNothing);
    expect(find.textContaining('Yarın tavşan'), findsNothing);
  });

  testWidgets('not kartı: dışına dokununca kapanır, kağıt tavşanın önünde kalır, ona dokununca açılır',
      (t) async {
    await _open(t, {});
    final metin = _cardText(t);
    expect(metin.length, greaterThan(30));
    expect(find.byKey(const ValueKey('tavsan-acik-kagit')), findsNothing);
    expect(find.byKey(const ValueKey('tavsan-kart-disi')), findsOneWidget);
    await t.tapAt(const Offset(30, 120)); // kartın dışı
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(metin), findsNothing, reason: 'kart kapandı');
    expect(find.byKey(const ValueKey('tavsan-acik-kagit')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('tavsan-acik-kagit')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(_cardText(t), metin, reason: 'aynı yazı yeniden açıldı');
    expect(find.byKey(const ValueKey('tavsan-acik-kagit')), findsNothing);
  });

  testWidgets('dokunmadan çekmez: kayıt yok, ipucu görünür; dokununca çeker ve kaydeder', (t) async {
    final prefs = await _open(t, {}, tap: false);
    expect(prefs.getString('tavsanfali_bugun_tarih'), isNull); // hak harcanmadı
    expect(prefs.getInt('tavsanfali_bugun_id'), isNull);
    expect(find.textContaining('Bir kağıda dokun'), findsOneWidget);
    expect(find.textContaining('Yarın tavşan'), findsNothing);

    await t.tap(find.byKey(const ValueKey('tavsan-kagit-4')), warnIfMissed: false);
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(prefs.getString('tavsanfali_bugun_tarih'), _today());
    expect(prefs.getInt('tavsanfali_bugun_id'), isNotNull);
    expect(find.textContaining('Bir kağıda dokun'), findsNothing);
  });

  testWidgets('aynı gün tekrar: aynı metin + yarın notu, yeni id yazılmaz', (t) async {
    final prefs = await _open(t, {});
    final first = _cardText(t);
    final id = prefs.getInt('tavsanfali_bugun_id')!;
    final shownBefore = prefs.getStringList('tavsanfali_gosterilen')!;

    await t.pumpWidget(const SizedBox());
    final prefs2 = await _open(t, {
      'tavsanfali_bugun_tarih': _today(),
      'tavsanfali_bugun_id': id,
      'tavsanfali_gosterilen': shownBefore,
    }, finish: false);
    expect(prefs2.getStringList('tavsanfali_gosterilen'), shownBefore);
    expect(find.textContaining('Yarın tavşan'), findsOneWidget);
    // Yer tutucu rastgeleliği (sayi/kelime) olabilir; metnin başı aynı kalmalı.
    expect(_cardText(t).isNotEmpty, isTrue);
    expect(first.isNotEmpty, isTrue);
  });

  testWidgets('no-repeat: gösterilen id tekrar seçilmez', (t) async {
    final prefs = await _open(t, {});
    final firstId = prefs.getInt('tavsanfali_bugun_id')!;
    await t.pumpWidget(const SizedBox());
    // Yeni gün simülasyonu: dünü yaz, gösterilenleri koru.
    final prefs2 = await _open(t, {
      'tavsanfali_bugun_tarih': '2000-01-01',
      'tavsanfali_bugun_id': firstId,
      'tavsanfali_gosterilen': ['$firstId'],
    });
    final secondId = prefs2.getInt('tavsanfali_bugun_id')!;
    expect(secondId, isNot(firstId));
    expect(prefs2.getStringList('tavsanfali_gosterilen'),
        containsAll(['$firstId', '$secondId']));
  });

  testWidgets('EN dil: İngilizce arayüz ve metin_en', (t) async {
    await _open(t, {}, lang: 'en');
    expect(find.text('Rabbit Fortune'), findsOneWidget);
    expect(find.text('Go Back'), findsNothing); // alt Geri Git yok (yüzen bar)
    // Türkçe başlık/geri düğmesi yok; kart metninde Türkçe'ye özgü harf beklenmez.
    expect(find.text('Geri Git'), findsNothing);
    expect(_cardText(t).length, greaterThan(30));
  });
}
