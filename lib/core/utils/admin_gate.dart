// Yönetici (admin) kapısı — kişisel veri İÇERMEZ.
//
// Eskiden yönetici profili gerçek kişisel bilgilerle açık metin olarak kodda duruyordu
// (yayınlanan uygulamaya giriyordu). Artık:
//  • "godag" girişi nötr bir profil kaydeder + [kAdminModeKey] bayrağını açar.
//  • Daha önce eski yöntemle girilmiş cihazlar, profil parmak izinin özetiyle
//    ([_kLegacyFingerprint], FNV-1a 32) tanınır — açık metin veri yok.
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_profile.dart';

/// godag girişiyle açılan yönetici modu bayrağı.
const kAdminModeKey = 'admin_mode';

/// Admin panelindeki "Reklamlar" anahtarının kalıcı değeri.
const kAdsDisabledKey = 'admin_ads_disabled';

/// Eski (2026-11 öncesi) godag profilinin parmak izi özeti.
const _kLegacyFingerprint = 0xac4a7277;

/// godag girişinde kaydedilen nötr yönetici profili (koşul filtreleri için
/// evli / kamu sektörü / erkek / Terazi; kimseye ait değildir).
UserProfile neutralAdminProfile() => UserProfile(
      name: 'Magnus',
      age: 36,
      gender: 'erkek',
      job: 'kamusektoru',
      maritalStatus: 'evli',
      birthDate: '1990-10-10',
      birthCity: 'İstanbul',
      zodiacSign: 'Terazi',
      birthTime: '12:00',
      onboardingComplete: true,
    );

/// Türkçe i/ı farkını görmezden gelen normalize (hepsi 'i').
String _trNorm(String s) =>
    s.replaceAll('ı', 'i').replaceAll('I', 'i').replaceAll('İ', 'i').toLowerCase();

/// FNV-1a 32 bit (UTF-16 kod birimleri üzerinde).
int fnv1a32(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

int _fingerprint(UserProfile p) => fnv1a32([
      _trNorm(p.name),
      p.maritalStatus,
      p.birthDate ?? '',
      p.job,
      p.zodiacSign ?? '',
      p.birthTime ?? '',
      p.birthCity ?? '',
    ].join('|'));

/// Yönetici paneli gösterilsin mi?
bool isAdmin(UserProfile p, SharedPreferences prefs) =>
    (prefs.getBool(kAdminModeKey) ?? false) || _fingerprint(p) == _kLegacyFingerprint;

/// Reklamlar kapalı mı? Ayar yalnız yönetici iken geçerlidir: profil değişip yönetici olmaktan
/// çıkılınca reklamlar açılır (yoksa eski ayar reklamı sessizce kapalı tutar, ödül bedava verilirdi).
bool reklamlarKapaliMi(UserProfile p, SharedPreferences prefs) =>
    (prefs.getBool(kAdsDisabledKey) ?? false) && isAdmin(p, prefs);
