// "Kısmetim Kim?" falı motoru (2026-11-05). Tasarım: Anıl'ın kuralları + Codex + DeepSeek.
//
// Kullanıcıya özel bir KISMET ZAMAN ÇİZELGESİ bir kez üretilir ve saklanır:
//  • bu yıldan +50'ye kadar her yıl bir segmente düşer: kişi / eş / partner / boşluk;
//  • aynı yıl her zaman aynı sonucu verir; ardışık yıllar çoğunlukla aynı kişidir
//    (en kısa segment 3 yıl) — her yıl başka isim çıkmaz;
//  • kadın kullanıcı: ömür boyu 1 (%85) ya da 2 kişi; erkek: yaşa göre (çok genç 3-10);
//  • evli: "Eşin" ilk 5 yıl kesin, ömür boyu sürme olasılığı %55 (Codex: evlilik mutlaka
//    bitmesin); ilişkisi/nişanı olan: "Şu anki partnerin";
//  • çizelgelerin %15'inde 1-2 yıllık "yeni tanışma görünmüyor" boşluğu;
//  • kişiler kimlikle saklanır: aynı kişi farklı yılda aynı isim/özelliklerle çıkar,
//    açılmış kutuları açık kalır (tekrar reklam yok).
// Özellik dağılımları (DeepSeek, Türkiye geneli yaklaşık): saç siyah %42, koyu kahve %28,
// kumral %18, sarı %6, kızıl %2; göz kahverengi %72, ela %16, yeşil %6, mavi %5;
// boy kadın 160±7.6, erkek 171±8.1 cm. Eğlence amaçlıdır.
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

enum KismetKind { person, spouse, partner, gap }

class KismetPerson {
  KismetPerson({
    required this.id,
    required this.firstName,
    required this.lastInitial,
    required this.job,
    required this.city,
    required this.hair,
    required this.eye,
    required this.heightCm,
    required this.birthYear,
    required this.female,
  });

  final String id;
  final String firstName;
  final String lastInitial;
  final String job; // anahtar (KismetLabels.job)
  final String city;
  final String hair; // anahtar
  final String eye; // anahtar
  final int heightCm;
  final int birthYear;
  final bool female;

  String get displayName => '$firstName $lastInitial.';

  Map<String, dynamic> toJson() => {
        'id': id, 'fn': firstName, 'li': lastInitial, 'job': job, 'city': city,
        'hair': hair, 'eye': eye, 'h': heightCm, 'by': birthYear, 'f': female,
      };

  static KismetPerson fromJson(Map<String, dynamic> j) => KismetPerson(
        id: j['id'] as String,
        firstName: j['fn'] as String,
        lastInitial: j['li'] as String,
        job: j['job'] as String,
        city: j['city'] as String,
        hair: j['hair'] as String,
        eye: j['eye'] as String,
        heightCm: j['h'] as int,
        birthYear: j['by'] as int,
        female: j['f'] as bool,
      );
}

class KismetSegment {
  const KismetSegment(this.start, this.end, this.kind, [this.personId]);
  final int start; // dahil
  final int end; // dahil
  final KismetKind kind;
  final String? personId;

  Map<String, dynamic> toJson() => {'s': start, 'e': end, 'k': kind.name, 'p': personId};
  static KismetSegment fromJson(Map<String, dynamic> j) => KismetSegment(
      j['s'] as int, j['e'] as int, KismetKind.values.byName(j['k'] as String), j['p'] as String?);
}

class KismetResult {
  const KismetResult(this.year, this.kind, [this.person]);
  final int year;
  final KismetKind kind;
  final KismetPerson? person;
}

/// Kutu alanları (sırası ekrandaki sıradır).
const kKismetFields = ['name', 'job', 'city', 'hair', 'eye', 'height'];

class KismetTimeline {
  KismetTimeline({
    required this.seed,
    required this.baseYear,
    required this.signature,
    required this.segments,
    required this.people,
    Map<String, Set<String>>? revealed,
  }) : revealed = revealed ?? {};

  static const schema = 1;
  final int seed;
  final int baseYear;
  final String signature;
  final List<KismetSegment> segments;
  final Map<String, KismetPerson> people;
  final Map<String, Set<String>> revealed; // personId → açılmış alanlar

  int get lastYear => segments.last.end;

  KismetResult resultFor(int year) {
    final y = year.clamp(baseYear, lastYear);
    for (final s in segments) {
      if (y >= s.start && y <= s.end) {
        return KismetResult(year, s.kind, s.personId == null ? null : people[s.personId]);
      }
    }
    final s = segments.last;
    return KismetResult(year, s.kind, s.personId == null ? null : people[s.personId]);
  }

  bool isRevealed(String personId, String field) => revealed[personId]?.contains(field) ?? false;

  Map<String, dynamic> toJson() => {
        'v': schema, 'seed': seed, 'base': baseYear, 'sig': signature,
        'seg': [for (final s in segments) s.toJson()],
        'people': {for (final e in people.entries) e.key: e.value.toJson()},
        'rev': {for (final e in revealed.entries) e.key: e.value.toList()},
      };

  static KismetTimeline? fromJson(Map<String, dynamic> j) {
    if (j['v'] != schema) return null;
    return KismetTimeline(
      seed: j['seed'] as int,
      baseYear: j['base'] as int,
      signature: j['sig'] as String,
      segments: [for (final s in j['seg'] as List) KismetSegment.fromJson(Map<String, dynamic>.from(s as Map))],
      people: {
        for (final e in (j['people'] as Map).entries)
          e.key as String: KismetPerson.fromJson(Map<String, dynamic>.from(e.value as Map)),
      },
      revealed: {
        for (final e in ((j['rev'] as Map?) ?? {}).entries)
          e.key as String: {for (final f in e.value as List) f as String},
      },
    );
  }
}

class KismetEngine {
  KismetEngine._();

  static const prefsKey = 'kismet_timeline_v1';
  static const horizon = 50;

  /// Kayıtlı çizelgeyi yükler; yoksa (veya cinsiyet/medeni hal grubu değiştiyse) üretir.
  static Future<KismetTimeline> load(SharedPreferences prefs, UserProfile p, {int? nowYear}) async {
    final year = nowYear ?? DateTime.now().year;
    final sig = signatureOf(p);
    final raw = prefs.getString(prefsKey);
    if (raw != null) {
      try {
        final t = KismetTimeline.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        if (t != null && t.signature == sig) {
          final extended = _extend(t, year + horizon);
          if (!identical(extended, t)) await save(prefs, extended);
          return extended;
        }
      } catch (_) {/* bozuk kayıt → yeniden üret */}
    }
    final t = generate(p, baseYear: year, seed: Random().nextInt(1 << 31));
    await save(prefs, t);
    return t;
  }

  static Future<void> save(SharedPreferences prefs, KismetTimeline t) =>
      prefs.setString(prefsKey, jsonEncode(t.toJson()));

  static Future<void> reveal(SharedPreferences prefs, KismetTimeline t, String personId, String field) {
    (t.revealed[personId] ??= <String>{}).add(field);
    return save(prefs, t);
  }

  /// Takvim ilerleyince sona yıl ekle (mevcut yıllar DEĞİŞMEZ): son segment uzar.
  static KismetTimeline _extend(KismetTimeline t, int toYear) {
    if (t.lastYear >= toYear) return t;
    final segs = [...t.segments];
    final last = segs.removeLast();
    segs.add(KismetSegment(last.start, toYear, last.kind, last.personId));
    return KismetTimeline(
        seed: t.seed, baseYear: t.baseYear, signature: t.signature,
        segments: segs, people: t.people, revealed: t.revealed);
  }

  // ── Profil yorumlama ──────────────────────────────────────────────────────
  static String genderOf(UserProfile p) {
    final g = p.gender.toLowerCase().replaceAll('ı', 'i');
    if (g.startsWith('kad')) return 'kadin';
    if (g.startsWith('erk')) return 'erkek';
    return 'belirsiz';
  }

  static String maritalGroupOf(UserProfile p) {
    final m = p.maritalStatus.toLowerCase();
    if (m == 'evli') return 'evli';
    if (m.contains('iliski_var') || m.contains('iliskisi_var') || m.contains('nisan') || m.contains('soz')) {
      return 'partner';
    }
    return 'bekar';
  }

  static String signatureOf(UserProfile p) => '${genderOf(p)}|${maritalGroupOf(p)}';

  static int birthYearOf(UserProfile p, int nowYear) {
    final by = int.tryParse((p.birthDate ?? '').split('-').first);
    if (by != null && by > 1900) return by;
    return nowYear - (p.age > 0 ? p.age : 30);
  }

  // ── Üretim ────────────────────────────────────────────────────────────────
  static KismetTimeline generate(UserProfile p, {required int baseYear, required int seed}) {
    final rnd = Random(seed);
    final gender = genderOf(p);
    final group = maritalGroupOf(p);
    final userBirth = birthYearOf(p, baseYear);
    final age = baseYear - userBirth;
    final endYear = baseYear + horizon;
    final total = horizon + 1; // 51 yıl

    final segments = <KismetSegment>[];
    final people = <String, KismetPerson>{};
    var cursor = baseYear;

    // 1) Evli / partner: ilk segment eş/partner
    if (group != 'bekar') {
      final durations = group == 'evli'
          ? const [(5, 5), (10, 10), (20, 15), (35, 15), (51, 55)]
          : const [(5, 15), (10, 15), (20, 20), (35, 15), (51, 35)];
      final len = _weighted(rnd, durations);
      final kind = group == 'evli' ? KismetKind.spouse : KismetKind.partner;
      final end = min(endYear, baseYear + len - 1);
      segments.add(KismetSegment(baseYear, end, kind));
      cursor = end + 1;
    }

    // 2) Kalan yıllar: kişi sayısı + segmentler
    final remaining = endYear - cursor + 1;
    if (remaining > 0) {
      var count = _personCount(rnd, gender, age);
      if (group != 'bekar') count = max(1, min(count, gender == 'kadin' ? 1 : 3));
      count = max(1, min(count, remaining ~/ 3));
      final lengths = _partition(rnd, remaining, count,
          firstLong: count == 2 && group == 'bekar' ? (12, 35) : null);
      // %15 olasılıkla bir kez 1-2 yıllık boşluk (ilk kişiden sonra)
      final gapAfter = (count >= 2 && rnd.nextDouble() < 0.15) ? rnd.nextInt(count - 1) : -1;
      for (var i = 0; i < count; i++) {
        var len = lengths[i];
        if (i == gapAfter && len >= 5) {
          final g = 1 + rnd.nextInt(2);
          len -= g;
          final person = _makePerson(rnd, 'p$i', gender, userBirth);
          people[person.id] = person;
          segments.add(KismetSegment(cursor, cursor + len - 1, KismetKind.person, person.id));
          cursor += len;
          segments.add(KismetSegment(cursor, cursor + g - 1, KismetKind.gap));
          cursor += g;
          continue;
        }
        final person = _makePerson(rnd, 'p$i', gender, userBirth);
        people[person.id] = person;
        segments.add(KismetSegment(cursor, cursor + len - 1, KismetKind.person, person.id));
        cursor += len;
      }
    }
    assert(segments.first.start == baseYear && segments.last.end == endYear,
        'çizelge $total yılı boşluksuz kaplamalı');
    return KismetTimeline(
        seed: seed, baseYear: baseYear, signature: signatureOf(p), segments: segments, people: people);
  }

  static int _weighted(Random rnd, List<(int, int)> items) {
    final sum = items.fold<int>(0, (a, b) => a + b.$2);
    var r = rnd.nextInt(sum);
    for (final (v, w) in items) {
      if (r < w) return v;
      r -= w;
    }
    return items.last.$1;
  }

  /// Bekâr kullanıcı için toplam farklı kişi sayısı (Codex tablosu).
  static int _personCount(Random rnd, String gender, int age) {
    int range(int a, int b) => a + rnd.nextInt(b - a + 1);
    if (gender != 'erkek') return rnd.nextDouble() < 0.85 ? 1 : 2; // kadın + belirsiz
    final r = rnd.nextDouble();
    if (age < 25) {
      if (r < 0.15) return 1;
      if (r < 0.65) return range(3, 5);
      if (r < 0.95) return range(6, 8);
      return range(9, 10);
    }
    if (age < 40) {
      if (r < 0.30) return 1;
      if (r < 0.80) return range(2, 3);
      return range(4, 5);
    }
    if (age < 60) {
      if (r < 0.55) return 1;
      if (r < 0.90) return 2;
      return 3;
    }
    if (r < 0.80) return 1;
    return r < 0.98 ? 2 : 3;
  }

  /// [total] yılı [n] segmente böler; her segment ≥ 3 yıl.
  static List<int> _partition(Random rnd, int total, int n, {(int, int)? firstLong}) {
    if (n <= 1) return [total];
    final out = List<int>.filled(n, 3);
    var left = total - 3 * n;
    if (firstLong != null) {
      final want = (firstLong.$1 + rnd.nextInt(firstLong.$2 - firstLong.$1 + 1)) - 3;
      final add = min(left, max(0, want));
      out[0] += add;
      left -= add;
    }
    final weights = [for (var i = 0; i < n; i++) 0.4 + rnd.nextDouble()];
    final wsum = weights.reduce((a, b) => a + b);
    var given = 0;
    for (var i = 0; i < n; i++) {
      final add = (left * weights[i] / wsum).floor();
      out[i] += add;
      given += add;
    }
    out[n - 1] += left - given; // yuvarlama artığı
    return out;
  }

  // ── Kişi üretimi ──────────────────────────────────────────────────────────
  static T _pickW<T>(Random rnd, List<(T, int)> items) {
    final sum = items.fold<int>(0, (a, b) => a + b.$2);
    var r = rnd.nextInt(sum);
    for (final (v, w) in items) {
      if (r < w) return v;
      r -= w;
    }
    return items.last.$1;
  }

  static double _gauss(Random rnd) {
    final u = 1 - rnd.nextDouble();
    final v = rnd.nextDouble();
    return sqrt(-2 * log(u)) * cos(2 * pi * v);
  }

  static KismetPerson _makePerson(Random rnd, String id, String userGender, int userBirth) {
    // Karşı cins: erkek kullanıcı → kadın ismi; kadın → erkek; belirsiz → ortak isim
    final female = userGender == 'erkek'
        ? true
        : userGender == 'kadin'
            ? false
            : rnd.nextBool();
    // Kısmetin doğum yılı: kadın kullanıcıya 0-5 yaş büyük, erkek kullanıcıya 0-5 yaş küçük (eğilim)
    final offset = userGender == 'kadin'
        ? -rnd.nextInt(6)
        : userGender == 'erkek'
            ? rnd.nextInt(6)
            : rnd.nextInt(7) - 3;
    final birth = userBirth + offset;
    final pool = userGender == 'belirsiz'
        ? _unisex
        : female
            ? (birth < 1975 ? _femaleOld : birth < 1995 ? _femaleMid : _femaleNew)
            : (birth < 1975 ? _maleOld : birth < 1995 ? _maleMid : _maleNew);
    final name = pool[rnd.nextInt(pool.length)];
    final initial = _pickW(rnd, _initials);
    final eye = _pickW(rnd, const [('kahverengi', 72), ('ela', 16), ('yesil', 6), ('mavi', 5), ('gri', 1)]);
    final light = eye == 'mavi' || eye == 'yesil' || eye == 'gri';
    final hair = _pickW(
        rnd,
        light
            ? const [('siyah', 18), ('koyu_kahve', 24), ('kumral', 32), ('sari', 22), ('kizil', 4)]
            : const [('siyah', 44), ('koyu_kahve', 30), ('kumral', 18), ('sari', 6), ('kizil', 2)]);
    final h = female
        ? (160 + 7.6 * _gauss(rnd)).round().clamp(148, 178)
        : (171 + 8.1 * _gauss(rnd)).round().clamp(158, 192);
    return KismetPerson(
      id: id,
      firstName: name,
      lastInitial: initial,
      job: _jobs[rnd.nextInt(_jobs.length)],
      city: _pickW(rnd, _cities),
      hair: hair,
      eye: eye,
      heightCm: h,
      birthYear: birth,
      female: female,
    );
  }

  /// Seçilen yılda gösterilecek meslek: çok gençse öğrenci, 66+ ise emekli.
  static String jobForYear(KismetPerson p, int year) {
    final age = year - p.birthYear;
    if (age < 22) return 'ogrenci';
    if (age >= 66) return 'emekli';
    return p.job;
  }

  // ── Havuzlar ──────────────────────────────────────────────────────────────
  static const _femaleOld = [
    'Ayşe', 'Fatma', 'Emine', 'Hatice', 'Zeynep', 'Elif', 'Sevgi', 'Gülsüm', 'Nermin', 'Sevim',
    'Nurten', 'Aynur', 'Filiz', 'Gülay', 'Hülya', 'Serpil', 'Nilgün', 'Meral', 'Sema', 'Perihan',
  ];
  static const _femaleMid = [
    'Zeynep', 'Elif', 'Merve', 'Büşra', 'Esra', 'Özlem', 'Gamze', 'Tuğba', 'Derya', 'Ebru',
    'Burcu', 'Seda', 'Gizem', 'Pınar', 'Ceren', 'Aslı', 'Didem', 'Duygu', 'Selin', 'Sibel',
    'Yasemin', 'Ayşe', 'Fatma', 'Melike', 'Kübra', 'İrem', 'Damla', 'Ece', 'Nazlı', 'Deniz',
  ];
  static const _femaleNew = [
    'Zeynep', 'Elif', 'Defne', 'Eylül', 'Ecrin', 'Azra', 'Nehir', 'Asya', 'Miray', 'Zehra',
    'Ela', 'Ada', 'Lina', 'Duru', 'İpek', 'Beren', 'Yağmur', 'Sude', 'Melis', 'Nisa',
    'Buse', 'İrem', 'Ceylin', 'Hira', 'Rabia', 'Selin', 'Su', 'Öykü', 'Ilgın', 'Dila',
  ];
  static const _maleOld = [
    'Mehmet', 'Mustafa', 'Ahmet', 'Ali', 'Hüseyin', 'Hasan', 'İbrahim', 'İsmail', 'Osman', 'Yusuf',
    'Murat', 'Kemal', 'Halil', 'Erol', 'Orhan', 'Levent', 'Cengiz', 'Tuncay', 'Ercan', 'Nihat',
  ];
  static const _maleMid = [
    'Mehmet', 'Mustafa', 'Ahmet', 'Emre', 'Burak', 'Murat', 'Serkan', 'Onur', 'Tolga', 'Kerem',
    'Can', 'Cem', 'Okan', 'Barış', 'Gökhan', 'Volkan', 'Erkan', 'Hakan', 'Fatih', 'Kaan',
    'Selim', 'Umut', 'Oğuz', 'Uğur', 'Tuncay', 'Ozan', 'Sinan', 'Engin', 'Cihan', 'Arda',
  ];
  static const _maleNew = [
    'Yusuf', 'Eymen', 'Ömer', 'Mustafa', 'Mehmet', 'Alparslan', 'Aras', 'Kerem', 'Emir', 'Miraç',
    'Yiğit', 'Arda', 'Efe', 'Poyraz', 'Çınar', 'Kuzey', 'Deniz', 'Ege', 'Mert', 'Berk',
    'Baran', 'Tuna', 'Doruk', 'Alp', 'Batuhan', 'Eren', 'Kaan', 'Onur', 'Atlas', 'Aybars',
  ];
  static const _unisex = [
    'Deniz', 'Ekin', 'Özgür', 'Derya', 'Umut', 'Evren', 'Bora', 'Ilgaz', 'Eylül', 'Güneş',
    'Barış', 'Ege', 'Doğa', 'Kayra', 'Aydın', 'Yağmur', 'Arya', 'İlke', 'Toprak', 'Nur',
  ];
  static const _initials = [
    ('A', 9), ('B', 6), ('C', 3), ('Ç', 4), ('D', 6), ('E', 5), ('F', 3), ('G', 5), ('H', 4),
    ('I', 1), ('İ', 3), ('K', 9), ('L', 1), ('M', 5), ('N', 2), ('O', 3), ('Ö', 4), ('P', 2),
    ('R', 2), ('S', 6), ('Ş', 3), ('T', 6), ('U', 3), ('Ü', 2), ('V', 1), ('Y', 6), ('Z', 1),
  ];
  static const _jobs = [
    'ogretmen', 'muhendis', 'doktor', 'hemsire', 'avukat', 'mimar', 'eczaci', 'dishekimi',
    'yazilimci', 'tasarimci', 'akademisyen', 'pilot', 'bankaci', 'muhasebeci', 'psikolog',
    'veteriner', 'fizyoterapist', 'girisimci', 'esnaf', 'asci', 'fotografci', 'muzisyen',
    'gazeteci', 'satis', 'polis', 'kuafor', 'diyetisyen', 'sporcu', 'oyuncu', 'ciftci',
  ];
  static const _cities = [
    ('İstanbul', 10), ('Ankara', 6), ('İzmir', 6), ('Bursa', 4), ('Antalya', 4), ('Konya', 3),
    ('Adana', 3), ('Gaziantep', 3), ('Kocaeli', 3), ('Mersin', 3), ('Kayseri', 2), ('Eskişehir', 2),
    ('Samsun', 2), ('Trabzon', 2), ('Diyarbakır', 2), ('Denizli', 2), ('Malatya', 2), ('Sakarya', 2),
    ('Muğla', 2), ('Tekirdağ', 2), ('Balıkesir', 2), ('Aydın', 2), ('Manisa', 2), ('Hatay', 2),
    ('Şanlıurfa', 2), ('Erzurum', 1), ('Van', 1), ('Elazığ', 1), ('Sivas', 1), ('Ordu', 1),
    ('Rize', 1), ('Giresun', 1), ('Çanakkale', 1), ('Edirne', 1), ('Kırklareli', 1), ('Bolu', 1),
    ('Düzce', 1), ('Zonguldak', 1), ('Kastamonu', 1), ('Sinop', 1), ('Amasya', 1), ('Tokat', 1),
    ('Çorum', 1), ('Yozgat', 1), ('Kırşehir', 1), ('Nevşehir', 1), ('Niğde', 1), ('Aksaray', 1),
    ('Karaman', 1), ('Isparta', 1), ('Burdur', 1), ('Afyonkarahisar', 1), ('Uşak', 1),
    ('Kütahya', 1), ('Bilecik', 1), ('Yalova', 1), ('Kahramanmaraş', 1), ('Osmaniye', 1),
    ('Adıyaman', 1), ('Mardin', 1), ('Batman', 1), ('Siirt', 1), ('Bitlis', 1), ('Muş', 1),
    ('Ağrı', 1), ('Kars', 1), ('Ardahan', 1), ('Iğdır', 1), ('Erzincan', 1), ('Bayburt', 1),
    ('Gümüşhane', 1), ('Artvin', 1), ('Tunceli', 1), ('Bingöl', 1), ('Hakkari', 1), ('Şırnak', 1),
    ('Kilis', 1), ('Karabük', 1), ('Bartın', 1), ('Çankırı', 1), ('Kırıkkale', 1),
  ];
}

/// Değer etiketleri (TR / EN). İsim ve şehirler Türkiye temalı (Codex: dil ≠ ülke).
class KismetLabels {
  KismetLabels._();

  static String field(String f, bool en) => switch (f) {
        'name' => en ? 'Name' : 'İsim Soyisim',
        'job' => en ? 'Occupation' : 'Meslek',
        'city' => en ? 'Hometown' : 'Memleket',
        'hair' => en ? 'Hair colour' : 'Saç rengi',
        'eye' => en ? 'Eye colour' : 'Göz rengi',
        'height' => en ? 'Height' : 'Boy',
        _ => f,
      };

  static String hair(String k, bool en) => switch (k) {
        'siyah' => en ? 'Black' : 'Siyah',
        'koyu_kahve' => en ? 'Dark brown' : 'Koyu kahve',
        'kumral' => en ? 'Light brown' : 'Kumral',
        'sari' => en ? 'Blonde' : 'Sarı',
        'kizil' => en ? 'Red' : 'Kızıl',
        _ => k,
      };

  static String eye(String k, bool en) => switch (k) {
        'kahverengi' => en ? 'Brown' : 'Kahverengi',
        'ela' => en ? 'Hazel' : 'Ela',
        'yesil' => en ? 'Green' : 'Yeşil',
        'mavi' => en ? 'Blue' : 'Mavi',
        'gri' => en ? 'Grey' : 'Gri',
        _ => k,
      };

  static String job(String k, bool en) => switch (k) {
        'ogretmen' => en ? 'Teacher' : 'Öğretmen',
        'muhendis' => en ? 'Engineer' : 'Mühendis',
        'doktor' => en ? 'Doctor' : 'Doktor',
        'hemsire' => en ? 'Nurse' : 'Hemşire',
        'avukat' => en ? 'Lawyer' : 'Avukat',
        'mimar' => en ? 'Architect' : 'Mimar',
        'eczaci' => en ? 'Pharmacist' : 'Eczacı',
        'dishekimi' => en ? 'Dentist' : 'Diş hekimi',
        'yazilimci' => en ? 'Software developer' : 'Yazılımcı',
        'tasarimci' => en ? 'Designer' : 'Tasarımcı',
        'akademisyen' => en ? 'Academic' : 'Akademisyen',
        'pilot' => en ? 'Pilot' : 'Pilot',
        'bankaci' => en ? 'Banker' : 'Bankacı',
        'muhasebeci' => en ? 'Accountant' : 'Muhasebeci',
        'psikolog' => en ? 'Psychologist' : 'Psikolog',
        'veteriner' => en ? 'Veterinarian' : 'Veteriner',
        'fizyoterapist' => en ? 'Physiotherapist' : 'Fizyoterapist',
        'girisimci' => en ? 'Entrepreneur' : 'Girişimci',
        'esnaf' => en ? 'Shop owner' : 'Esnaf',
        'asci' => en ? 'Chef' : 'Aşçı',
        'fotografci' => en ? 'Photographer' : 'Fotoğrafçı',
        'muzisyen' => en ? 'Musician' : 'Müzisyen',
        'gazeteci' => en ? 'Journalist' : 'Gazeteci',
        'satis' => en ? 'Sales specialist' : 'Satış uzmanı',
        'polis' => en ? 'Police officer' : 'Polis',
        'kuafor' => en ? 'Hairdresser' : 'Kuaför',
        'diyetisyen' => en ? 'Dietitian' : 'Diyetisyen',
        'sporcu' => en ? 'Athlete' : 'Sporcu',
        'oyuncu' => en ? 'Actor' : 'Oyuncu',
        'ciftci' => en ? 'Farmer' : 'Çiftçi',
        'ogrenci' => en ? 'University student' : 'Üniversite öğrencisi',
        'emekli' => en ? 'Retired' : 'Emekli',
        _ => k,
      };
}
