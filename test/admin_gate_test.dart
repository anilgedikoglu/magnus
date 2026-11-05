// Yönetici kapısı: kişisel veri olmadan godag bayrağı + eski cihazlar için özet.
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/utils/admin_gate.dart';
import 'package:magnus_app/data/models/user_profile.dart';
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

  test('nötr profil kişisel veri taşımaz', () {
    final p = neutralAdminProfile();
    expect(p.name, 'Magnus');
    expect(p.lastName, isNull);
    expect(p.onboardingComplete, isTrue);
  });
}
