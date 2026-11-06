// "Evim Neresi?" falı motoru (2026-11-05). Tasarım: Anıl'ın kuralları + DeepSeek + ChatGPT.
//
// Kullanıcıya özel TEK BİR HAYAT SENARYOSU bir kez üretilir ve saklanır:
//  • bu yıldan +50'ye kadar yaşa göre uzunlukta "ev segmentleri" (18-25: 2-3 yıl, 26-35: 3-5,
//    36-50: 5-8, 51-60: 6-12, 61+: 10-20); aynı yıl her zaman aynı sonucu verir;
//  • konum: ilk segment mevcut il %65 / komşu %20 / büyükşehir %15; sonraki taşınmalarda aynı il %60,
//    komşu %20, başka büyükşehir %15, sürpriz %5 (kamu 30-45 yaş: tayin eğilimi artar);
//    emeklilik (≥62): mevcut ilde kal %55, Ege/Akdeniz emekli ilçesi %25, memlekete dönüş %20;
//    50 yaş sonrası uzak doğu/sınır illeri ve köy önerisi düşer;
//  • yurt dışı çok nadir: yaş 20-50, vade ≥ bu yıl+5, senaryo başına %3 (öğrenci/özel sektör %5),
//    en fazla 1 segment (3-8 yıl), sonra Türkiye'ye dönüş;
//  • ev tipi / konut durumu (kiracı, ev sahibi, aile yanında) yaşa ve medeni hale göre; ev sahibi
//    olduktan sonra kiracıya dönüş nadir (%10); ikinci ev (yazlık) olasılığı;
//  • cinsiyet ve burç sonucu ETKİLEMEZ. KAÇINILANLAR: deprem, huzurevi, boşanma/eş kaybı,
//    zorunlu göç, "kesin ev sahibi olacaksın" garantisi. Eğlence amaçlıdır.
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'kismet_engine.dart' show KismetEngine;

// ── Veri ────────────────────────────────────────────────────────────────────
class EvimIlce {
  const EvimIlce(this.il, this.ilce, this.kiyi, this.km, this.profil);
  final String il;
  final String ilce;
  final String kiyi; // kenar | yakin | ic
  final int km; // denize yaklaşık mesafe
  final String profil; // merkez | banliyo | tatil | emekli | anadolu | koy
}

class EvimAbroad {
  const EvimAbroad(this.ulke, this.ulkeEn, this.sehir, this.sehirEn, this.w);
  final String ulke, ulkeEn, sehir, sehirEn;
  final int w;
}

class EvimNarr {
  const EvimNarr(this.tr, this.en);
  final String tr, en;
}

class EvimData {
  EvimData({
    required this.ilceler,
    required this.yurtdisi,
    required this.komsu,
    required this.anlati,
  }) {
    for (final i in ilceler) {
      (byIl[i.il] ??= []).add(i);
    }
    iller = byIl.keys.toList();
  }

  final List<EvimIlce> ilceler;
  final List<EvimAbroad> yurtdisi;
  final Map<String, List<String>> komsu;
  final Map<String, List<EvimNarr>> anlati;
  final Map<String, List<EvimIlce>> byIl = {};
  late final List<String> iller;

  static EvimData parse(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    return EvimData(
      ilceler: [
        for (final e in j['ilceler'] as List)
          EvimIlce(e['il'] as String, e['ilce'] as String, e['kiyi'] as String,
              (e['mesafe_km'] as num).toInt(), e['profil'] as String),
      ],
      yurtdisi: [
        for (final e in j['yurtdisi'] as List)
          EvimAbroad(e['ulke'] as String, (e['ulke_en'] ?? e['ulke']) as String, e['sehir'] as String,
              (e['sehir_en'] ?? e['sehir']) as String, ((e['w'] ?? 1) as num).toInt()),
      ],
      komsu: {
        for (final e in (j['komsu'] as Map).entries)
          e.key as String: [for (final x in e.value as List) x as String],
      },
      anlati: {
        for (final e in (j['anlati'] as Map).entries)
          e.key as String: [for (final x in e.value as List) EvimNarr(x['tr'] as String, x['en'] as String)],
      },
    );
  }

  /// Türkçe harfleri sadeleştirip küçültür ("İstanbul" → "istanbul").
  static String fold(String s) {
    const map = {'İ': 'i', 'I': 'i', 'ı': 'i', 'Ç': 'c', 'ç': 'c', 'Ğ': 'g', 'ğ': 'g', 'Ö': 'o', 'ö': 'o', 'Ş': 's', 'ş': 's', 'Ü': 'u', 'ü': 'u'};
    final b = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      b.write(map[ch] ?? ch.toLowerCase());
    }
    return b.toString().trim();
  }

  /// Serbest metni (doğum şehri vb.) 81 ilden birine eşler; bulunamazsa null.
  String? matchIl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final f = fold(raw);
    for (final il in iller) {
      if (fold(il) == f) return il;
    }
    for (final il in iller) {
      final fi = fold(il);
      if (f.startsWith(fi) || (f.length >= 4 && fi.startsWith(f))) return il;
    }
    for (final il in iller) {
      if (f.contains(fold(il))) return il;
    }
    return null;
  }
}

// ── Senaryo modeli ──────────────────────────────────────────────────────────
class EvimSegment {
  EvimSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.abroad,
    required this.il,
    required this.ilce,
    required this.kiyi,
    required this.km,
    required this.profil,
    required this.ulke,
    required this.ulkeEn,
    required this.sehir,
    required this.sehirEn,
    required this.tip,
    required this.durum,
    required this.kullanim,
    this.yazIl,
    this.yazIlce,
    this.yazKm,
    required this.narrPool,
    required this.narrIdx,
  });

  final String id;
  final int start; // dahil
  int end; // dahil (son segment ufuk uzayınca uzar)
  final bool abroad;
  final String il, ilce, kiyi, profil; // Türkiye
  final int km;
  final String ulke, ulkeEn, sehir, sehirEn; // yurt dışı
  final String tip; // apartman | site | mustakil | villa | koy_evi
  final String durum; // kiraci | sahip | aile
  final String kullanim; // surekli | yaz_kis | kislik
  final String? yazIl, yazIlce;
  final int? yazKm;
  final String narrPool;
  final int narrIdx;

  bool get hasYazlik => yazIl != null;
  int get length => end - start + 1;

  /// Kutu alanları (sırası ekrandaki sıradır).
  List<String> get fields => [
        'yer',
        'tip',
        if (!abroad) 'deniz',
        'durum',
        'kullanim',
        if (hasYazlik) 'yazlik',
      ];

  Map<String, dynamic> toJson() => {
        'id': id, 's': start, 'e': end, 'ab': abroad, 'il': il, 'ilce': ilce, 'ky': kiyi, 'km': km,
        'pf': profil, 'ul': ulke, 'ule': ulkeEn, 'sh': sehir, 'she': sehirEn, 'tip': tip, 'du': durum,
        'ku': kullanim, 'yi': yazIl, 'yc': yazIlce, 'yk': yazKm, 'np': narrPool, 'ni': narrIdx,
      };

  static EvimSegment fromJson(Map<String, dynamic> j) => EvimSegment(
        id: j['id'] as String,
        start: j['s'] as int,
        end: j['e'] as int,
        abroad: j['ab'] as bool,
        il: j['il'] as String,
        ilce: j['ilce'] as String,
        kiyi: j['ky'] as String,
        km: j['km'] as int,
        profil: j['pf'] as String,
        ulke: j['ul'] as String,
        ulkeEn: j['ule'] as String,
        sehir: j['sh'] as String,
        sehirEn: j['she'] as String,
        tip: j['tip'] as String,
        durum: j['du'] as String,
        kullanim: j['ku'] as String,
        yazIl: j['yi'] as String?,
        yazIlce: j['yc'] as String?,
        yazKm: j['yk'] as int?,
        narrPool: j['np'] as String,
        narrIdx: j['ni'] as int,
      );
}

class EvimTimeline {
  EvimTimeline({
    required this.seed,
    required this.baseYear,
    required this.signature,
    required this.segments,
    Map<String, Set<String>>? revealed,
  }) : revealed = revealed ?? {};

  static const schema = 2; // v2: vade havuzlu yer seçimi (Anıl, 2026-11-06) → eski senaryolar yeniden üretilir
  final int seed;
  final int baseYear;
  final String signature;
  final List<EvimSegment> segments;
  final Map<String, Set<String>> revealed; // segmentId → açılmış alanlar

  int get lastYear => segments.last.end;

  EvimSegment segmentFor(int year) {
    final y = year.clamp(baseYear, lastYear);
    for (final s in segments) {
      if (y >= s.start && y <= s.end) return s;
    }
    return segments.last;
  }

  bool isRevealed(String segId, String field) => revealed[segId]?.contains(field) ?? false;

  Map<String, dynamic> toJson() => {
        'v': schema, 'seed': seed, 'base': baseYear, 'sig': signature,
        'seg': [for (final s in segments) s.toJson()],
        'rev': {for (final e in revealed.entries) e.key: e.value.toList()},
      };

  static EvimTimeline? fromJson(Map<String, dynamic> j) {
    if (j['v'] != schema) return null;
    return EvimTimeline(
      seed: j['seed'] as int,
      baseYear: j['base'] as int,
      signature: j['sig'] as String,
      segments: [for (final s in j['seg'] as List) EvimSegment.fromJson(Map<String, dynamic>.from(s as Map))],
      revealed: {
        for (final e in ((j['rev'] as Map?) ?? {}).entries)
          e.key as String: {for (final f in e.value as List) f as String},
      },
    );
  }
}

// ── Motor ───────────────────────────────────────────────────────────────────
class EvimEngine {
  EvimEngine._();

  static const prefsKey = 'evim_v1';
  static const prefsIlKey = 'evim_il';
  static const prefsAskedKey = 'evim_il_asked';
  static const horizon = 50;

  /// 50 yaş sonrası önerilmeyen uzak doğu / sınır illeri.
  static const farIller = {
    'Van', 'Hakkari', 'Şırnak', 'Ağrı', 'Kars', 'Ardahan', 'Iğdır', 'Muş', 'Bitlis', 'Siirt',
    'Tunceli', 'Bingöl', 'Batman',
  };
  static const _metros = ['İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana', 'Konya', 'Gaziantep',
    'Kocaeli', 'Mersin', 'Kayseri', 'Eskişehir', 'Samsun'];
  static const _metroW = [6, 4, 4, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1];
  static const _bigThree = {'İstanbul', 'Ankara', 'İzmir'};

  /// Şehir büyüklüğü: 3 = üç büyük, 2 = büyükşehir, 1 = diğer.
  static int sizeOf(String il) => _bigThree.contains(il) ? 3 : _metros.contains(il) ? 2 : 1;

  static const _retireCoastIller = {'İzmir', 'Aydın', 'Muğla', 'Balıkesir', 'Antalya', 'Mersin', 'Çanakkale'};

  // ── Yükleme / kayıt ───────────────────────────────────────────────────────
  static String signatureOf(UserProfile p, String il) => '$il|${KismetEngine.maritalGroupOf(p)}';

  /// Kayıtlı ya da profilden çözülen il; yoksa null (kullanıcıya sorulmalı).
  static String? storedIl(SharedPreferences prefs, EvimData d) =>
      d.matchIl(prefs.getString(prefsIlKey));

  static Future<void> saveIl(SharedPreferences prefs, String il) async {
    await prefs.setString(prefsIlKey, il);
    await prefs.setBool(prefsAskedKey, true);
  }

  static Future<EvimTimeline> load(SharedPreferences prefs, EvimData d, UserProfile p, String il,
      {int? nowYear, int? seed}) async {
    final year = nowYear ?? DateTime.now().year;
    final sig = signatureOf(p, il);
    final raw = prefs.getString(prefsKey);
    if (raw != null) {
      try {
        final t = EvimTimeline.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        if (t != null && t.signature == sig) {
          if (t.lastYear < year + horizon) {
            t.segments.last.end = year + horizon; // mevcut yıllar DEĞİŞMEZ; yalnız son segment uzar
            await save(prefs, t);
          }
          return t;
        }
      } catch (_) {/* bozuk kayıt → yeniden üret */}
    }
    final t = generate(d, p, il, baseYear: year, seed: seed ?? Random().nextInt(1 << 31));
    await save(prefs, t);
    return t;
  }

  static Future<void> save(SharedPreferences prefs, EvimTimeline t) =>
      prefs.setString(prefsKey, jsonEncode(t.toJson()));

  static Future<void> reveal(SharedPreferences prefs, EvimTimeline t, String segId, String field) {
    (t.revealed[segId] ??= <String>{}).add(field);
    return save(prefs, t);
  }

  // ── Üretim ────────────────────────────────────────────────────────────────
  static int _range(Random r, int a, int b) => a + r.nextInt(b - a + 1);

  static int _lengthFor(Random r, int age) {
    if (age < 18) return _range(r, 4, 8);
    if (age <= 25) return _range(r, 2, 3);
    if (age <= 35) return _range(r, 3, 5);
    if (age <= 50) return _range(r, 5, 8);
    if (age <= 60) return _range(r, 6, 12);
    return _range(r, 10, 20);
  }

  static T _pickW<T>(Random r, List<T> items, List<num> w) {
    final sum = w.fold<num>(0, (a, b) => a + b);
    var x = r.nextDouble() * sum;
    for (var i = 0; i < items.length; i++) {
      x -= w[i];
      if (x < 0) return items[i];
    }
    return items.last;
  }

  static EvimTimeline generate(EvimData d, UserProfile p, String home,
      {required int baseYear, required int seed}) {
    final r = Random(seed);
    final group = KismetEngine.maritalGroupOf(p);
    final evli = group == 'evli';
    final job = p.job.toLowerCase();
    final kamu = job.contains('kamu');
    final ozel = job.contains('ozel') || job.contains('serbest') || job.contains('girisim');
    final ogrenci = job.contains('ogrenci');
    final userBirth = KismetEngine.birthYearOf(p, baseYear);
    final endYear = baseYear + horizon;
    final birthIl = d.matchIl(p.birthCity);

    // Yurt dışı: orta/uzun vadede olası (Anıl, 2026-11-06: "uzun vade için yurt dışı da çıksın");
    // en fazla 2 segment. Öğrenci/özel sektör biraz daha olası.
    var abroadCount = 0;
    final abroadBoost = (ogrenci || ozel) ? 1.3 : 1.0;

    final segs = <EvimSegment>[];
    var cursor = baseYear;
    var lastTrIl = home;
    EvimSegment? prev;
    var owner = false;

    while (cursor <= endYear) {
      final age = cursor - userBirth;
      final retire = age >= 62;

      // ── vade + yurt dışı kararı ─────────────────────────────────────────
      final offset = cursor - baseYear;
      final term = offset < 5 ? 0 : offset < 15 ? 1 : 2; // 0 yakın · 1 orta · 2 uzun
      var goAbroad = false;
      if (prev != null && !prev.abroad && abroadCount < 2 && offset >= 4 && age >= 20) {
        var pAbroad = term == 2 ? 0.30 : term == 1 ? 0.15 : 0.0; // uzun vadede daha olası
        pAbroad *= abroadBoost;
        if (age > 58) pAbroad *= 0.4; // yaşlıyken daha az, ama KAPALI değil
        if (r.nextDouble() < pAbroad) goAbroad = true;
      }

      // Yurt dışı uzunluğu kalan ufukla sınırlı (negatif uzunluk bug'ı: eski cap yaş>60'ta eksiydi).
      var len = goAbroad ? min(_range(r, 3, 8), endYear - cursor + 1) : _lengthFor(r, age);
      final end = min(endYear, cursor + len - 1);
      len = end - cursor + 1;

      EvimSegment seg;
      if (goAbroad) {
        abroadCount++;
        final a = _pickW(r, d.yurtdisi, [for (final x in d.yurtdisi) x.w]);
        final dur = r.nextDouble() < 0.85 ? 'kiraci' : 'sahip';
        final tip = _pickW(r, ['apartman', 'site', 'mustakil'], [80, 15, 5]);
        final pool = 'yurtdisi';
        seg = EvimSegment(
          id: 's${segs.length}', start: cursor, end: end, abroad: true, il: '', ilce: '', kiyi: 'ic',
          km: 999, profil: 'merkez', ulke: a.ulke, ulkeEn: a.ulkeEn, sehir: a.sehir, sehirEn: a.sehirEn,
          tip: tip, durum: dur, kullanim: 'surekli', narrPool: pool,
          narrIdx: r.nextInt(d.anlati[pool]!.length),
        );
      } else {
        // ── vade havuzlu yer seçimi (Anıl, 2026-11-06) ─────────────────────
        //  yakın (0): mevcut şehir/çevre · orta (1): kıyı + başka metropol · uzun (2): Ege/Akdeniz kıyı.
        //  İlk segmentten SONRA mevcut şehri (home) dışla → İstanbul/Ankara döngüsü biter, çeşitlilik + wow.
        final first = prev == null;
        final afterAbroad = prev?.abroad == true;
        final prevIl = afterAbroad ? home : lastTrIl;
        final coastRetire = retire; // emeklilik anlatısı için
        final ilce = _pickLocation(r, d, term: term, first: first, home: home,
            prevIl: prevIl, prevIlce: (first || afterAbroad) ? null : prev.ilce,
            birthIl: birthIl, age: age, retire: retire, evli: evli, kamu: kamu);

        // ── konut durumu ──────────────────────────────────────────────────
        final dur = _durum(r, age, evli, owner);
        owner = dur == 'sahip';

        // ── ev tipi ───────────────────────────────────────────────────────
        final tip = _tip(r, ilce, age, evli);

        // ── kullanım ──────────────────────────────────────────────────────
        var kul = 'surekli';
        if (ilce.profil == 'tatil') {
          kul = 'yaz_kis';
        } else if (coastRetire && r.nextDouble() < 0.30) {
          kul = 'kislik';
        }

        // ── yazlık (ikinci ev) ────────────────────────────────────────────
        String? yi, yc;
        int? yk;
        final coastalMain = ilce.kiyi != 'ic' && (ilce.profil == 'tatil' || ilce.profil == 'emekli');
        final yazP = (age >= 40 && age <= 60 && evli && ozel) ? 0.15 : 0.06;
        if (age >= 30 && dur != 'aile' && !coastalMain && r.nextDouble() < yazP) {
          final near = {ilce.il, ...?d.komsu[ilce.il]};
          final cands = d.ilceler.where((e) => e.kiyi == 'kenar' && (e.profil == 'tatil' || e.profil == 'emekli') &&
              !(e.il == ilce.il && e.ilce == ilce.ilce)).toList();
          final y = _pickW(r, cands, [for (final e in cands) near.contains(e.il) ? 4 : 1]);
          yi = y.il;
          yc = y.ilce;
          yk = y.km;
        }

        // ── anlatı ────────────────────────────────────────────────────────
        final String pool;
        if (retire) {
          pool = 'emekli';
        } else if (ilce.profil == 'tatil' || ilce.profil == 'emekli' || ilce.profil == 'koy' ||
            tip == 'mustakil' || tip == 'villa' || tip == 'koy_evi') {
          pool = 'sakin';
        } else if ((ilce.profil == 'merkez' || ilce.profil == 'banliyo') && (tip == 'apartman' || tip == 'site')) {
          pool = 'sehir';
        } else {
          pool = 'genel';
        }
        seg = EvimSegment(
          id: 's${segs.length}', start: cursor, end: end, abroad: false, il: ilce.il, ilce: ilce.ilce,
          kiyi: ilce.kiyi, km: ilce.km, profil: ilce.profil, ulke: '', ulkeEn: '', sehir: '', sehirEn: '',
          tip: tip, durum: dur, kullanim: kul, yazIl: yi, yazIlce: yc, yazKm: yk, narrPool: pool,
          narrIdx: r.nextInt(d.anlati[pool]!.length),
        );
        lastTrIl = ilce.il;
      }
      segs.add(seg);
      prev = seg;
      cursor = end + 1;
    }
    return EvimTimeline(seed: seed, baseYear: baseYear, signature: signatureOf(p, home), segments: segs);
  }

  /// Vade havuzlu yer seçimi (Anıl, 2026-11-06). term: 0 yakın · 1 orta · 2 uzun.
  /// İlk segment gerçekçi (mevcut şehir); sonra orta/uzun vadede mevcut şehir (home) DIŞLANIR →
  /// İstanbul/Ankara döngüsü biter, kıyı/yurt dışı/çeşitlilik gelir.
  static EvimIlce _pickLocation(Random r, EvimData d, {
    required int term, required bool first, required String home, required String prevIl,
    String? prevIlce, String? birthIl, required int age, required bool retire,
    required bool evli, required bool kamu,
  }) {
    if (first) return _pickIlce(r, d, home, age: age, evli: evli, exclude: null);
    if (retire) {
      if (r.nextDouble() < 0.72) return _pickCoastal(r, d, excludeIl: null);
      if (birthIl != null && !_bigThree.contains(birthIl)) return _pickIlce(r, d, birthIl, age: age, evli: evli);
      return _pickIlce(r, d, prevIl, age: age, evli: evli, exclude: prevIlce);
    }
    switch (term) {
      case 0: // yakın: mevcut çevre (kamu + 28-45 yaş → tayin ile daha çok taşınma)
        final w0 = (kamu && age >= 28 && age <= 45) ? const [44, 26, 30] : const [62, 20, 18];
        final c = _pickW(r, [0, 1, 2], w0);
        final il = c == 0 ? prevIl : c == 1 ? _neighbor(r, d, prevIl, age) : _otherMetro(r, {prevIl});
        return _pickIlce(r, d, il, age: age, evli: evli, exclude: il == prevIl ? prevIlce : null);
      case 1: // orta: kıyı + başka metropol — mevcut şehir dışla
        final c = _pickW(r, [0, 1, 2], const [50, 35, 15]);
        if (c == 0) return _pickCoastal(r, d, excludeIl: home);
        if (c == 1) return _pickIlce(r, d, _otherMetro(r, {home, prevIl}), age: age, evli: evli);
        return _pickIlce(r, d, _neighbor(r, d, prevIl, age), age: age, evli: evli);
      default: // uzun: Ege/Akdeniz kıyı ağırlıklı — mevcut şehir dışla
        final c = _pickW(r, [0, 1], const [65, 35]);
        if (c == 0) return _pickCoastal(r, d, excludeIl: home);
        return _pickIlce(r, d, _otherMetro(r, {home, prevIl}), age: age, evli: evli);
    }
  }

  /// Ege/Akdeniz kıyı güzel ilçeler (Bodrum, Çeşme, Datça, Fethiye…). [excludeIl] varsa o il hariç.
  static EvimIlce _pickCoastal(Random r, EvimData d, {String? excludeIl}) {
    var l = d.ilceler
        .where((e) => _retireCoastIller.contains(e.il) && e.kiyi == 'kenar' &&
            (e.profil == 'tatil' || e.profil == 'emekli'))
        .toList();
    if (excludeIl != null) {
      final f = l.where((e) => e.il != excludeIl).toList();
      if (f.isNotEmpty) l = f;
    }
    if (l.isEmpty) l = d.ilceler.where((e) => e.kiyi == 'kenar').toList();
    if (l.isEmpty) return d.ilceler.first;
    return _pickW(r, l, [for (final e in l) e.profil == 'tatil' ? 3.0 : 2.0]);
  }

  static String _neighbor(Random r, EvimData d, String il, int age) {
    final n = (d.komsu[il] ?? const <String>[])
        .where((x) => age < 50 || !farIller.contains(x))
        .toList();
    return n.isEmpty ? il : n[r.nextInt(n.length)];
  }

  static String _otherMetro(Random r, Set<String> exclude) {
    final idx = [for (var i = 0; i < _metros.length; i++) if (!exclude.contains(_metros[i])) i];
    if (idx.isEmpty) return _metros.first;
    return _metros[_pickW(r, idx, [for (final i in idx) _metroW[i].toDouble()])];
  }

  static EvimIlce _pickIlce(Random r, EvimData d, String il,
      {required int age, required bool evli, String? exclude}) {
    var list = d.byIl[il]!;
    if (exclude != null && list.length > 1) {
      list = list.where((e) => e.ilce != exclude).toList();
    }
    double w(EvimIlce e) {
      var x = switch (e.profil) {
        'merkez' => 5.0, 'banliyo' => 4.0, 'anadolu' => 3.0, 'tatil' => 1.5, 'emekli' => 0.4, _ => 1.0,
      };
      if (age >= 50) {
        if (e.profil == 'koy') x *= 0.3;
        if (e.profil == 'tatil') x *= 1.3;
      }
      if (age < 35) {
        if (e.profil == 'tatil' || e.profil == 'koy') x *= 0.4;
        if (e.profil == 'merkez') x *= 1.5;
      }
      if (evli && e.profil == 'banliyo') x *= 1.3;
      return x;
    }

    return _pickW(r, list, [for (final e in list) w(e)]);
  }

  static String _durum(Random r, int age, bool evli, bool owner) {
    if (owner) return r.nextDouble() < 0.10 ? 'kiraci' : 'sahip';
    double aile, sahip;
    if (age < 25) {
      aile = 0.40;
      sahip = 0.10;
    } else {
      aile = age < 30 ? 0.12 : age < 35 ? 0.05 : 0.02;
      sahip = age < 30 ? 0.22 : age < 35 ? 0.35 : age < 40 ? 0.45 : age < 46 ? 0.52 : age < 55 ? 0.62 : 0.70;
      if (evli) sahip = min(0.78, sahip + 0.08);
    }
    final x = r.nextDouble();
    if (x < aile) return 'aile';
    if (x < aile + sahip) return 'sahip';
    return 'kiraci';
  }

  static String _tip(Random r, EvimIlce e, int age, bool evli) {
    final w = <String, double>{'apartman': 55, 'site': 30, 'mustakil': 10, 'villa': 3, 'koy_evi': 0};
    if (e.profil == 'koy') {
      w['koy_evi'] = 25;
      w['mustakil'] = 30;
      w['apartman'] = 20;
      if (age >= 50) w['koy_evi'] = 8;
    }
    if (e.profil == 'merkez') {
      w['mustakil'] = w['mustakil']! * 0.3;
      w['villa'] = w['villa']! * 0.3;
    }
    if (e.profil == 'tatil' || e.profil == 'emekli') {
      w['site'] = w['site']! * 1.5;
      w['mustakil'] = w['mustakil']! * 1.8;
      w['villa'] = w['villa']! * 2;
    }
    if (evli) {
      w['site'] = w['site']! * 1.4;
      w['mustakil'] = w['mustakil']! * 1.8;
    } else if (age < 35) {
      w['apartman'] = w['apartman']! * 1.6;
      w['site'] = w['site']! * 0.6;
      w['mustakil'] = w['mustakil']! * 0.3;
      w['villa'] = w['villa']! * 0.1;
    }
    if (age < 30) w['villa'] = 0;
    final keys = w.keys.toList();
    return _pickW(r, keys, [for (final k in keys) w[k]!]);
  }
}

// ── Etiketler (TR / EN) ───────────────────────────────────────────────────────
class EvimLabels {
  EvimLabels._();

  static String field(String f, bool en) => switch (f) {
        'yer' => en ? 'Place' : 'Yer',
        'tip' => en ? 'Home type' : 'Ev tipi',
        'deniz' => en ? 'Sea distance' : 'Denize mesafe',
        'durum' => en ? 'Status' : 'Durum',
        'kullanim' => en ? 'Use' : 'Kullanım',
        'yazlik' => en ? 'Summer home' : 'Yazlığın',
        _ => f,
      };

  static String tip(String k, bool en) => switch (k) {
        'apartman' => en ? 'Apartment' : 'Apartman dairesi',
        'site' => en ? 'Flat in a residential complex' : 'Site içinde daire',
        'mustakil' => en ? 'Detached house with garden' : 'Bahçeli müstakil ev',
        'villa' => en ? 'Villa' : 'Villa',
        'koy_evi' => en ? 'Village house' : 'Köy evi',
        _ => k,
      };

  static String durum(String k, bool en) => switch (k) {
        'kiraci' => en ? 'Tenant' : 'Kiracı',
        'sahip' => en ? 'Homeowner' : 'Ev sahibi',
        'aile' => en ? 'Living with family' : 'Aile yanında',
        _ => k,
      };

  static String kullanim(String k, bool en) => switch (k) {
        'yaz_kis' => en ? 'Summer & winter' : 'Yaz-kış',
        'kislik' => en ? 'Winter home' : 'Kışlık',
        _ => en ? 'Year-round residence' : 'Sürekli oturma',
      };

  /// Denize mesafe kategorisi anahtarı (km yerine).
  static String seaKey(int km) {
    if (km <= 2) return 'cok_yakin';
    if (km <= 10) return 'yakin';
    if (km <= 30) return 'kisa_yol';
    if (km <= 100) return 'biraz_uzak';
    return 'uzak';
  }

  static String sea(int km, bool en) => switch (seaKey(km)) {
        'cok_yakin' => en ? 'Very close to the sea' : 'Denize çok yakın',
        'yakin' => en ? 'Close to the sea' : 'Denize yakın',
        'kisa_yol' => en ? 'A short trip to the sea' : 'Denize kısa bir yolculuk',
        'biraz_uzak' => en ? 'The sea is a bit far' : 'Deniz biraz uzakta',
        _ => en ? 'Far from the sea, inland' : 'Denizden uzak, iç kesimlerde',
      };

  static String place(EvimSegment s, bool en) =>
      s.abroad ? '${en ? s.sehirEn : s.sehir}, ${en ? s.ulkeEn : s.ulke}' : '${s.ilce}, ${s.il}';

  static String summerHome(EvimSegment s, bool en) =>
      '${s.yazIlce}, ${s.yazIl} (${sea(s.yazKm ?? 1, en).toLowerCase()})';
}
