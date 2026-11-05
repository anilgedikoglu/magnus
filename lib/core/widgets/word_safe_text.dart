// lib/core/widgets/word_safe_text.dart
//
// Kelimeyi ORTASINDAN bölmeyen etiket (Anıl, 2026-11-06: dar telefonda + büyük sistem
// yazısında menü kartı adları "ASTROLO / Jİ", "DURUGÖ / RÜ" diye bölünüyordu).
// Flutter, tek kelime satıra sığmayınca kelimeyi harf harf böler. Burada en geniş kelime
// ölçülür; kutuya sığmıyorsa yazı (ve harf aralığı) o kelime sığacak kadar küçültülür
// (en az [minScale]). Kelimeler arasında satır kırılması normal sürer.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class WordSafeText extends StatelessWidget {
  const WordSafeText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 2,
    this.textAlign = TextAlign.center,
    this.minScale = 0.55,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;

  /// Yazının küçültülebileceği en alt oran.
  final double minScale;

  /// [maxWidth]'e en geniş kelimenin sığması için [style]'ın çarpanı (1 = değişmez).
  static double fitScale(
    String text,
    TextStyle style,
    double maxWidth, {
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
    double minScale = 0.55,
  }) {
    if (!maxWidth.isFinite || maxWidth <= 0) return 1;
    var widest = 0.0;
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, tp.width);
      tp.dispose();
    }
    if (widest <= maxWidth) return 1;
    // %2 pay: yuvarlama farkıyla son harf yine alt satıra düşmesin.
    return math.max(minScale, maxWidth / widest * 0.98);
  }

  static TextStyle scaled(TextStyle style, double k) => k == 1
      ? style
      : style.copyWith(
          fontSize: (style.fontSize ?? 14) * k,
          letterSpacing: style.letterSpacing == null ? null : style.letterSpacing! * k,
        );

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    return LayoutBuilder(builder: (context, c) {
      final k = fitScale(text, style, c.maxWidth,
          textScaler: scaler, textDirection: dir, minScale: minScale);
      return Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: scaled(style, k),
      );
    });
  }
}
