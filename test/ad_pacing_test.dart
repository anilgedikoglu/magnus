// Reklam sıklık sınırları (docs/reklam_duzeni.md): kalıcı sayaçlar, gün sıfırlama, saat geri alma.
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/services/ad_pacing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AdPacing> _yeni([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(Map.of(seed));
  return AdPacing(await SharedPreferences.getInstance());
}

void main() {
  final t0 = DateTime(2026, 11, 9, 12, 0, 0);

  group('Geçiş reklamı', () {
    test('ilk 2 fal tamamlanmadan geçiş yok', () async {
      final p = await _yeni();
      expect(p.canShowInterstitial(t0, tamamlananFal: 0), isFalse);
      expect(p.canShowInterstitial(t0, tamamlananFal: 1), isFalse);
      expect(p.canShowInterstitial(t0, tamamlananFal: 2), isTrue);
    });

    test('en az 120 sn aralık', () async {
      final p = await _yeni();
      await p.recordInterstitial(t0);
      expect(p.canShowInterstitial(t0.add(const Duration(seconds: 119)), tamamlananFal: 9), isFalse);
      expect(p.canShowInterstitial(t0.add(const Duration(seconds: 120)), tamamlananFal: 9), isTrue);
    });

    test('oturumda en çok 3; yeniden açılışta oturum sıfırlanır, gün sayacı kalır', () async {
      final p = await _yeni();
      await p.recordInterstitial(t0);
      await p.recordInterstitial(t0.add(const Duration(minutes: 5)));
      await p.recordInterstitial(t0.add(const Duration(minutes: 10)));
      final sonra = t0.add(const Duration(minutes: 20));
      expect(p.canShowInterstitial(sonra, tamamlananFal: 9), isFalse);
      final prefs = await SharedPreferences.getInstance();
      final yeniOturum = AdPacing(prefs);
      expect(yeniOturum.canShowInterstitial(sonra, tamamlananFal: 9), isTrue);
    });

    test('günde en çok 6 (oturum sıfırlansa da kalıcı)', () async {
      var p = await _yeni();
      final prefs = await SharedPreferences.getInstance();
      var now = t0;
      for (var i = 0; i < 6; i++) {
        if (i == 3) p = AdPacing(prefs); // yeni oturum
        expect(p.canShowInterstitial(now, tamamlananFal: 9), isTrue, reason: 'geçiş ${i + 1}');
        await p.recordInterstitial(now);
        now = now.add(const Duration(minutes: 4));
      }
      expect(AdPacing(prefs).canShowInterstitial(now, tamamlananFal: 9), isFalse, reason: 'gün sınırı 6');
    });

    test('ertesi gün sayaçlar sıfırlanır', () async {
      final p = await _yeni();
      for (var i = 0; i < 6; i++) {
        await p.recordInterstitial(t0.add(Duration(minutes: 4 * i)));
      }
      final prefs = await SharedPreferences.getInstance();
      expect(AdPacing(prefs).canShowInterstitial(DateTime(2026, 11, 10, 9), tamamlananFal: 9), isTrue);
    });

    test('saat geri alınırsa güvenli: gün sayacı sıfırlanmaz, aralık sağlanmış sayılmaz', () async {
      final p = await _yeni();
      for (var i = 0; i < 6; i++) {
        await p.recordInterstitial(t0.add(Duration(minutes: 4 * i)));
      }
      final prefs = await SharedPreferences.getInstance();
      expect(AdPacing(prefs).canShowInterstitial(DateTime(2026, 11, 8, 12), tamamlananFal: 9), isFalse);

      // Aynı gün içinde geri alma: son geçiş "gelecekte" kalır → şimdi gösterme, sonra normal akış.
      final p2 = await _yeni();
      await p2.recordInterstitial(t0);
      final geri = t0.subtract(const Duration(hours: 3));
      expect(p2.canShowInterstitial(geri, tamamlananFal: 9), isFalse);
      expect(p2.canShowInterstitial(geri.add(const Duration(seconds: 121)), tamamlananFal: 9), isTrue);
    });

    test('ödüllü izledikten sonra 120 sn geçiş yok', () async {
      final p = await _yeni();
      await p.recordReward(OdulTuru.hemenAc, t0);
      expect(p.canShowInterstitial(t0.add(const Duration(seconds: 119)), tamamlananFal: 9), isFalse);
      expect(p.canShowInterstitial(t0.add(const Duration(seconds: 120)), tamamlananFal: 9), isTrue);
    });

    test('bozuk kayıt uygulamayı bozmaz', () async {
      final p = await _yeni({AdPacing.prefsKey: '{bozuk'});
      expect(p.canShowInterstitial(t0, tamamlananFal: 2), isTrue);
    });
  });

  group('Doğal ara', () {
    test('menüye dönüş + 25 sn ve üstü + Dert Ortağı hariç', () {
      const sure = Duration(seconds: 25);
      expect(AdPacing.dogalAraMi('kahve', sure, menuyeDonuyor: true), isTrue);
      expect(AdPacing.dogalAraMi('kahve', const Duration(seconds: 24), menuyeDonuyor: true), isFalse);
      expect(AdPacing.dogalAraMi('kahve', sure, menuyeDonuyor: false), isFalse);
      expect(AdPacing.dogalAraMi('dertortagi', const Duration(minutes: 5), menuyeDonuyor: true), isFalse);
    });

    test('gelen kutusuna düşen falda kısa eşik; dokunuştan hemen sonra yok', () {
      expect(AdPacing.dogalAraMi('iching', const Duration(seconds: 5), menuyeDonuyor: true, kutuyaDustu: true), isTrue);
      expect(AdPacing.dogalAraMi('japonfali', const Duration(seconds: 1), menuyeDonuyor: true, kutuyaDustu: true), isFalse);
      expect(AdPacing.dogalAraMi('iching', const Duration(seconds: 5), menuyeDonuyor: true), isFalse);
    });
  });

  group('Ödüllü', () {
    test('hak bitti: tür başına 2, günde toplam 6', () async {
      final p = await _yeni();
      expect(p.canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'kahve'), isTrue);
      await p.recordReward(OdulTuru.hakBitti, t0, falTuru: 'kahve');
      expect(p.canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'kahve'), isTrue, reason: 'aynı tür 2. hak');
      await p.recordReward(OdulTuru.hakBitti, t0, falTuru: 'kahve');
      expect(p.canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'kahve'), isFalse, reason: 'aynı tür 2');
      expect(p.canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'tarot'), isTrue);
      for (final tur in const ['tarot', 'tarot', 'durugoru', 'durugoru']) {
        await p.recordReward(OdulTuru.hakBitti, t0, falTuru: tur);
      }
      expect(p.canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'askuyumu'), isFalse, reason: 'günde 6');
    });

    test('306 biçimindeki kayıt: listedeki tür 1 hak kullanmış sayılır', () async {
      final bugun = AdPacing.gunAnahtari(t0);
      final p = await _yeni({
        AdPacing.prefsKey: '{"d":"$bugun","ig":0,"li":0,"r":{"hakBitti":1},"hb":["kahve"]}',
      });
      expect(p.canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'kahve'), isTrue);
      await p.recordReward(OdulTuru.hakBitti, t0, falTuru: 'kahve');
      final prefs = await SharedPreferences.getInstance();
      expect(AdPacing(prefs).canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'kahve'), isFalse);
    });

    test('hemen aç günde 5, kutu açma günde 8', () async {
      final p = await _yeni();
      for (var i = 0; i < 5; i++) {
        expect(p.canOfferReward(OdulTuru.hemenAc, t0), isTrue);
        await p.recordReward(OdulTuru.hemenAc, t0);
      }
      expect(p.canOfferReward(OdulTuru.hemenAc, t0), isFalse);
      for (var i = 0; i < 8; i++) {
        expect(p.canOfferReward(OdulTuru.kutuAc, t0), isTrue, reason: 'kutu ${i + 1}');
        await p.recordReward(OdulTuru.kutuAc, t0);
      }
      expect(p.canOfferReward(OdulTuru.kutuAc, t0), isFalse);
    });

    test('hepsi toplam günde 15', () async {
      final p = await _yeni();
      for (var i = 0; i < 5; i++) {
        await p.recordReward(OdulTuru.hemenAc, t0);
      }
      for (var i = 0; i < 8; i++) {
        await p.recordReward(OdulTuru.kutuAc, t0);
      }
      for (final tur in const ['kahve', 'tarot']) {
        expect(p.canOfferReward(OdulTuru.hakBitti, t0, falTuru: tur), isTrue);
        await p.recordReward(OdulTuru.hakBitti, t0, falTuru: tur);
      }
      expect(p.canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'durugoru'), isFalse, reason: 'toplam 15 doldu');
    });

    test('kalıcı + ertesi gün sıfırlanır', () async {
      final p = await _yeni();
      await p.recordReward(OdulTuru.hakBitti, t0, falTuru: 'kahve');
      await p.recordReward(OdulTuru.hakBitti, t0, falTuru: 'kahve');
      final prefs = await SharedPreferences.getInstance();
      final ayni = AdPacing(prefs);
      expect(ayni.canOfferReward(OdulTuru.hakBitti, t0, falTuru: 'kahve'), isFalse);
      expect(ayni.canOfferReward(OdulTuru.hakBitti, DateTime(2026, 11, 10, 8), falTuru: 'kahve'), isTrue);
    });
  });
}
