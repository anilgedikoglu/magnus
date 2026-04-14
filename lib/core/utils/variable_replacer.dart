// ── AI NOTU: variable_replacer.dart ──────────────────────────────────────────
// Tüm içerik metinlerindeki {{placeholder}} ifadelerini gerçek kullanıcı
// verisine çeviren merkezi motor. Her fal/motivasyon/olumlama/tarot ekranında
// metni göstermeden önce mutlaka çağrılır:
//   VariableReplacer.replace(metin, profile.toVariableMap())
//
// Desteklenen placeholder'lar (tam liste):
//   {{isim}}             → kullanıcı adı
//   {{isim hanim/bey}}  → "Ahmet Bey" (erkek) / "Ayşe Hanım" (kadın)
//   {{isime}}        → yönelme eki  ("Ahmet'e" / "Ayşe'ye")
//   {{isimi}}        → belirtme eki ("Ahmet'i" / "Ayşe'yi")
//   {{isimden}}      → uzaklaşma    ("Ahmet'ten" / "Ayşe'den")
//   {{isimcigim}}    → küçültme     ("Ahmetciğim")
//   {{harf}}         → ismin ilk harfi
//   {{yas}}          → yaş (sayı)
//   {{meslek}}       → meslek Türkçe
//   {{medeni_durum}} → medeni durum
//   {{cinsiyet}}     → 'erkek'/'kadin'/'lgbt'
//   {{burc}}         → burç adı
//   {{dogum gunu}}   → kullanıcının doğduğu gün (sayı, örn. 14)
//   {{dogum ayi}}    → kullanıcının doğduğu ay  (sayı, örn. 10)
//   {{dogum yili}}   → kullanıcının doğduğu yıl (sayı, örn. 1983)
//   {{gun}}          → bugünün adı (Pazartesi vb.)
//   {{gun_0}}        → ayın günü (sayı)
//   {{gun_+N}}       → N gün sonraki haftanın gün adı ({{gun_+2}} → Cuma)
//   {{gunsayi_0}}    → bugünün ayın kaçı (sayı); {{gunsayi_3}} → bugün+3; {{gunsayi_-3}} → bugün-3
//   {{ay}}           → ay adı
//   {{ay_0}}         → ay adı (alias)
//   {{ay_+N}}        → N ay sonraki ay adı ({{ay_+1}} → Mayıs)
//   {{yil_0}}        → bu yıl (sayı, örn. 2026); {{yil_-1}} → 2025; {{yil_2}} → 2028
//   {{saat}}             → saat HH:MM
//   {{saat, A | B | C | D | E}} → saat dilimine göre seçim:
//       A=sabah(06-11), B=öğle(12-13), C=ikindi(14-17), D=akşam(18-20), E=gece(21-05)
//   {{sayi,min,max}}       → rastgele sayı [min,max] (her tekrarda bağımsız)
//   {{sabit_sayi,min,max}} → rastgele sayı [min,max] (aynı metin içinde hep aynı değer)
//   {{randomtarih, min, max}} → bugüne min–max arası rastgele gün eklenmiş Türkçe tarih
//                               örn. {{randomtarih, 15, 50}} → "17 Ocak"
//   {{rastgeleburc}} → rastgele burç adı
//   {{saniye}}       → geçerli saniye
//   {{kullanici sehri}} → doğum şehri
//   {{kelime, A | B | C}} → A/B/C arasından her render'da rastgele biri
//   {{data, cinsiyet=erkek, MetinA | cinsiyet=kadin, MetinB | cinsiyet=lgbt, MetinC}}
//                    → koşullu metin (cinsiyet değerine göre seçim)
//   {{fiziki}}           → rastgele fiziksel özellik (150-madde havuz)
//   {{kadinisim}}        → rastgele Türkçe kadın adı (100-madde havuz)
//   {{erkekisim}}        → rastgele Türkçe erkek adı (100-madde havuz)
//   {{havadurumu sicaklik}} → "değişken sıcaklıklarda" vb. rastgele ifade
//   {{tutulantakim}}     → "milli takımlı" (sabit)
//   {{xgundur}}          → kullanıcı adından türetilmiş kararlı gün sayısı (60–359)
//   {{kac gun tanisma}}  → {{xgundur}} ile aynı değer
//   {{nereli}}           → şehir adı + sıfat eki ("İstanbul'lu", "Ankara'lı")
//
// <sprite=N> etiketleri emoji'ye dönüştürülür (bilinmeyenler kaldırılır):
//   <sprite=0>→🙂  <sprite=5>→😄  <sprite=7>→😉  <sprite=10>→☺️
//   <sprite=23>→😎  <sprite=73>→👊  <sprite=79>→🙏
//
// Türkçe sesli uyum kuralları user_profile.dart'taki static metodlarda.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math';
import 'package:intl/intl.dart';

/// Replaces {{variable}} placeholders in text with actual values.
/// Direct equivalent of Unity's ChatVariables.OrtakButonlar().
class VariableReplacer {
  VariableReplacer._();

  static final Random _rng = Random();

  /// Main replacement function. Takes template text and a variable map,
  /// returns the fully resolved string.
  static String replace(String template, Map<String, String> variables) {
    final now = DateTime.now();
    final allVars = {
      ...variables,
      ..._timeVariables(now),
    };

    String result = template;

    // 0. Ham metin temizliği (Python extract artefaktları)
    result = _cleanRawText(result);

    // 1. <sprite=N> → emoji (bilinmeyenler kaldırılır)
    result = _replaceSprites(result);

    // 2. Koşullu metin: {{data, cinsiyet=erkek, X | cinsiyet=kadın, Y | ...}}
    result = _replaceConditional(result, allVars);

    // 2b. {{isim hanim/bey}} → "Ahmet Bey" / "Ayşe Hanım"
    result = _replaceIsimHanimBey(result, allVars);

    // 2c. {{saat, A | B | C | D | E}} — saat dilimine göre seçim
    result = _replaceSaatVakti(result, now);

    // 3. {{kelime, A | B | C}} — rastgele seçim
    result = _replaceRandomWord(result);

    // 4. {{ay_+N}} / {{gun_+N}} — kaydırmalı zaman (gün adı / ay adı)
    result = _replaceOffsetTime(result, now);

    // 4b. {{gunsayi_N}} — ayın gün sayısı ± offset (sayı olarak)
    result = _replaceOffsetDayNumber(result, now);

    // 4c. {{yil_N}} — yıl ± offset (sayı olarak)
    result = _replaceOffsetYear(result, now);

    // 4d. Önceden hesaplanan dinamik değişkenler — step 5 forEach'ten ÖNCE
    //     inject edilmeli; yoksa toVariableMap()'deki boş '' değerleri bunları siler.
    final kayitSeed = variables['isim'] ?? '';
    allVars['fiziki']              = _randomFiziki();
    allVars['kadinisim']           = _randomKadinIsim();
    allVars['erkekisim']           = _randomErkekIsim();
    allVars['havadurumu sicaklik'] = _randomHavaDurumu();
    allVars['tutulantakim']        = 'milli takımlı';
    allVars['xgundur']             = _seededDayCount(kayitSeed).toString();
    allVars['kac gun tanisma']     = _seededDayCount(kayitSeed).toString();
    allVars['nereli']              = _nereli(variables['kullanici sehri'] ?? '');

    // 5. Sade değişken ikameleri
    allVars.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });

    // 6a. {{sabit_sayi,min,max}} — aynı aralıktaki TÜM tekrarlar aynı sayıyı alır
    result = _replaceStableNumbers(result);

    // 6b. {{sayi,min,max}} — her seferinde bağımsız rastgele sayı
    result = _replaceRandomNumbers(result);

    // 6c. {{randomtarih, min, max}} — bugüne rastgele gün eklenmiş Türkçe tarih
    result = _replaceRandomTarih(result, now);

    // 7. {{rastgeleburc}} — rastgele burç
    result = result.replaceAll('{{rastgeleburc}}', _randomBurc());

    // 7b. {{burc_*}} catch-all — süslü parantez içinde "burc" geçen her kalıp
    //     (allVars üzerinden zaten eşleşmeyenler için güvenlik ağı)
    final burcDegeri = allVars['burc'] ?? '';
    if (burcDegeri.isNotEmpty) {
      result = result.replaceAllMapped(
        RegExp(r'\{\{[^}]*burc[^}]*\}\}'),
        (_) => burcDegeri.isNotEmpty
            ? burcDegeri[0].toUpperCase() + burcDegeri.substring(1)
            : burcDegeri,
      );
    }

    // 8. {{saniye}} — anlık saniye
    result = result.replaceAll('{{saniye}}', now.second.toString());

    // 9. Alias'lar ve türetilmiş pattern'ler
    result = _replaceAliases(result, allVars, now);

    // 10. {{kelimecins, erkek_X|kadin_Y|lgbt_Z}} — cinsiyete göre kelime
    result = _replaceKelimeCins(result, allVars);

    // 11. {{medenidurum, evli_X|bekar_Y|...}} — medeni duruma göre kelime
    result = _replaceMedeniDurum(result, allVars);

    // 12. {{sabitkelime, A|B|C}} / {{sabit_kelime, A|B|C}} — kararlı rastgele kelime
    result = _replaceSabitKelime(result, allVars);

    // 13. {{yas_N}} / {{yas_+N}} / {{yas_-N}} / {{yaş,N}} — yaş ± offset
    result = _replaceYasOffset(result, allVars);

    // 14. {{mevsim_N}} / {{mevsim,N}} — mevsim ± offset
    result = _replaceMevsimOffset(result, now);

    // 15. Kalan bilinmeyen {{...}} kalıplarını sil (boş bırak)
    result = result.replaceAllMapped(
      RegExp(r'\{\{[^}]+\}\}'),
      (_) => '',
    );

    return result;
  }

  // ── Koşullu metin ──────────────────────────────────────────────────────────
  // Örnek: {{data, cinsiyet=erkek, beyler | cinsiyet=kadın, hanımlar | cinsiyet=lgbt, bireyler}}

  static String _replaceConditional(String text, Map<String, String> vars) {
    // data ile başlayan tüm {{...}} bloklarını yakala
    final pattern = RegExp(r'\{\{data,([^}]*)\}\}');
    return text.replaceAllMapped(pattern, (match) {
      final body = match.group(1)!;
      final cinsiyet = (vars['cinsiyet'] ?? '').toLowerCase().trim();

      // "cinsiyet=erkek, Metin | cinsiyet=kadın, Metin2 | ..." parçalarını ayır
      final parts = body.split('|');
      String? fallback;
      for (final part in parts) {
        final trimmed = part.trim();
        final eq = trimmed.indexOf('=');
        if (eq < 0) continue;
        final afterEq = trimmed.substring(eq + 1); // "erkek, Metin"
        final comma = afterEq.indexOf(',');
        if (comma < 0) continue;
        final val = afterEq.substring(0, comma).trim().toLowerCase();
        final metin = afterEq.substring(comma + 1).trim();
        fallback ??= metin; // ilk seçenek yedek
        if (val == cinsiyet) return metin;
      }
      // Eşleşme yoksa ilk seçeneği döndür
      return fallback ?? '';
    });
  }

  // ── {{isim hanim/bey}} ────────────────────────────────────────────────────
  // Kişinin adını ve cinsiyetine göre "Hanım" veya "Bey" unvanını birleştirir.
  // Erkek → "[İsim] Bey", Kadın → "[İsim] Hanım", diğer → sadece isim.

  static String _replaceIsimHanimBey(String text, Map<String, String> vars) {
    if (!text.contains('{{isim hanim/bey}}')) return text;
    final isim = vars['isim'] ?? '';
    final cinsiyet = (vars['cinsiyet'] ?? '').toLowerCase().trim();
    final String unvanli;
    if (cinsiyet == 'kadin' || cinsiyet == 'kadın') {
      unvanli = '$isim Hanım'.trim();
    } else if (cinsiyet == 'erkek') {
      unvanli = '$isim Bey'.trim();
    } else {
      unvanli = isim; // lgbt / bilinmiyor → sadece isim
    }
    return text.replaceAll('{{isim hanim/bey}}', unvanli);
  }

  // ── {{saat, A | B | C | D | E}} ──────────────────────────────────────────
  // 5 seçenekli saat dilimi seçimi:
  //   index 0 → sabah    06:00–11:59
  //   index 1 → öğle     12:00–13:59
  //   index 2 → ikindi   14:00–17:59
  //   index 3 → akşam    18:00–20:59
  //   index 4 → gece     21:00–05:59
  // 5'ten az seçenek varsa son seçenek yedek olarak kullanılır.

  static String _replaceSaatVakti(String text, DateTime now) {
    final pattern = RegExp(r'\{\{saat,([^}]+)\}\}');
    return text.replaceAllMapped(pattern, (match) {
      final options = match
          .group(1)!
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (options.isEmpty) return '';
      final index = _saatDilimiIndex(now.hour).clamp(0, options.length - 1);
      return options[index];
    });
  }

  /// 0=sabah, 1=öğle, 2=ikindi, 3=akşam, 4=gece
  static int _saatDilimiIndex(int hour) {
    if (hour >= 6  && hour < 12) return 0; // sabah
    if (hour >= 12 && hour < 14) return 1; // öğle
    if (hour >= 14 && hour < 18) return 2; // ikindi
    if (hour >= 18 && hour < 21) return 3; // akşam
    return 4;                               // gece (21–05)
  }

  // ── Alias'lar ve türetilmiş pattern'ler ──────────────────────────────────────
  // Vurgulu harf varyantları, boşluklu/tireli yazım farkları ve
  // UserProfile'dan türetilen ek değişkenler burada çözümlenir.

  static String _replaceAliases(
      String text, Map<String, String> vars, DateTime now) {
    final isim    = vars['isim']    ?? '';
    final soyisim = vars['soyisim'] ?? '';
    final yas     = int.tryParse(vars['yas'] ?? '0') ?? 0;
    final sehir   = vars['kullanici sehri'] ?? '';

    // — Basit alias'lar ——————————————————————————————————————————————————
    text = text.replaceAll('{{isimciğim}}',   vars['isimcigim'] ?? '');
    text = text.replaceAll('{{isim hanım/bey}}', _resolveHanimBey(isim, vars));
    text = text.replaceAll('{{yükselen}}',    vars['yukselen'] ?? '');
    text = text.replaceAll('{{soiyisim}}',    soyisim); // yazım hatası
    text = text.replaceAll('{{harfi}}',       vars['harf'] ?? '');
    text = text.replaceAll('{{tam saat}}',    vars['tam_saat'] ?? '');
    text = text.replaceAll('{{dogumyili}}',   vars['dogum yili'] ?? '');
    text = text.replaceAll('{{dogumayi}}',    vars['dogum ayi']  ?? '');
    text = text.replaceAll('{{dogum ayi yazi}}',
        _monthTr(int.tryParse(vars['dogum ayi'] ?? '0') ?? 0));
    text = text.replaceAll('{{aysayi_0}}',    now.month.toString());
    text = text.replaceAll('{{altsatır}}',    '\n');
    text = text.replaceAll('{{sabit_harf}}',  vars['harf'] ?? '');
    text = text.replaceAll('{{sabitharf}}',   vars['harf'] ?? '');
    text = text.replaceAll('{{sessizharf}}',  _randomConsonant(isim));
    text = text.replaceAll('{{sprite=34}}',   '');

    // — Şehir lokasyon hâli (İstanbul→"İstanbul'da") ————————————————————
    if (sehir.isNotEmpty) {
      text = text.replaceAll('{{kullanici sehrinde}}', _locative(sehir));
    } else {
      text = text.replaceAll('{{kullanici sehrinde}}', '');
    }

    // — İsim harf parçaları ——————————————————————————————————————————————
    text = text.replaceAll('{{isimilk}}',  isim.isNotEmpty ? isim[0].toUpperCase() : '');
    text = text.replaceAll('{{isimiki}}',  isim.length > 1 ? isim[1].toUpperCase() : '');
    text = text.replaceAll('{{isimson}}',  isim.isNotEmpty ? isim[isim.length-1].toUpperCase() : '');
    text = text.replaceAll('{{soyisimilk}}', soyisim.isNotEmpty ? soyisim[0].toUpperCase() : '');
    text = text.replaceAll('{{soyisimiki}}', soyisim.length > 1 ? soyisim[1].toUpperCase() : '');
    text = text.replaceAll('{{soyisimson}}', soyisim.isNotEmpty ? soyisim[soyisim.length-1].toUpperCase() : '');

    // — Geçen/gelecek/şimdiki ay adı ————————————————————————————————————
    final prevMonth = ((now.month - 2 + 12) % 12) + 1;
    final nextMonth = (now.month % 12) + 1;
    for (final k in ['gecen_ay', 'gecenay']) {
      text = text.replaceAll('{{$k}}', _monthTr(prevMonth));
    }
    for (final k in ['gelecek_ay', 'gelecekay']) {
      text = text.replaceAll('{{$k}}', _monthTr(nextMonth));
    }
    for (final k in ['simdiki_ay', 'simdikiay']) {
      text = text.replaceAll('{{$k}}', _monthTr(now.month));
    }

    // — Vurgulu harf notasyonu: {{gün,N}}, {{yıl,N}}, {{ay,N}} ————————
    // {{gün,N}} → N gün sonraki haftanın gün adı
    text = text.replaceAllMapped(RegExp(r'\{\{gün,([+-]?\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      final day = ((now.weekday - 1 + offset) % 7 + 7) % 7 + 1;
      return _dayOfWeekTr(day);
    });
    // {{yıl,N}} → yıl ± offset
    text = text.replaceAllMapped(RegExp(r'\{\{yıl,([+-]?\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      return (now.year + offset).toString();
    });
    // {{ay,N}} → ay adı ± offset
    text = text.replaceAllMapped(RegExp(r'\{\{ay,([+-]?\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      final month = ((now.month - 1 + offset) % 12 + 12) % 12 + 1;
      return _monthTr(month);
    });
    // {{yaş,N}} / {{yaş,+N}} / {{yaş,-N}} → yaş ± offset
    text = text.replaceAllMapped(RegExp(r'\{\{yaş,([+-]?\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      return (yas + offset).toString();
    });

    // — Saat kac yazi (saatleri yazı ile, sadece tam saat) ——————————————
    text = text.replaceAll('{{saat kac yazi}}', _saatYazi(now.hour));

    return text;
  }

  // — Hanım/Bey yardımcısı ——————————————————————————————————————————————————
  static String _resolveHanimBey(String isim, Map<String, String> vars) {
    final cinsiyet = (vars['cinsiyet'] ?? '').toLowerCase().trim();
    if (cinsiyet == 'kadin' || cinsiyet == 'kadın') return '$isim Hanım'.trim();
    if (cinsiyet == 'erkek') return '$isim Bey'.trim();
    return isim;
  }

  // — Şehir lokasyon hâli (Türkçe -da/-de/-ta/-te) ————————————————————————
  static String _locative(String sehir) {
    if (sehir.isEmpty) return '';
    const frontVowels = {'e', 'i', 'ö', 'ü'};
    const backVowels  = {'a', 'ı', 'o', 'u'};
    const voiceless   = {'ç', 'f', 'h', 'k', 'p', 's', 'ş', 't'};
    bool front = true;
    for (int i = sehir.length - 1; i >= 0; i--) {
      final c = sehir[i].toLowerCase();
      if (frontVowels.contains(c)) { front = true; break; }
      if (backVowels.contains(c))  { front = false; break; }
    }
    final lastChar = sehir[sehir.length - 1].toLowerCase();
    final hardEnd  = voiceless.contains(lastChar);
    final ek = front ? (hardEnd ? "'te" : "'de") : (hardEnd ? "'ta" : "'da");
    return "$sehir$ek";
  }

  // — Saat yazı (0-23 → Türkçe) ————————————————————————————————————————————
  static const _saatler = [
    'gece yarısı', 'biri', 'ikiyi', 'üçü', 'dördü', 'beşi',
    'altıyı', 'yediyi', 'sekizi', 'dokuzu', 'onu', 'on biri',
    'öğleni', 'biri', 'ikiyi', 'üçü', 'dördü', 'beşi',
    'altıyı', 'yediyi', 'sekizi', 'dokuzu', 'onu', 'on biri',
  ];
  static String _saatYazi(int hour) =>
      _saatler.length > hour ? _saatler[hour] : hour.toString();

  // — Rastgele kadın ismi (100 Türkçe kadın adı) ——————————————————————————
  static const _kadinIsimleri = [
    'Zeynep', 'Elif', 'Ayşe', 'Fatma', 'Emine', 'Hatice', 'Merve', 'Büşra',
    'Selin', 'Esra', 'Derya', 'Özge', 'Ceyda', 'Nilüfer', 'Gülsüm', 'Perihan',
    'Şule', 'Tülay', 'Nuray', 'Sevgi', 'Tuğba', 'Sibel', 'Arzu', 'Nihal',
    'Pınar', 'Aysun', 'Serap', 'Gülay', 'Filiz', 'Mehtap', 'Canan', 'Yıldız',
    'Bahar', 'Hülya', 'Zümrüt', 'Sevda', 'Aslı', 'Gamze', 'Neslihan', 'Duygu',
    'Ece', 'İpek', 'Seda', 'Gül', 'Nurcan', 'Fulya', 'Berna', 'Songül',
    'Özlem', 'Yaprak', 'Selma', 'Nurgül', 'Buse', 'Hande', 'Simge', 'Deniz',
    'Leyla', 'Zehra', 'Betül', 'Kübra', 'Melike', 'Rana', 'Sıla', 'Yasemin',
    'Miray', 'Sümeyye', 'Hilal', 'Nazan', 'Tuğçe', 'Nesrin', 'Güneş', 'Funda',
    'Dilek', 'Şeyma', 'Eylül', 'Cansu', 'Hazal', 'Aylin', 'Nida', 'Rüya',
    'Sanem', 'Şirin', 'Tuba', 'Vildan', 'Yeliz', 'Zühre', 'Alev', 'Bengü',
    'Cemre', 'Dilara', 'Ebru', 'Ferda', 'Gökçe', 'Jale', 'Kamile', 'Latife',
    'Müjde', 'Nazlı', 'Özden', 'Pembe',
  ];
  static String _randomKadinIsim() =>
      _kadinIsimleri[_rng.nextInt(_kadinIsimleri.length)];

  // — Rastgele erkek ismi (100 Türkçe erkek adı) ———————————————————————————
  static const _erkekIsimleri = [
    'Ahmet', 'Mehmet', 'Ali', 'Mustafa', 'Ömer', 'İbrahim', 'Hasan', 'Hüseyin',
    'Kemal', 'Yusuf', 'Mahmut', 'Kadir', 'Osman', 'Ramazan', 'Recep', 'Murat',
    'Emre', 'Burak', 'Can', 'Serkan', 'Tolga', 'Arda', 'Berk', 'Deniz',
    'Efe', 'Furkan', 'Görkem', 'Haluk', 'İlker', 'Kaan', 'Levent', 'Mert',
    'Nuri', 'Onur', 'Polat', 'Rıza', 'Selçuk', 'Tayfun', 'Uğur', 'Volkan',
    'Yiğit', 'Zafer', 'Adem', 'Baran', 'Cem', 'Devrim', 'Ercan', 'Ferhat',
    'Gökhan', 'Hakan', 'İsmail', 'Kenan', 'Lokman', 'Münir', 'Necati', 'Okan',
    'Poyraz', 'Rauf', 'Suat', 'Taner', 'Umut', 'Vedat', 'Yüksel', 'Zeki',
    'Aykut', 'Bilal', 'Cengiz', 'Dursun', 'Erdal', 'Fikret', 'Güven', 'Hamit',
    'İlhan', 'Kasım', 'Lütfi', 'Necdet', 'Orhan', 'Oktay', 'Sami', 'Tarık',
    'Ulaş', 'Veli', 'Yasin', 'Adnan', 'Bülent', 'Cemal', 'Doğan', 'Ergün',
    'Fatih', 'Gürol', 'Hayri', 'İhsan', 'Kamil', 'Latif', 'Muzaffer', 'Nadir',
    'Orçun', 'Servet', 'Tayyar', 'Tuncay',
  ];
  static String _randomErkekIsim() =>
      _erkekIsimleri[_rng.nextInt(_erkekIsimleri.length)];

  // — Rastgele fiziksel özellik (150 yaratıcı tanım) ————————————————————————
  static const _fizikiHavuzu = [
    'sarışın mavi gözlü',
    'kısa boylu gözlüklü',
    'uzun saçlı beyaz tokalı',
    'mavi gözlü kırmızı rujlu',
    'kumral yeşil gözlü',
    'siyah saçlı kahverengi gözlü',
    'kızıl saçlı çilli',
    'uzun boylu ince yapılı',
    'kısa boylu tombul yanaklı',
    'esmer zeytin tenli',
    'açık tenli pembe yanaklı',
    'gümüş saçlı zarif görünümlü',
    'uzun kirpikli koyu gözlü',
    'dolgun dudaklı güler yüzlü',
    'keskin çizgili yüzlü',
    'elma yanaklı tatlı görünümlü',
    'ince belli uzun boylu',
    'atletik yapılı bronz tenli',
    'çekik gözlü koyu kaşlı',
    'sarı saçlı fındık gözlü',
    'kıvırcık saçlı canlı bakışlı',
    'düz saçlı zarif duruşlu',
    'oval yüzlü ince çizgili',
    'geniş alınlı zeytinyağı tenli',
    'dolgun yanaklı tatlı görünümlü',
    'mor gözlüklü kısa saçlı',
    'uzun boylu güçlü yapılı',
    'narin yapılı büyük gözlü',
    'siyah gözlüklü ciddi görünümlü',
    'dövmeli kollu rock havalı',
    'temiz yüzlü masum bakışlı',
    'enerjik görünümlü canlı bakışlı',
    'sakin ifadeli derin gözlü',
    'gülümseme çizgili mutlu yüzlü',
    'çıkık elmacık kemikli egzotik görünümlü',
    'ince dudaklı keskin bakışlı',
    'yuvarlak yüzlü sevimli görünümlü',
    'düzgün burunlu simetrik yüzlü',
    'koyu kaşlı ifadeli yüzlü',
    'parlak gözlü neşeli görünümlü',
    'tombul yanaklı yumuşak bakışlı',
    'uzun boyunlu zarif görünümlü',
    'geniş omuzlu sportif yapılı',
    'kısa saçlı sivri çizgili',
    'örgülü saçlı geleneksel görünümlü',
    'renkli gözlüklü artistik görünümlü',
    'pembe dudaklı şirin görünümlü',
    'bronzlaşmış tenli tatil havalı',
    'soluk tenli gizemli görünümlü',
    'çakır gözlü aydınlık yüzlü',
    'kehribar gözlü sıcak bakışlı',
    'mavi gözlüklü entelektüel görünümlü',
    'çene çukurlu yakışıklı görünümlü',
    'gamzeli tatlı gülen yüzlü',
    'uzun dalgalı bronz saçlı',
    'kısa saçlı küpeli cool görünümlü',
    'omuz saçlı sade güzel görünümlü',
    'topuz saçlı ciddi görünümlü',
    'at kuyruğu saçlı sportif görünümlü',
    'perçemli sempatik görünümlü',
    'beyaz saçlı bilge görünümlü',
    'ela gözlü tatlı bakışlı',
    'koyu mavi gözlü mistik görünümlü',
    'yeşil gözlü bahar havalı',
    'gri gözlü derin bakışlı',
    'fındık gözlü sıcak görünümlü',
    'kestane saçlı klasik güzel görünümlü',
    'platin saçlı modern görünümlü',
    'kızıl kahverengi saçlı doğal görünümlü',
    'siyah saçlı parlak gözlü',
    'iri gözlü şaşkın bakışlı',
    'ufak tefek zarif görünümlü',
    'iri yapılı heybetli görünümlü',
    'narin boyunlu zarif görünümlü',
    'buğday tenli doğal güzel görünümlü',
    'çilli sevimli görünümlü',
    'tatlı sert yüzlü',
    'asil görünümlü dik duruşlu',
    'içten bakışlı sıcak görünümlü',
    'dalgın bakışlı düşünceli görünümlü',
    'çekici gülüşlü karizmatik görünümlü',
    'sabah güneşi gibi aydınlık yüzlü',
    'ay ışığı gibi soluk tenli',
    'esmer gözlü ateşli görünümlü',
    'badem gözlü Akdeniz havalı',
    'ince belli uzun bacaklı zarif görünümlü',
    'güçlü çeneli karizmatik görünümlü',
    'yumuşak hatlı sevimli görünümlü',
    'keskin bakışlı kararlı görünümlü',
    'nazik görünümlü nazlı bakışlı',
    'yüzü aydınlık neşeli görünümlü',
    'büyük gözlü çekici görünümlü',
    'ince kaşlı zarif görünümlü',
    'kalın kaşlı kendinden emin görünümlü',
    'kıvırcık sarı saçlı neşeli görünümlü',
    'düz siyah saçlı gizemli görünümlü',
    'kestane kıvırcık saçlı şen görünümlü',
    'uzun kirpikli masumane bakışlı',
    'çatık kaşlı düşünceli görünümlü',
    'gülen gözlü neşeli görünümlü',
    'melankolik bakışlı sanatsal görünümlü',
    'sıcak gülüşlü sevecen görünümlü',
    'hafif çilli romantik görünümlü',
    'yanaktan gamzeli büyüleyici görünümlü',
    'güneş yanığı doğal görünümlü',
    'kış bakışlı soğuk güzel görünümlü',
    'güz havalı nostaljik görünümlü',
    'deniz gözlü maceracı görünümlü',
    'orman gözlü özgür ruhlu görünümlü',
    'fırtına gri gözlü dramatik görünümlü',
    'şeker pembesi dudaklı tatlı görünümlü',
    'doğal dudaklı alımlı görünümlü',
    'ışıltılı gülüşlü büyüleyici görünümlü',
    'kurumsal bakışlı profesyonel görünümlü',
    'sakin yüzlü güvenilir görünümlü',
    'cömert gülüşlü güven veren görünümlü',
    'gizemli bakışlı çekici görünümlü',
    'yıldız gözlü peri havalı görünümlü',
    'model boyunda zarif görünümlü',
    'spor yapmış sıkı yapılı',
    'tertemiz bakışlı saf görünümlü',
    'bilge gözlü deneyimli görünümlü',
    'genç görünümlü enerjik yapılı',
    'olgun bakışlı derin düşünceli görünümlü',
    'toy görünümlü taze yüzlü',
    'porselen tenli narin görünümlü',
    'çöl güneşi gibi bronz görünümlü',
    'kuzey ülkesi gibi beyaz tenli',
    'doğu güzeli egzotik görünümlü',
    'batı güzeli klasik görünümlü',
    'melez görünümlü etnik güzel',
    'küçük burunlu simetrik yüzlü',
    'sivri çeneli ince yüzlü',
    'yuvarlak çeneli sevimli görünümlü',
    'geniş alınlı zeki görünümlü',
    'dar alınlı yoğunlaşmış ifadeli görünümlü',
    'tatlı dilli görünümlü',
    'sert bakışlı güçlü görünümlü',
    'mütevazı görünümlü alçakgönüllü tipli',
    'göz alıcı renk uyumlu görünümlü',
    'karizmatik duruşlu çarpıcı görünümlü',
    'doğaçlama güzel bir görünümü olan',
    'silueti belirgin zarif duruşlu',
    'cam gibi teni olan berrak bakışlı',
    'koyu kirpikli dolgun yüzlü',
    'rüzgârda dalgalanan saçlı özgür görünümlü',
  ];
  static String _randomFiziki() =>
      _fizikiHavuzu[_rng.nextInt(_fizikiHavuzu.length)];

  // — Rastgele hava durumu ifadesi ——————————————————————————————————————————
  static const _havaDurumuFrazeler = [
    'değişken sıcaklıklarda',
    'hiç belli olmuyor',
    'bir hayli oynak',
    'mevsime göre değişken',
    'tahmin edilmesi güç',
    'her an sürpriz yapabilir',
  ];
  static String _randomHavaDurumu() =>
      _havaDurumuFrazeler[_rng.nextInt(_havaDurumuFrazeler.length)];

  // — Kaç gündür (isim hash'inden kararlı gün sayısı, 60–359 arası) ————————
  static int _seededDayCount(String isim) {
    if (isim.isEmpty) return 120;
    int hash = 0;
    for (final c in isim.codeUnits) {
      hash = (hash * 31 + c) & 0xFFFFFFFF;
    }
    return 60 + (hash % 300); // 60–359
  }

  // — Şehir sıfat hâli (İstanbul→"İstanbul'lu", Ankara→"Ankara'lı") —————————
  // Türkçe ünlü uyumuna göre -lI eki: a/ı→-lı, e/i→-li, o/u→-lu, ö/ü→-lü
  static String _nereli(String sehir) {
    if (sehir.isEmpty) return '';
    const allVowels = 'aeıioöuü';
    String lastVowel = '';
    for (int i = sehir.length - 1; i >= 0; i--) {
      final c = sehir[i].toLowerCase();
      if (allVowels.contains(c)) { lastVowel = c; break; }
    }
    String ek;
    if (lastVowel == 'a' || lastVowel == 'ı') {
      ek = "'lı";
    } else if (lastVowel == 'e' || lastVowel == 'i') {
      ek = "'li";
    } else if (lastVowel == 'o' || lastVowel == 'u') {
      ek = "'lu";
    } else if (lastVowel == 'ö' || lastVowel == 'ü') {
      ek = "'lü";
    } else {
      ek = "'li"; // fallback
    }
    return '$sehir$ek';
  }

  // — Rastgele sessiz harf ——————————————————————————————————————————————————
  static const _sessizHarfler = 'BCÇDFGĞHJKLMNPRSŞTVYZ';
  static String _randomConsonant(String seed) {
    final idx = seed.isEmpty ? _rng.nextInt(_sessizHarfler.length)
        : seed.codeUnitAt(0) % _sessizHarfler.length;
    return _sessizHarfler[idx];
  }

  // ── {{kelimecins, erkek_X|kadin_Y|lgbt_Z}} ──────────────────────────────────

  static String _replaceKelimeCins(String text, Map<String, String> vars) {
    final pattern = RegExp(r'\{\{kelimecins,([^}]+)\}\}');
    return text.replaceAllMapped(pattern, (match) {
      final cinsiyet = (vars['cinsiyet'] ?? '').toLowerCase().trim();
      final parts = match.group(1)!.split('|');
      String? fallback;
      for (final part in parts) {
        final trimmed = part.trim();
        final us = trimmed.indexOf('_');
        if (us < 0) continue;
        final key   = trimmed.substring(0, us).trim().toLowerCase();
        final value = trimmed.substring(us + 1).trim();
        fallback ??= value;
        final normalKey = key.replaceAll('ı', 'i').replaceAll('ş', 's');
        final normalCins = cinsiyet.replaceAll('ı', 'i').replaceAll('ş', 's');
        if (normalKey == normalCins) { return value; }
      }
      return fallback ?? '';
    });
  }

  // ── {{medenidurum, evli_X|bekar_Y|...}} ────────────────────────────────────

  static String _replaceMedeniDurum(String text, Map<String, String> vars) {
    final pattern = RegExp(r'\{\{medenidurum,([^}]+)\}\}');
    return text.replaceAllMapped(pattern, (match) {
      final durum = (vars['medeni_durum'] ?? '').toLowerCase().trim();
      final parts = match.group(1)!.split('|');
      String? fallback;
      for (final part in parts) {
        final trimmed = part.trim();
        final us = trimmed.indexOf('_');
        if (us < 0) continue;
        final key   = trimmed.substring(0, us).trim().toLowerCase();
        final value = trimmed.substring(us + 1).trim();
        fallback ??= value;
        if (key == durum) return value;
      }
      return fallback ?? '';
    });
  }

  // ── {{sabitkelime, A|B|C}} / {{sabit_kelime, A|B|C}} ───────────────────────
  // Her kalıp için aynı metin içinde aynı sonuç döner (isim seed'li).

  static String _replaceSabitKelime(String text, Map<String, String> vars) {
    final pattern = RegExp(r'\{\{sabit[_]?kelime[a-z]*,([^}]+)\}\}');
    return text.replaceAllMapped(pattern, (match) {
      final options = match.group(1)!
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (options.isEmpty) return '';
      final seed = vars['isim'] ?? '';
      final idx  = seed.isEmpty ? 0 : seed.codeUnitAt(0) % options.length;
      return options[idx];
    });
  }

  // ── {{yas_N}} / {{yas_+N}} / {{yas_-N}} ─────────────────────────────────────

  static String _replaceYasOffset(String text, Map<String, String> vars) {
    final yas = int.tryParse(vars['yas'] ?? '0') ?? 0;
    return text.replaceAllMapped(
      RegExp(r'\{\{yas_([+-]?\d+)\}\}'),
      (m) {
        final offset = int.tryParse(m.group(1)!) ?? 0;
        return (yas + offset).toString();
      },
    );
  }

  // ── {{mevsim_N}} / {{mevsim,N}} ─────────────────────────────────────────────
  // Mevcut mevsimden N mevsim ilerisi/gerisi.
  // mevsim_0 veya mevsim → şu an. mevsim_+1 → bir sonraki.

  static String _replaceMevsimOffset(String text, DateTime now) {
    const mevsimler = ['İlkbahar', 'Yaz', 'Sonbahar', 'Kış'];
    int currentMevsim() {
      final m = now.month;
      if (m >= 3 && m <= 5) return 0;
      if (m >= 6 && m <= 8) return 1;
      if (m >= 9 && m <= 11) return 2;
      return 3;
    }
    // {{mevsim_0}}, {{mevsim_1}}, {{mevsim_-1}}, {{mevsim_+2}} ...
    text = text.replaceAllMapped(RegExp(r'\{\{mevsim_([+-]?\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      final idx = ((currentMevsim() + offset) % 4 + 4) % 4;
      return mevsimler[idx];
    });
    // {{mevsim,N}} — virgüllü notasyon
    text = text.replaceAllMapped(RegExp(r'\{\{mevsim,([+-]?\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      final idx = ((currentMevsim() + offset) % 4 + 4) % 4;
      return mevsimler[idx];
    });
    return text;
  }

  // ── Zaman değişkenleri ──────────────────────────────────────────────────────

  static Map<String, String> _timeVariables(DateTime now) {
    return {
      'gun': _dayOfWeekTr(now.weekday),
      'gun_0': now.day.toString(),        // bugünün ayın kaçıncı günü (8, 15...)
      'ay': _monthTr(now.month),
      'ay_0': _monthTr(now.month),        // bugünün ay adı (Nisan, Mayıs...)
      'mevsim': _seasonTr(now.month),
      'tam_saat': DateFormat('HH:mm').format(now),
      'saat': now.hour.toString(),
      'dakika': now.minute.toString(),
    };
  }

  // ── Sabit rastgele sayı ─────────────────────────────────────────────────────
  // {{sabit_sayi,min,max}} — aynı metin içinde aynı kalıp her yerde aynı sayıyı alır.
  // Farklı aralıklar (2,6) ve (3,7) bağımsız seçilir; aynı aralık tekrarsa aynı değer.

  static String _replaceStableNumbers(String text) {
    final pattern = RegExp(r'\{\{sabit_sayi,(\d+),(\d+)\}\}');
    // Önce her benzersiz "min,max" kombinasyonu için bir sayı seç
    final cache = <String, String>{};
    for (final m in pattern.allMatches(text)) {
      final key = '${m.group(1)},${m.group(2)}';
      if (!cache.containsKey(key)) {
        final min = int.tryParse(m.group(1)!) ?? 0;
        final max = int.tryParse(m.group(2)!) ?? min;
        final value = max <= min ? min : min + _rng.nextInt(max - min + 1);
        cache[key] = value.toString();
      }
    }
    // Şimdi hepsini aynı anda değiştir
    return text.replaceAllMapped(pattern, (m) {
      final key = '${m.group(1)},${m.group(2)}';
      return cache[key]!;
    });
  }

  // ── Rastgele sayı ───────────────────────────────────────────────────────────

  static String _replaceRandomNumbers(String text) {
    final pattern = RegExp(r'\{\{sayi,(\d+),(\d+)\}\}');
    return text.replaceAllMapped(pattern, (match) {
      final min = int.tryParse(match.group(1) ?? '0') ?? 0;
      final max = int.tryParse(match.group(2) ?? '100') ?? 100;
      if (max <= min) return min.toString();
      return (min + _rng.nextInt(max - min + 1)).toString();
    });
  }

  // ── {{randomtarih, min, max}} ────────────────────────────────────────────────
  // Bugünün üzerine [min, max] aralığında rastgele gün ekler ve Türkçe yazar.
  // Örn: bugün 1 Ocak, random=16 → "17 Ocak"
  //      bugün 4 Şubat, random=20 → "24 Şubat"
  // Yıl gösterilmez (aynı yıl içinde kalsa da). Geçen yıl sınırını aşarsa yıl eklenir.

  static String _replaceRandomTarih(String text, DateTime now) {
    final pattern = RegExp(r'\{\{randomtarih,\s*(\d+),\s*(\d+)\}\}');
    return text.replaceAllMapped(pattern, (match) {
      final min = int.tryParse(match.group(1)!) ?? 1;
      final max = int.tryParse(match.group(2)!) ?? min;
      final gunSayisi = max <= min ? min : min + _rng.nextInt(max - min + 1);
      final hedef = now.add(Duration(days: gunSayisi));
      // Farklı yıla geçtiyse yılı da göster
      if (hedef.year != now.year) {
        return '${hedef.day} ${_monthTr(hedef.month)} ${hedef.year}';
      }
      return '${hedef.day} ${_monthTr(hedef.month)}';
    });
  }

  // ── Ham metin temizliği ──────────────────────────────────────────────────────
  // Python extraction artefaktlarını düzeltir:
  //   \U0001F50D  → 🔍  (8 haneli büyük-U Unicode escape — emoji düzlemi)
  //   \uXXXX      → ilgili karakter (artık JSON'da olmamalı ama güvenlik için)
  //   Baş tırnak işareti (YAML parse artefaktı: "Metin...")

  static String _cleanRawText(String text) {
    // \UXXXXXXXX — 8 haneli emoji escape (Python'un \U formatı)
    text = text.replaceAllMapped(
      RegExp(r'\\U([0-9A-Fa-f]{8})'),
      (m) {
        final code = int.tryParse(m.group(1)!, radix: 16);
        if (code == null) return '';
        try { return String.fromCharCodes([code]); } catch (_) { return ''; }
      },
    );

    // \uXXXX — 4 haneli escape (güvenlik)
    text = text.replaceAllMapped(
      RegExp(r'\\u([0-9A-Fa-f]{4})'),
      (m) {
        final code = int.tryParse(m.group(1)!, radix: 16);
        return code != null ? String.fromCharCode(code) : '';
      },
    );

    // Baş ve son tırnak işaretini kaldır (YAML artefaktı)
    if (text.startsWith('"')) text = text.substring(1);
    if (text.endsWith('"'))   text = text.substring(0, text.length - 1);

    return text.trim();
  }

  // ── <sprite=N> → emoji ──────────────────────────────────────────────────────

  static const _spriteMap = <int, String>{
    0:  '🙂',
    5:  '😄',
    7:  '😉',
    10: '☺️',
    23: '😎',
    73: '👊',
    79: '🙏',
  };

  static String _replaceSprites(String text) {
    return text.replaceAllMapped(RegExp(r'<sprite=(\d+)>'), (m) {
      final n = int.tryParse(m.group(1) ?? '') ?? -1;
      return _spriteMap[n] ?? ''; // bilinmiyorsa sil
    });
  }

  // ── {{kelime, A | B | C}} — rastgele seçim ──────────────────────────────────

  static String _replaceRandomWord(String text) {
    return text.replaceAllMapped(RegExp(r'\{\{kelime,([^}]+)\}\}'), (m) {
      final options = m.group(1)!
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (options.isEmpty) return '';
      return options[_rng.nextInt(options.length)];
    });
  }

  // ── {{ay_+N}} / {{gun_+N}} — kaydırmalı ay/gün adı ─────────────────────────

  static String _replaceOffsetTime(String text, DateTime now) {
    // {{ay_+N}} veya {{ay_-N}}
    text = text.replaceAllMapped(RegExp(r'\{\{ay_([+-]\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      final month = ((now.month - 1 + offset) % 12 + 12) % 12 + 1;
      return _monthTr(month);
    });
    // {{gun_+N}} veya {{gun_-N}}
    text = text.replaceAllMapped(RegExp(r'\{\{gun_([+-]\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      // weekday: 1=Pzt … 7=Pazar
      final day = ((now.weekday - 1 + offset) % 7 + 7) % 7 + 1;
      return _dayOfWeekTr(day);
    });
    return text;
  }

  // ── {{gunsayi_N}} — ayın kaçı ± offset ─────────────────────────────────────
  // {{gunsayi_0}} = bugün 17'yse → "17"
  // {{gunsayi_3}} = bugün 17'yse → "20"
  // {{gunsayi_-3}} = bugün 17'yse → "14"
  // (sonuç 1–31 arasına sıkıştırılır)

  static String _replaceOffsetDayNumber(String text, DateTime now) {
    return text.replaceAllMapped(RegExp(r'\{\{gunsayi_(-?\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      final day = (now.day + offset).clamp(1, 31);
      return day.toString();
    });
  }

  // ── {{yil_N}} — yıl ± offset ─────────────────────────────────────────────
  // {{yil_0}} = 2026'daysa → "2026"
  // {{yil_-1}} = 2026'daysa → "2025"
  // {{yil_2}} = 2026'daysa → "2028"

  static String _replaceOffsetYear(String text, DateTime now) {
    return text.replaceAllMapped(RegExp(r'\{\{yil_(-?\d+)\}\}'), (m) {
      final offset = int.tryParse(m.group(1)!) ?? 0;
      return (now.year + offset).toString();
    });
  }

  // ── Rastgele burç ───────────────────────────────────────────────────────────

  static const _burclar = [
    'Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak',
    'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık',
  ];

  static String _randomBurc() => _burclar[_rng.nextInt(_burclar.length)];

  // ── Yardımcılar ─────────────────────────────────────────────────────────────

  static String _dayOfWeekTr(int weekday) {
    const days = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[weekday];
  }

  static String _monthTr(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return months[month];
  }

  static String _seasonTr(int month) {
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }

  /// Pick one variation from a list. Uses a stable index derived from
  /// the user's name so the same user always gets the same variation
  /// for the same node (deterministic, not random).
  static String pickVariation(List<String> variations, {String seed = ''}) {
    if (variations.isEmpty) return '';
    if (variations.length == 1) return variations.first;
    final index = seed.isEmpty ? 0 : seed.codeUnits.first % variations.length;
    return variations[index];
  }
}
