// Yönetici kapısı: kişisel veri olmadan godag bayrağı + eski cihazlar için özet.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/services/ad_service.dart';
import 'package:magnus_app/core/utils/admin_gate.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('FNV-1a 32 bilinen değerler', () {
    expect(fnv1a32(''), 0x811c9dc5);
    expect(fnv1a32('a'), 0xe40c292c);
  });

  test('nötr profil: bayrak yoksa yönetici değil, bayrakla yönetici', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final p = neutralAdminProfile();
    expect(isAdmin(p, prefs), isFalse);
    await prefs.setBool(kAdminModeKey, true);
    expect(isAdmin(p, prefs), isTrue);
  });

  test('sıradan kullanıcı yönetici sayılmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final p = UserProfile(
      name: 'Deniz',
      age: 30,
      gender: 'kadin',
      job: 'ozelsektoru',
      maritalStatus: 'iliskisi_yok',
      birthDate: '1996-03-02',
      birthCity: 'İzmir',
      zodiacSign: 'Balık',
      birthTime: '08:15',
    );
    expect(isAdmin(p, prefs), isFalse);
  });

  group('reklam kapatma yalnız yönetici iken geçerli', () {
    final siradan = UserProfile(
      name: 'Deniz',
      age: 30,
      gender: 'kadin',
      job: 'ozelsektoru',
      maritalStatus: 'iliskisi_yok',
    );

    test('ayar açık + yönetici → reklam kapalı; ayar kapalı → reklam açık', () async {
      SharedPreferences.setMockInitialValues({kAdminModeKey: true, kAdsDisabledKey: true});
      final prefs = await SharedPreferences.getInstance();
      expect(reklamlarKapaliMi(siradan, prefs), isTrue);
      await prefs.setBool(kAdsDisabledKey, false);
      expect(reklamlarKapaliMi(siradan, prefs), isFalse);
    });

    test('yönetici olmayan profilde eski ayar reklamı kapatamaz', () async {
      SharedPreferences.setMockInitialValues({kAdsDisabledKey: true});
      final prefs = await SharedPreferences.getInstance();
      expect(reklamlarKapaliMi(siradan, prefs), isFalse);
    });

    test('profil değişince reklam ayarı eşitlenir', () async {
      SharedPreferences.setMockInitialValues({kAdsDisabledKey: true});
      final prefs = await SharedPreferences.getInstance();
      final eski = AdService.instance;
      addTearDown(() => AdService.instance = eski);
      AdService.instance = AdService.forTest()..setAdsDisabled(true);
      final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);

      await c.read(userProfileProvider.notifier).save(siradan);
      expect(AdService.instance.adsDisabled, isFalse);
      expect(AdService.instance.tanilama, startsWith('ads on'));
    });
  });

  test('nötr profil kişisel veri taşımaz', () {
    final p = neutralAdminProfile();
    expect(p.name, 'Magnus');
    expect(p.lastName, isNull);
    expect(p.onboardingComplete, isTrue);
  });
}
