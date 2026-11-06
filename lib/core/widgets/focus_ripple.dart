// lib/core/widgets/focus_ripple.dart
//
// "Odaklanıyor" beklemesi (2026-11-06, Grok/Codex: kahinlerin beklemesi kum saatiyle
// yavan kalıyordu). Ortada nabız gibi atan (çift vuruş: lub-dub) ışıklı göz, çevresinden
// sonar gibi yayılan üç ince halka. İlk birkaç vuruşta hafif titreşim (sonra susar).
// Azaltılmış harekette: duran göz + iki sabit halka, titreşim yok.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'occult_glyphs.dart';

class FocusRipple extends StatefulWidget {
  const FocusRipple({
    super.key,
    required this.color,
    this.size = 148,
    this.period = const Duration(milliseconds: 1500),
    this.hapticBeats = 3,
  });

  final Color color;
  final double size;

  /// Bir nabız döngüsü (halkaların yayılma süresi bunun 2 katı).
  final Duration period;

  /// Kaç vuruşta titreşim olur (0 = hiç).
  final int hapticBeats;

  /// İki vuruşlu kalp atışı zarfı, t ∈ [0,1): 0.06'da güçlü, 0.26'da zayıf vuruş.
  @visibleForTesting
  static double beat(double t) {
    // Periyodik uzaklık: t=1 ile t=0 aynı değeri verir (Codex: sarmada ~0,3 sıçrıyordu).
    double g(double c, double w) {
      var d = (t - c).abs() % 1.0;
      if (d > 0.5) d = 1 - d;
      return math.exp(-math.pow(d / w, 2).toDouble());
    }
    return (g(0.06, 0.055) + 0.55 * g(0.26, 0.06)).clamp(0.0, 1.0);
  }

  @override
  State<FocusRipple> createState() => _FocusRippleState();
}

class _FocusRippleState extends State<FocusRipple> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period * 2);
  double _last = 0;
  int _beats = 0;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTick);
  }

  // Nabız döngüsü kontrolcünün yarısı: her yarı başında bir vuruş.
  void _onTick() {
    final v = (_c.value * 2) % 1.0;
    if (v < _last && _beats < widget.hapticBeats) {
      _beats++;
      HapticFeedback.lightImpact();
    }
    _last = v;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _reduced ? 0.0 : _c.value;
            final pulse = _reduced ? 0.35 : FocusRipple.beat((t * 2) % 1.0);
            return CustomPaint(
              painter: _RipplePainter(t: t, pulse: pulse, color: widget.color, still: _reduced),
              child: Center(
                child: Transform.scale(
                  scale: 1 + pulse * 0.10,
                  child: OccultGlyphIcon(
                    OccultGlyph.eye,
                    color: Color.lerp(widget.color, Colors.white, 0.35 + pulse * 0.4)!,
                    size: widget.size * 0.30,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.t, required this.pulse, required this.color, required this.still});
  final double t;
  final double pulse;
  final Color color;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    final r0 = maxR * 0.22;

    // Ortadaki ışık: vuruşla büyüyüp parlar.
    final orbR = r0 * (1.25 + pulse * 0.55);
    canvas.drawCircle(
      c,
      orbR,
      Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: 0.38 + pulse * 0.5),
          color.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: orbR)),
    );

    final ring = Paint()..style = PaintingStyle.stroke;
    if (still) {
      for (final f in const [0.55, 0.85]) {
        ring
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 0.35 * (1.1 - f));
        canvas.drawCircle(c, r0 + (maxR - r0) * f, ring);
      }
      return;
    }
    // Üç halka, eşit faz aralığıyla dışa yayılır ve söner.
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final e = 1 - math.pow(1 - p, 2.2).toDouble(); // dışa doğru yavaşlar
      final a = math.pow(1 - p, 1.4).toDouble() * 0.8;
      ring
        ..strokeWidth = 1.6 - p * 0.9
        ..color = color.withValues(alpha: a);
      canvas.drawCircle(c, r0 + (maxR - r0) * e, ring);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.t != t || old.pulse != pulse || old.color != color || old.still != still;
}
