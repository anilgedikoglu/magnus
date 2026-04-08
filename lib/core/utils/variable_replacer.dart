// ── AI NOTU: variable_replacer.dart ──────────────────────────────────────────
// Tüm içerik metinlerindeki {{placeholder}} ifadelerini gerçek kullanıcı
// verisine çeviren merkezi motor. Her fal/motivasyon/olumlama/tarot ekranında
// metni göstermeden önce mutlaka çağrılır:
//   VariableReplacer.replace(metin, profile.toVariableMap())
//
// Desteklenen placeholder'lar (tam liste):
//   {{isim}}         → kullanıcı adı
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
//   {{gun}}          → bugünün adı (Pazartesi vb.)
//   {{gun_0}}        → ayın günü (sayı)
//   {{gun_+N}}       → N gün sonraki haftanın gün adı ({{gun_+2}} → Cuma)
//   {{ay}}           → ay adı
//   {{ay_0}}         → ay sayısı
//   {{ay_+N}}        → N ay sonraki ay adı ({{ay_+1}} → Mayıs)
//   {{saat}}         → saat HH:MM
//   {{sayi,min,max}}       → rastgele sayı [min,max] (her tekrarda bağımsız)
//   {{sabit_sayi,min,max}} → rastgele sayı [min,max] (aynı metin içinde hep aynı değer)
//   {{rastgeleburc}} → rastgele burç adı
//   {{saniye}}       → geçerli saniye
//   {{kullanici sehri}} → doğum şehri
//   {{kelime, A | B | C}} → A/B/C arasından her render'da rastgele biri
//   {{data, cinsiyet=erkek, MetinA | cinsiyet=kadin, MetinB | cinsiyet=lgbt, MetinC}}
//                    → koşullu metin (cinsiyet değerine göre seçim)
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

    // 3. {{kelime, A | B | C}} — rastgele seçim
    result = _replaceRandomWord(result);

    // 4. {{ay_+N}} / {{gun_+N}} — kaydırmalı zaman
    result = _replaceOffsetTime(result, now);

    // 5. Sade değişken ikameleri
    allVars.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });

    // 6a. {{sabit_sayi,min,max}} — aynı aralıktaki TÜM tekrarlar aynı sayıyı alır
    result = _replaceStableNumbers(result);

    // 6b. {{sayi,min,max}} — her seferinde bağımsız rastgele sayı
    result = _replaceRandomNumbers(result);

    // 7. {{rastgeleburc}} — rastgele burç
    result = result.replaceAll('{{rastgeleburc}}', _randomBurc());

    // 8. {{saniye}} — anlık saniye
    result = result.replaceAll('{{saniye}}', now.second.toString());

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
