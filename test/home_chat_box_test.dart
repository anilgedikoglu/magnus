// Ana menü sohbet kutusu: alt barla aynı boy, mesaj kuyruğu, uzun mesajın sayfalanması.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/glass_tab_bar.dart' show kGlassBarHeight;
import 'package:magnus_app/presentation/home/home_chat_box.dart';

const _text = ValueKey('homeChatText');

String _shown(WidgetTester t) => t.widget<Text>(find.byKey(_text)).data!;

void main() {
  group('paginateChatText', () {
    bool fits40(String s) => s.length <= 40;

    test('sığan metin tek sayfa', () {
      expect(paginateChatText('Hoş geldin.', fits40), ['Hoş geldin.']);
    });

    test('sığmayan metin cümle sınırından bölünür, hiçbir kelime kaybolmaz', () {
      const m = 'Bugün yıldızlar seninle konuşuyor. Akşama doğru güzel bir haber alacaksın!';
      final p = paginateChatText(m, fits40);
      expect(p, ['Bugün yıldızlar seninle konuşuyor.', 'Akşama doğru güzel bir haber alacaksın!']);
      expect(p.join(' '), m);
    });

    test('tek cümle sığmıyorsa kelimeden bölünür, sayfalar sınırı aşmaz', () {
      const m = 'bir iki üç dört beş altı yedi sekiz dokuz on on bir on iki on üç on dört on beş';
      final p = paginateChatText(m, fits40);
      expect(p.length, greaterThan(1));
      expect(p.every(fits40), isTrue);
      expect(p.join(' '), m);
    });
  });

  Future<HomeChatBoxState> pump(WidgetTester t) async {
    final key = GlobalKey<HomeChatBoxState>();
    await t.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 366,
          height: kGlassBarHeight,
          child: HomeChatBox(key: key, tint: 0.55),
        ),
      ),
    ));
    return key.currentState!;
  }

  Future<void> dispose(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  }

  testWidgets('kutu alt bar ölçüsünde; mesaj gelene dek yazı yok', (t) async {
    await pump(t);
    expect(t.getSize(find.byKey(const ValueKey('homeChatBox'))).height, kGlassBarHeight);
    expect(find.byKey(_text), findsNothing);
    await dispose(t);
  });

  testWidgets('mesaj yeterince kalmadan yenisi araya girmez, sonra tek karede değişir', (t) async {
    final box = await pump(t);
    box.say('İlk mesaj.');
    await t.pump();
    expect(_shown(t), 'İlk mesaj.');

    box.say('İkinci mesaj.');
    await t.pump(const Duration(seconds: 2));
    expect(_shown(t), 'İlk mesaj.', reason: 'okuma süresi dolmadı');

    await t.pump(const Duration(milliseconds: 1600));
    expect(_shown(t), 'İkinci mesaj.');
    await dispose(t);
  });

  const longMsg = 'Bugün yıldızlar seninle konuşuyor, sabırlı ol. '
      'Akşama doğru beklediğin bir haber geleceğini hissediyorum.';

  testWidgets('uzun mesaj dönerken dokunuş cevabı anında gelir', (t) async {
    final box = await pump(t);
    box.say(longMsg);
    await t.pump();
    expect(longMsg.startsWith(_shown(t)), isTrue);
    expect(_shown(t).length, lessThan(longMsg.length), reason: 'sayfalanmalı');
    await t.pump(const Duration(seconds: 1));
    box.say('Bugünkü hakkın doldu.', now: true);
    await t.pump();
    expect(_shown(t), 'Bugünkü hakkın doldu.');
    await dispose(t);
  });

  testWidgets('aynı dokunuş cevabı tekrar edilince sıraya yığılmaz', (t) async {
    final box = await pump(t);
    for (var i = 0; i < 5; i++) {
      box.say('Hakkın doldu.', now: true);
      await t.pump(const Duration(milliseconds: 200));
    }
    box.say('Yeni haber.');
    await t.pump(const Duration(milliseconds: 3600));
    expect(_shown(t), 'Yeni haber.');
    await dispose(t);
  });

  testWidgets('tamamı okunmuş uzun mesaj sıradakini bekletmez', (t) async {
    final box = await pump(t);
    box.say(longMsg);
    await t.pump();
    final first = _shown(t);
    var other = false;
    for (var i = 0; i < 20 && !other; i++) {
      await t.pump(const Duration(milliseconds: 500));
      if (_shown(t) != first) other = true;
    }
    expect(other, isTrue);
    box.say('Sıradaki.');
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(seconds: 8));
    expect(_shown(t), 'Sıradaki.');
    await dispose(t);
  });

  testWidgets('clear yazıyı ve sırayı boşaltır', (t) async {
    final box = await pump(t);
    box.say('Türkçe yazı.');
    box.say('Sıradaki yazı.');
    await t.pump();
    box.clear();
    await t.pump(const Duration(seconds: 10));
    expect(find.byKey(_text), findsNothing);
    await dispose(t);
  });

  Size kutu(WidgetTester t) => t.getSize(find.byKey(const ValueKey('homeChatBox')));

  Future<void> oturt(WidgetTester t) async {
    for (var i = 0; i < 90; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('6 sn sonra sola toplanıp yuvarlak kalır', (t) async {
    final box = await pump(t);
    box.say('Bekleyen mesaj.');
    await t.pump();
    await oturt(t);
    expect(kutu(t).width, closeTo(366, 1));
    await t.pump(const Duration(milliseconds: 4400));
    await t.pump();
    expect(_shown(t), 'Bekleyen mesaj.', reason: '6 sn dolmadı');
    expect(kutu(t).width, closeTo(366, 1));
    await t.pump(const Duration(milliseconds: 200));
    await oturt(t);
    expect(kutu(t).width, closeTo(kGlassBarHeight, 1), reason: 'yuvarlak');
    expect(t.getTopLeft(find.byKey(const ValueKey('homeChatBox'))).dx, (800 - 366) / 2, reason: 'sola toplanır');
    expect(find.byKey(_text), findsNothing);
    await dispose(t);
  });

  testWidgets('yuvarlakken yeni yazı gelince sağa açılır, 6 sn sonra yine toplanır', (t) async {
    final box = await pump(t);
    box.say('Birinci.');
    await t.pump();
    await t.pump(const Duration(seconds: 6));
    await oturt(t);
    expect(kutu(t).width, closeTo(kGlassBarHeight, 1));

    box.say('İkinci.');
    await t.pump();
    await oturt(t);
    expect(kutu(t).width, closeTo(366, 1));
    expect(_shown(t), 'İkinci.');
    await dispose(t);
  });

  testWidgets('yuvarlağa dokununca son yazıyla açılır', (t) async {
    final box = await pump(t);
    box.say('Son söz.');
    await t.pump();
    await t.pump(const Duration(seconds: 6));
    await oturt(t);
    await t.tap(find.byKey(const ValueKey('homeChatBox')));
    await t.pump();
    await oturt(t);
    expect(kutu(t).width, closeTo(366, 1));
    expect(_shown(t), 'Son söz.');
    await dispose(t);
  });

  testWidgets('açıkken yeni yazı parlayıp sönerek gelir', (t) async {
    final box = await pump(t);
    box.say('Eski.');
    await t.pump();
    await oturt(t);
    box.say('Yeni.', now: true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 130));
    expect(_shown(t), 'Yeni.');
    expect(t.widget<Text>(find.byKey(_text)).style!.shadows, isNotEmpty, reason: 'parlıyor');
    await t.pump(const Duration(milliseconds: 800));
    expect(t.widget<Text>(find.byKey(_text)).style!.shadows ?? const [], isEmpty, reason: 'söndü');
    await dispose(t);
  });

  testWidgets('kısa mesaj süresi dolunca da 6 sn yerinde bekler', (t) async {
    final box = await pump(t);
    box.say('Bekleyen mesaj.');
    await t.pump();
    await t.pump(const Duration(seconds: 5));
    expect(_shown(t), 'Bekleyen mesaj.');
    await dispose(t);
  });

  testWidgets('kutuya dokunuş altındaki öğeye geçmez', (t) async {
    var tapped = 0;
    final key = GlobalKey<HomeChatBoxState>();
    await t.pumpWidget(MaterialApp(
      home: Stack(children: [
        Positioned.fill(child: GestureDetector(onTap: () => tapped++)),
        Positioned(
          top: 100,
          left: 12,
          right: 12,
          height: kGlassBarHeight,
          child: HomeChatBox(key: key, tint: 0.55),
        ),
      ]),
    ));
    await t.tap(find.byKey(const ValueKey('homeChatBox')), warnIfMissed: false);
    await t.pump();
    expect(tapped, 0);
    await dispose(t);
  });
}
