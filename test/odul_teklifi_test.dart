// Ödüllü teklif penceresi: iki eşit düğme, Vazgeç → false (reklam hiç başlamaz), İzle → yalnız
// servis ödülü verirse true; admin modunda pencere yok; AdService SDK olmadan ödül vermez.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/core/services/ad_pacing.dart';
import 'package:magnus_app/core/services/ad_service.dart';
import 'package:magnus_app/core/widgets/odul_teklifi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SahteServis extends AdService {
  _SahteServis({this.odul = false, this.admin = false}) : super.forTest();
  final bool odul;
  final bool admin;
  int izletilen = 0;

  @override
  bool get adsDisabled => admin;

  @override
  Future<bool> showRewardedFor(OdulTuru tur, {String? falTuru}) async {
    izletilen++;
    return odul;
  }
}

class _Sonuc {
  bool? deger;
}

Future<void> _kur(WidgetTester t, AdService servis, _Sonuc sonuc, {bool reduce = false}) async {
  await t.pumpWidget(MaterialApp(
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
      child: child!,
    ),
    home: Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              sonuc.deger = await odulTeklifiGoster(
                c,
                tur: OdulTuru.kutuAc,
                baslik: 'Kutuları aç',
                aciklama: 'Kısa bir reklam izlersen bu kişinin tüm kutuları açılır.',
                izleEtiketi: 'Reklam izle',
                vazgecEtiketi: 'Vazgeç',
                servis: servis,
              );
            },
            child: const Text('ac'),
          ),
        ),
      ),
    ),
  ));
  await t.tap(find.text('ac'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('iki eşit düğme; Vazgeç false döner ve reklam başlamaz', (t) async {
    final s = _SahteServis(odul: true);
    final r = _Sonuc();
    await _kur(t, s, r);
    expect(find.text('Kutuları aç'), findsOneWidget);
    expect(find.textContaining('tüm kutuları açılır'), findsOneWidget);
    expect(find.text('Reklam izle'), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);
    final izle = t.getRect(find.ancestor(of: find.text('Reklam izle'), matching: find.byType(Expanded)).first);
    final vazgec = t.getRect(find.ancestor(of: find.text('Vazgeç'), matching: find.byType(Expanded)).first);
    expect((izle.width - vazgec.width).abs() < 0.5, isTrue, reason: 'düğmeler eşit genişlikte');
    expect(izle.height, vazgec.height);
    await t.tap(find.text('Vazgeç'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(s.izletilen, 0, reason: 'vazgeçince reklam başlamaz');
    expect(r.deger, isFalse);
    expect(find.text('Kutuları aç'), findsNothing);
  });

  for (final odul in [false, true]) {
    testWidgets('Reklam izle: servis ödül ${odul ? 'verirse true' : 'vermezse false'}', (t) async {
      final s = _SahteServis(odul: odul);
      final r = _Sonuc();
      await _kur(t, s, r);
      await t.tap(find.text('Reklam izle'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(s.izletilen, 1);
      expect(r.deger, odul, reason: 'true yalnız ödül kazanıldıysa');
    });
  }

  testWidgets('admin modunda pencere yok, ödül doğrudan', (t) async {
    final s = _SahteServis(admin: true);
    final r = _Sonuc();
    await _kur(t, s, r);
    expect(find.text('Vazgeç'), findsNothing);
    expect(r.deger, isTrue);
    expect(s.izletilen, 0);
  });

  testWidgets('azaltılmış harekette sayfa animasyonsuz açılır', (t) async {
    final r = _Sonuc();
    await t.pumpWidget(MaterialApp(
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () async {
            r.deger = await odulTeklifiGoster(c,
                tur: OdulTuru.hemenAc,
                baslik: 'b',
                aciklama: 'a',
                izleEtiketi: 'Reklam izle',
                vazgecEtiketi: 'Vazgeç',
                servis: _SahteServis());
          },
          child: const Text('ac'),
        ),
      ),
    ));
    await t.tap(find.text('ac'));
    await t.pump(); // tek kare: animasyon süresi 0
    await t.pump();
    expect(find.text('Reklam izle'), findsOneWidget);
  });

  group('AdService (SDK olmadan)', () {
    test('rıza yok / reklam hazır değil: ödül verilmez, sayaç artmaz, teklif edilemez', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a = AdService.forTest()..pacing = AdPacing(prefs);
      expect(a.odulMumkun(OdulTuru.kutuAc), isFalse);
      expect(await a.showRewardedFor(OdulTuru.kutuAc), isFalse);
      expect(await a.maybeShowInterstitial(tamamlananFal: 9), isFalse);
      expect(a.pacing!.canOfferReward(OdulTuru.kutuAc, DateTime.now()), isTrue);
      expect(prefs.getString(AdPacing.prefsKey), isNull, reason: 'hiçbir şey kaydedilmedi');
    });

    test('admin modu: teklif mümkün ve ödül doğrudan; geçiş yok', () async {
      final a = AdService.forTest()..setAdsDisabled(true);
      expect(a.odulMumkun(OdulTuru.hakBitti, falTuru: 'kahve'), isTrue);
      expect(await a.showRewardedFor(OdulTuru.hakBitti, falTuru: 'kahve'), isTrue);
      expect(await a.maybeShowInterstitial(tamamlananFal: 9), isFalse);
    });
  });
}
