// Aşk Uyumu çarkı: yalnız çark üzerinde başlayan kaydırma çevirir; merkezden çıkan doğruya dik
// saat yönündeki kaydırma, çarkın neresinde olursa olsun saat yönünde döndürür.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/core/widgets/edge_swipe_back.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/askuyumu/askuyumu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _m = Offset(180, 180);

void main() {
  setUp(rootBundle.clear);

  group('Açı hesabı', () {
    // Çarkın saat kadranındaki dört noktası ve oradaki saat yönlü teğet hareket.
    const noktalar = <String, (Offset, Offset)>{
      'üst, sağa': (Offset(180, 40), Offset(8, 0)),
      'sağ, aşağı': (Offset(320, 180), Offset(0, 8)),
      'alt, sola': (Offset(180, 320), Offset(-8, 0)),
      'sol, yukarı': (Offset(40, 180), Offset(0, -8)),
      'sağ üst çapraz': (Offset(280, 80), Offset(6, 6)),
      'sol alt çapraz': (Offset(80, 280), Offset(-6, -6)),
    };

    noktalar.forEach((ad, v) {
      test('saat yönü: $ad', () {
        final (p, d) = v;
        expect(carkAciFarki(p, p + d, _m), greaterThan(0));
        expect(carkAcisalHiz(p, d * 100, _m), greaterThan(0));
      });
      test('saat tersi: $ad', () {
        final (p, d) = v;
        expect(carkAciFarki(p, p - d, _m), lessThan(0));
        expect(carkAcisalHiz(p, -d * 100, _m), lessThan(0));
      });
    });

    test('tam tur toplamı 2π', () {
      var toplam = 0.0;
      var once = _m + const Offset(140, 0);
      for (var i = 1; i <= 72; i++) {
        final a = i * 2 * pi / 72;
        final simdi = _m + Offset(140 * cos(a), 140 * sin(a));
        toplam += carkAciFarki(once, simdi, _m);
        once = simdi;
      }
      expect(toplam, closeTo(2 * pi, 1e-9));
    });

    test('merkezden uzaklaşan hareket döndürmez', () {
      expect(carkAciFarki(const Offset(180, 100), const Offset(180, 60), _m), closeTo(0, 1e-9));
    });

    test('daire dışı ve göbek çevirme başlatmaz', () {
      expect(carkUzerindeMi(const Offset(180, 40), _m, 180), isTrue);
      expect(carkUzerindeMi(const Offset(5, 5), _m, 180), isFalse, reason: 'kare köşesi');
      expect(carkUzerindeMi(_m + const Offset(4, 4), _m, 180), isFalse, reason: 'göbek');
    });
  });

  group('Ekran', () {
    Future<void> kur(WidgetTester t, {Size boyut = const Size(390, 844)}) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = boyut;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({'language_picked': true});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const AskUyumuScreen())]);
      await t.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(routerConfig: router),
      ));
      await t.pump();
    }

    Future<void> kapat(WidgetTester t) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
    }

    String burc(WidgetTester t) => t
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .firstWhere((s) => const ['Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak', 'Terazi', 'Akrep',
            'Yay', 'Oğlak', 'Kova', 'Balık'].contains(s));

    Rect cark(WidgetTester t) => t.getRect(find.byKey(const ValueKey('ask_uyumu_cark')));

    testWidgets('çark 320\'den büyük, kenarlarda 12 pt pay, taşma yok', (t) async {
      await kur(t);
      final r = cark(t);
      expect(r.width, greaterThan(320));
      expect(r.left, greaterThanOrEqualTo(12));
      expect(390 - r.right, greaterThanOrEqualTo(12));
      expect(t.takeException(), isNull);
      await kapat(t);
    });

    testWidgets('küçük telefonda da taşmaz', (t) async {
      await kur(t, boyut: const Size(320, 568));
      expect(cark(t).width, greaterThanOrEqualTo(120));
      expect(t.takeException(), isNull);
      await kapat(t);
    });

    testWidgets('çarkta sağa sürükleme ekranı kapatmaz (genel kaydırma = geri kapalı)', (t) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(390, 844);
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({'language_picked': true});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('kok'))),
        GoRoute(path: '/ask', builder: (_, __) => const AskUyumuScreen()),
      ]);
      await t.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => EdgeSwipeBack(router: router, child: child!),
        ),
      ));
      router.push('/ask');
      await t.pumpAndSettle();
      final r = cark(t);
      await t.dragFrom(r.center + Offset(-r.width * 0.3, r.height * 0.3), const Offset(150, 0));
      await t.pump(const Duration(seconds: 3));
      expect(find.byType(AskUyumuScreen), findsOneWidget);
      await kapat(t);
    });

    testWidgets('çark dışında kaydırma çarkı çevirmez', (t) async {
      await kur(t);
      final once = burc(t);
      final r = cark(t);
      await t.dragFrom(Offset(r.center.dx - 150, r.bottom + 100), const Offset(300, 0));
      await t.pump(const Duration(seconds: 2));
      expect(burc(t), once);
      await kapat(t);
    });

    testWidgets('çark karesinin köşesinden başlayan kaydırma çevirmez', (t) async {
      await kur(t);
      final once = burc(t);
      final r = cark(t);
      await t.dragFrom(r.topLeft + const Offset(4, 4), const Offset(160, 0));
      await t.pump(const Duration(seconds: 2));
      expect(burc(t), once);
      await kapat(t);
    });

    testWidgets('çarkın üzerinde teğet kaydırma çevirir', (t) async {
      await kur(t);
      final once = burc(t);
      final r = cark(t);
      await t.dragFrom(r.center + Offset(0, -r.height * 0.4), Offset(r.width * 0.5, r.height * 0.1));
      await t.pump(const Duration(seconds: 3));
      expect(burc(t), isNot(once));
      await kapat(t);
    });
  });
}
