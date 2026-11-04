// Unity rich text <color=X>...</color> etiketlerini Flutter TextSpan'a çevirir.
// Kullanım:
//   RichTextParser.build(text, style: TextStyle(...))
//
// Desteklenen renkler: yellow, red, green, blue, cyan, magenta, orange, white, black
// Hex renk de desteklenir: color=#FF8800 formatında

import 'package:flutter/material.dart';

class RichTextParser {
  static final _tag = RegExp(r'<color=(#?[0-9a-zA-Z]+)>(.*?)<\/color>', dotAll: true);

  /// <b>...</b> ve <i>...</i> gibi bilinmeyen Unity etiketlerini siler.
  static String _stripUnknownTags(String text) {
    return text
        .replaceAll(RegExp(r'<b>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<\/b>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<i>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<\/i>', caseSensitive: false), '');
  }

  // 2026-11 "Gece Grimuarı": içerik vurgu renkleri desatüre — TON (anlam) korunur,
  // neon kısılır (Codex: "renk" fallarında gerçek renk anlamı kaybolmasın). Eski neon
  // değerler: yellow FFDD33, red FF5555, green 55FF88, blue 5599FF, cyan 44EEFF,
  // magenta FF55FF, orange FF9944.
  static Color _parseColor(String name) {
    final n = name.toLowerCase().trim();
    if (n.startsWith('#')) {
      final hex = n.replaceFirst('#', '');
      if (hex.length == 6) {
        return mute(Color(int.parse('FF$hex', radix: 16)));
      } else if (hex.length == 8) {
        return mute(Color(int.parse(hex, radix: 16)));
      }
    }
    switch (n) {
      case 'yellow':  return const Color(0xFFD6BE82); // eski altın tonu
      case 'red':     return const Color(0xFFC98A86); // desatüre gül
      case 'green':   return const Color(0xFF8FB59A); // adaçayı
      case 'blue':    return const Color(0xFF8FA6C9); // çelik mavisi
      case 'cyan':    return const Color(0xFF8FB8BF); // soğuk gümüş-camgöbeği
      case 'magenta': return const Color(0xFFB98FB0); // tozlu leylak
      case 'orange':  return const Color(0xFFC9986A); // kehribar
      case 'white':   return const Color(0xFFEEEAE2); // kemik beyazı
      // Koyu zeminde siyah okunmaz (Unity metinleri açık zemin için yazılmış olabilir).
      case 'black':   return const Color(0xFF898C91);
      default:        return const Color(0xFFEEEAE2);
    }
  }

  /// Hex içerik rengini palete yaklaştır: doygunluk ≤ 0.38, açıklık 0.60–0.82
  /// (koyu cam üstünde okunur). Ton aynı kalır.
  static Color mute(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation(hsl.saturation.clamp(0.0, 0.38))
        .withLightness(hsl.lightness.clamp(0.60, 0.82))
        .toColor();
  }

  /// Metinde color etiketi varsa RichText, yoksa sade Text döner.
  /// <b>, <i> gibi bilinmeyen Unity etiketleri otomatik temizlenir.
  static Widget build(String text, {required TextStyle style, TextAlign textAlign = TextAlign.start}) {
    final cleaned = _stripUnknownTags(text);
    if (!cleaned.contains('<color=')) {
      return Text(cleaned, style: style, textAlign: textAlign);
    }
    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: _parse(cleaned, style)),
    );
  }

  /// Widget yerine ham TextSpan (kelime kelime animasyon gibi özel çizimler için).
  /// Etiket temizliği + desatüre renkler build() ile aynı.
  static TextSpan span(String text, {required TextStyle style}) {
    final cleaned = _stripUnknownTags(text);
    if (!cleaned.contains('<color=')) return TextSpan(text: cleaned, style: style);
    return TextSpan(style: style, children: _parse(cleaned, style));
  }

  static List<TextSpan> _parse(String text, TextStyle base) {
    final spans = <TextSpan>[];
    int lastEnd = 0;
    for (final m in _tag.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start), style: base));
      }
      spans.add(TextSpan(
        text: m.group(2)!,
        style: base.copyWith(color: _parseColor(m.group(1)!)),
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: base));
    }
    return spans;
  }
}
