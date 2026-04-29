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

  static Color _parseColor(String name) {
    final n = name.toLowerCase().trim();
    if (n.startsWith('#')) {
      final hex = n.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    switch (n) {
      case 'yellow':  return const Color(0xFFFFDD33);
      case 'red':     return const Color(0xFFFF5555);
      case 'green':   return const Color(0xFF55FF88);
      case 'blue':    return const Color(0xFF5599FF);
      case 'cyan':    return const Color(0xFF44EEFF);
      case 'magenta': return const Color(0xFFFF55FF);
      case 'orange':  return const Color(0xFFFF9944);
      case 'white':   return Colors.white;
      case 'black':   return Colors.black;
      default:        return Colors.white;
    }
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
