// ── AI NOTU: user_profile.dart ────────────────────────────────────────────────
// Kullanıcının tüm profil bilgisini tutan Hive modeli.
// Provider: userProfileProvider (lib/data/providers.dart) — Riverpod StateNotifier.
// Riverpod ile okuma: ref.read/watch(userProfileProvider)
// Kaydetme: ref.read(userProfileProvider.notifier).save(UserProfile(...))
//
// Alan adları ve değerleri (VariableReplacer ve koşul sistemi için kritik):
//   name          → string, kullanıcı adı
//   age           → int
//   gender        → 'erkek' | 'kadin' | 'lgbt'
//   job           → 'ogrenci' | 'kamusektoru' | 'ozelsektoru' | 'serbest' | 'emekli' | 'issiz'
//   maritalStatus → 'evli' | 'bekar' | 'nisanli' | 'iliski_var' | 'yeni_ayrilmis' | 'bosanmis' | 'dul'
//   birthDate     → 'YYYY-MM-DD'
//   birthCity     → string
//   zodiacSign    → 'Koç'|'Boğa'|'İkizler'|'Yengeç'|'Aslan'|'Başak'|'Terazi'|'Akrep'|'Yay'|'Oğlak'|'Kova'|'Balık'
//   birthTime     → 'HH:MM'
//   risingSign    → burç adı (yükselen)
//   moonSign      → burç adı (ay burcu)
//   planet        → gezegen adı
//   profilePicIndex  → 0-3 (sprite avatar) veya null
//   customPhotoPath  → dosya yolu veya null
//   onboardingComplete → bool
//
// toVariableMap() → VariableReplacer için tüm alanları string map'e çevirir.
// Türkçe çekim ekleri (_dative, _accusative, _ablative, _diminutive) bu dosyada.
//
// Admin koşulu (settings_screen.dart'ta):
//   name≈'Anıl' && maritalStatus='evli' && birthDate='1983-10-14'
//   && job='kamusektoru' && zodiacSign='Terazi' && birthTime='13:30' && birthCity='Ankara'
// ─────────────────────────────────────────────────────────────────────────────
import 'package:hive_flutter/hive_flutter.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  String gender; // 'erkek' | 'kadın' | 'belirtmek istemiyorum'

  @HiveField(3)
  String job; // profession key (evhanimi, ogrenci, kamusektoru, ...)

  @HiveField(4)
  String maritalStatus; // iliskisi_yok, iliski_var, evli, ...

  @HiveField(5)
  String? birthDate; // 'YYYY-MM-DD'

  @HiveField(6)
  String? birthCity;

  @HiveField(7)
  String? zodiacSign; // burc — derived from birthDate

  @HiveField(8)
  bool onboardingComplete;

  @HiveField(9)
  String? birthTime; // 'HH:MM'

  @HiveField(10)
  String? risingSign; // Yükselen burç

  @HiveField(11)
  String? moonSign; // Ay burcu

  @HiveField(12)
  String? planet; // Kullanıcı tarafından seçilen gezegen (override)

  @HiveField(13)
  int? profilePicIndex; // 0-3: profilepic.jpg sprite sheet köşeleri

  @HiveField(14)
  String? customPhotoPath; // kamera/galeriden seçilen fotoğraf yolu

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.job,
    required this.maritalStatus,
    this.birthDate,
    this.birthCity,
    this.zodiacSign,
    this.onboardingComplete = false,
    this.birthTime,
    this.risingSign,
    this.moonSign,
    this.planet,
    this.profilePicIndex,
    this.customPhotoPath,
  });

  // ─── Variable map for {{variable}} replacement ────────────────────────────
  Map<String, String> toVariableMap() {
    return {
      // ── Temel profil ──────────────────────────────────────────────────────
      'isim': name,
      'ismi': name,
      'yas': age.toString(),
      'yasim': age.toString(),
      'cinsiyet': gender,
      'cinsiyetim': gender,
      'meslek': jobLabel,
      'medeni_durum': maritalStatusLabel,
      'burc': zodiacSign ?? '',
      'dogum_tarihi': birthDate ?? '',
      'dogum_sehri': birthCity ?? '',
      // ── İsim halleri (Türkçe çekim) ───────────────────────────────────────
      'isime': _dative(name),       // "Ahmet'e", "Ayşe'ye"
      'isimi': _accusative(name),   // "Ahmet'i", "Ayşe'yi"
      'isimden': _ablative(name),   // "Ahmet'ten", "Ayşe'den"
      'isimcigim': _diminutive(name), // "Ahmetciğim", "Ayşeciğim"
      'harf': name.isNotEmpty ? name[0].toUpperCase() : '',
      // ── Lokasyon ─────────────────────────────────────────────────────────
      'kullanici sehri': birthCity ?? '',
      // ── Doldurulamayan (veri yok) — boş bırakılır ─────────────────────────
      'soyisim': '',
      'fiziki': '',
      'ayburcu': '',
      'yukselen': '',
      // Time-based variables (filled at runtime by VariableReplacer)
      'gun': '',
      'ay': '',
      'mevsim': '',
    };
  }

  // ── Türkçe isim çekim yardımcıları ────────────────────────────────────────

  static const _frontVowels = {'e', 'i', 'ö', 'ü'};
  static const _backVowels  = {'a', 'ı', 'o', 'u'};
  static const _allVowels   = {'a', 'e', 'ı', 'i', 'o', 'ö', 'u', 'ü'};
  static const _voicelessLast = {'ç', 'f', 'h', 'k', 'p', 's', 'ş', 't'};

  static bool _isFrontVowel(String name) {
    for (int i = name.length - 1; i >= 0; i--) {
      final c = name[i].toLowerCase();
      if (_frontVowels.contains(c)) return true;
      if (_backVowels.contains(c)) return false;
    }
    return true; // varsayılan ince
  }

  static bool _endsInVowel(String name) =>
      name.isNotEmpty && _allVowels.contains(name[name.length - 1].toLowerCase());

  static String _dative(String name) {
    if (name.isEmpty) return name;
    final front = _isFrontVowel(name);
    if (_endsInVowel(name)) {
      return "$name'${front ? 'ye' : 'ya'}";
    }
    return "$name'${front ? 'e' : 'a'}";
  }

  static String _accusative(String name) {
    if (name.isEmpty) return name;
    final lastVowel = name.toLowerCase().split('').lastWhere(
      (c) => _allVowels.contains(c), orElse: () => 'i');
    final suffix = _frontVowels.contains(lastVowel)
        ? (lastVowel == 'ö' || lastVowel == 'ü' ? 'ü' : 'i')
        : (lastVowel == 'o' || lastVowel == 'u' ? 'u' : 'ı');
    return _endsInVowel(name) ? "$name'y$suffix" : "$name'$suffix";
  }

  static String _ablative(String name) {
    if (name.isEmpty) return name;
    final front = _isFrontVowel(name);
    final voiceless = _voicelessLast.contains(name[name.length - 1].toLowerCase());
    final cons = voiceless ? 't' : 'd';
    return "$name'${cons}${front ? 'en' : 'an'}";
  }

  static String _diminutive(String name) {
    if (name.isEmpty) return name;
    final last = name[name.length - 1].toLowerCase();
    final voiceless = _voicelessLast.contains(last);
    return "$name${voiceless ? 'çiğim' : 'ciğim'}";
  }

  String get jobLabel {
    const labels = {
      'evhanimi': 'Ev Hanımı',
      'calismiyor': 'Çalışmıyor',
      'isariyor': 'İş Arıyor',
      'ogrenci': 'Öğrenci',
      'akademisyen': 'Akademisyen',
      'kendiisi': 'Kendi İşini Yapıyor',
      'kamusektoru': 'Kamu Sektörü',
      'ozelsektoru': 'Özel Sektör',
      'emekli': 'Emekli',
    };
    return labels[job] ?? job;
  }

  String get maritalStatusLabel {
    const labels = {
      'iliskisi_yok': 'Bekar',
      'platonik': 'Platonik',
      'iliski_var': 'İlişkisi Var',
      'flort': 'Flört',
      'karisik': 'Karmaşık',
      'yeni_ayrilmis': 'Yeni Ayrılmış',
      'nisanli': 'Nişanlı',
      'evli': 'Evli',
      'ayri_yasiyor': 'Ayrı Yaşıyor',
      'bosanmis': 'Boşanmış',
      'dul': 'Dul',
    };
    return labels[maritalStatus] ?? maritalStatus;
  }

  String get genderLabel {
    switch (gender) {
      case 'erkek':
        return 'Erkek';
      case 'kadin':
        return 'Kadın';
      default:
        return 'Belirtilmiyor';
    }
  }

  factory UserProfile.empty() => UserProfile(
        name: '',
        age: 0,
        gender: '',
        job: '',
        maritalStatus: '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'job': job,
        'maritalStatus': maritalStatus,
        'birthDate': birthDate,
        'birthCity': birthCity,
        'zodiacSign': zodiacSign,
        'onboardingComplete': onboardingComplete,
        'birthTime': birthTime,
        'risingSign': risingSign,
        'moonSign': moonSign,
        'planet': planet,
        'profilePicIndex': profilePicIndex,
        'customPhotoPath': customPhotoPath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? '',
        age: json['age'] ?? 0,
        gender: json['gender'] ?? '',
        job: json['job'] ?? '',
        maritalStatus: json['maritalStatus'] ?? '',
        birthDate: json['birthDate'],
        birthCity: json['birthCity'],
        zodiacSign: json['zodiacSign'],
        onboardingComplete: json['onboardingComplete'] ?? false,
        birthTime: json['birthTime'],
        risingSign: json['risingSign'],
        moonSign: json['moonSign'],
        planet: json['planet'],
        profilePicIndex: json['profilePicIndex'] as int?,
        customPhotoPath: json['customPhotoPath'],
      );
}

// ─── Job options for UI ────────────────────────────────────────────────────
class JobOption {
  final String key;
  final String label;
  const JobOption(this.key, this.label);
}

const List<JobOption> kJobOptions = [
  JobOption('evhanimi', 'Ev Hanımı'),
  JobOption('calismiyor', 'Çalışmıyor'),
  JobOption('isariyor', 'İş Arıyor'),
  JobOption('ogrenci', 'Öğrenci'),
  JobOption('akademisyen', 'Akademisyen'),
  JobOption('kendiisi', 'Kendi İşini Yapıyor'),
  JobOption('kamusektoru', 'Kamu Sektörü'),
  JobOption('ozelsektoru', 'Özel Sektör'),
  JobOption('emekli', 'Emekli'),
];

// ─── Marital status options for UI ────────────────────────────────────────
class MaritalOption {
  final String key;
  final String label;
  const MaritalOption(this.key, this.label);
}

const List<MaritalOption> kMaritalOptions = [
  MaritalOption('iliskisi_yok', 'Bekar'),
  MaritalOption('platonik', 'Platonik'),
  MaritalOption('iliski_var', 'İlişkisi Var'),
  MaritalOption('flort', 'Flört'),
  MaritalOption('karisik', 'Karmaşık'),
  MaritalOption('yeni_ayrilmis', 'Yeni Ayrılmış'),
  MaritalOption('nisanli', 'Nişanlı'),
  MaritalOption('evli', 'Evli'),
  MaritalOption('ayri_yasiyor', 'Ayrı Yaşıyor'),
  MaritalOption('bosanmis', 'Boşanmış'),
  MaritalOption('dul', 'Dul'),
];

// ─── Gender options ────────────────────────────────────────────────────────
const List<(String, String)> kGenderOptions = [
  ('kadin', 'Kadın'),
  ('erkek', 'Erkek'),
  ('belirtmek_istemiyorum', 'Belirtilmiyor'),
];
