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
  });

  // ─── Variable map for {{variable}} replacement ────────────────────────────
  Map<String, String> toVariableMap() {
    return {
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
      // Time-based variables (filled at runtime by VariableReplacer)
      'gun': '',
      'ay': '',
      'mevsim': '',
    };
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
        return 'Belirtmek İstemiyorum';
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
  ('erkek', 'Erkek'),
  ('kadin', 'Kadın'),
  ('belirtmek_istemiyorum', 'Belirtmek İstemiyorum'),
];
