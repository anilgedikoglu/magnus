import 'dart:math';
import 'package:flutter/material.dart';

/// Minimal, çizgisel kum saati widget'ı.
/// [size]   : Genel boyut (varsayılan 56)
/// [color]  : Çizgi + kum rengi
/// [animate]: true → kum akışı animasyonu (varsayılan true)
class ElegantHourglass extends StatefulWidget {
  final double size;
  final Color color;
  final bool animate;

  const ElegantHourglass({
    super.key,
    this.size = 56,
    this.color = Colors.white,
    this.animate = true,
  });

  @override
  State<ElegantHourglass> createState() => _ElegantHourglassState();
}

class _ElegantHourglassState extends State<ElegantHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _HourglassPainter(
            progress: _ctrl.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 (bir tam döngü)
  final Color color;

  const _HourglassPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Hizalama sabitleri
    final cx = w / 2;
    final topY = h * 0.06;
    final botY = h * 0.94;
    final neckY = h / 2;
    final halfNeck = w * 0.04; // boyun yarı genişliği
    final halfTop = w * 0.40;  // üst/alt kenar yarı genişliği

    // --- Çerçeve çizgisi ---
    final framePaint = Paint()
      ..color = color
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final framePath = Path()
      // Üst yatay çizgi
      ..moveTo(cx - halfTop, topY)
      ..lineTo(cx + halfTop, topY)
      // Sağ taraf: üstten boyuna
      ..moveTo(cx + halfTop, topY)
      ..lineTo(cx + halfNeck, neckY)
      // Sağ taraf: boyundan alta
      ..moveTo(cx + halfNeck, neckY)
      ..lineTo(cx + halfTop, botY)
      // Alt yatay çizgi
      ..moveTo(cx + halfTop, botY)
      ..lineTo(cx - halfTop, botY)
      // Sol taraf: alttan boyuna
      ..moveTo(cx - halfTop, botY)
      ..lineTo(cx - halfNeck, neckY)
      // Sol taraf: boyundan üste
      ..moveTo(cx - halfNeck, neckY)
      ..lineTo(cx - halfTop, topY);

    canvas.drawPath(framePath, framePaint);

    // --- Kum doluluk oranı ---
    // progress 0→1: üst boşalır, alt dolar
    // 0..0.85: aktif akış; 0.85..1.0: flip geçişi (görsel sıfırlanır)
    final t = progress < 0.85 ? progress / 0.85 : 1.0;

    final sandPaint = Paint()
      ..color = color.withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;

    // Üst bölme: t=0 → dolu, t=1 → boş
    final topFill = 1.0 - t;
    if (topFill > 0.01) {
      // Kum saati üst bölmesinin doluluk poligonu
      // Y=neckY üstünde, üstten aşağı doğru topFill kadar dolu
      final topSandTop = topY + (neckY - topY) * (1.0 - topFill);

      // Üst bölme: yamuk (üste geniş, alta dar — kum saati iç şekli)
      // topSandTop'taki genişlik = interpolasyon
      final topSandTopHalf = _xAtY(cx, topSandTop, topY, halfTop, neckY, halfNeck);
      final topSandBotHalf = _xAtY(cx, neckY - 1, topY, halfTop, neckY, halfNeck);

      final topSandPath = Path()
        ..moveTo(cx - topSandTopHalf, topSandTop)
        ..lineTo(cx + topSandTopHalf, topSandTop)
        ..lineTo(cx + topSandBotHalf, neckY - 1)
        ..lineTo(cx - topSandBotHalf, neckY - 1)
        ..close();
      canvas.drawPath(topSandPath, sandPaint);
    }

    // Alt bölme: t=0 → boş, t=1 → dolu
    final botFill = t;
    if (botFill > 0.01) {
      final botSandBot = botY - (botY - neckY) * (1.0 - botFill);
      final botSandBotHalf = _xAtY(cx, botSandBot, neckY, halfNeck, botY, halfTop);
      final botSandTopHalf = _xAtY(cx, neckY + 1, neckY, halfNeck, botY, halfTop);

      final botSandPath = Path()
        ..moveTo(cx - botSandTopHalf, neckY + 1)
        ..lineTo(cx + botSandTopHalf, neckY + 1)
        ..lineTo(cx + botSandBotHalf, botSandBot)
        ..lineTo(cx - botSandBotHalf, botSandBot)
        ..close();
      canvas.drawPath(botSandPath, sandPaint);
    }

    // --- Boyun kum damlası (aktif akış sırasında) ---
    if (progress < 0.85 && topFill > 0.02) {
      final dropPaint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;

      // Boyundan akan ince bir şerit
      final dropPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(cx, neckY + h * 0.04),
          width: w * 0.06,
          height: h * 0.08,
        ));
      canvas.drawPath(dropPath, dropPaint);
    }
  }

  /// İç kum saati duvarının belirli Y'deki X yarı genişliği (lineer interpolasyon)
  double _xAtY(
      double cx, double y, double y1, double x1, double y2, double x2) {
    if ((y2 - y1).abs() < 0.001) return x1;
    final ratio = (y - y1) / (y2 - y1);
    return x1 + (x2 - x1) * ratio.clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(_HourglassPainter old) =>
      old.progress != progress || old.color != color;
}

/// Flip animasyonlu versiyon — eski `_top ? hourglass_top : hourglass_bottom` kalıbı ile uyumlu
class FlipHourglass extends StatefulWidget {
  final double size;
  final Color color;
  final Duration flipInterval;

  const FlipHourglass({
    super.key,
    this.size = 56,
    this.color = Colors.white,
    this.flipInterval = const Duration(milliseconds: 900),
  });

  @override
  State<FlipHourglass> createState() => _FlipHourglassState();
}

class _FlipHourglassState extends State<FlipHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.flipInterval,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // 0→0.5: normal yön; 0.5→1.0: ters çevrilmiş
        final flipped = _ctrl.value >= 0.5;
        final turnProgress = flipped ? (_ctrl.value - 0.5) * 2 : _ctrl.value * 2;
        return Transform.rotate(
          angle: flipped ? pi : 0,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _HourglassPainter(
              progress: turnProgress * 0.85,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

/// Pulse (büyüyüp küçülen) animasyonlu versiyon — ScaleTransition + FlipHourglass
class PulsingHourglass extends StatefulWidget {
  final double size;
  final Color color;

  const PulsingHourglass({
    super.key,
    this.size = 48,
    this.color = const Color(0xFFB8E0FF),
  });

  @override
  State<PulsingHourglass> createState() => _PulsingHourglassState();
}

class _PulsingHourglassState extends State<PulsingHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: ElegantHourglass(size: widget.size, color: widget.color),
    );
  }
}

/// Dönen (360°) animasyonlu versiyon — numeroloji_screen'deki kalıbı değiştirir
class SpinningHourglass extends StatefulWidget {
  final double size;
  final Color color;

  const SpinningHourglass({
    super.key,
    this.size = 64,
    this.color = const Color(0xFFBBAAFF),
  });

  @override
  State<SpinningHourglass> createState() => _SpinningHourglassState();
}

class _SpinningHourglassState extends State<SpinningHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Transform.rotate(
          angle: _ctrl.value * 2 * pi,
          child: ElegantHourglass(
            size: widget.size,
            color: widget.color,
            animate: false,
          ),
        ),
      ),
    );
  }
}
