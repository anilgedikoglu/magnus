// lib/presentation/coffee/cup_steam.dart
//
// "Yerime İç" fincanından tüten buhar (2026-11-06, Grok: kahve falında ritüel hissi yok).
// Yumuşak, kıvrılarak yükselen 4 ince duman şeridi; [strong] (fal gönderilirken) daha
// yoğun ve uzun. Azaltılmış harekette çizilmez.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class CupSteam extends StatefulWidget {
  const CupSteam({super.key, this.strong = false, this.color = const Color(0xFFEDE6DA)});

  final bool strong;
  final Color color;

  @override
  State<CupSteam> createState() => _CupSteamState();
}

class _CupSteamState extends State<CupSteam> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
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
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) return const SizedBox.expand();
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.strong ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, k, _) => CustomPaint(
          size: Size.infinite,
          painter: _SteamPainter(anim: _c, strength: k, color: widget.color),
        ),
      ),
    );
  }
}

class _SteamPainter extends CustomPainter {
  _SteamPainter({required this.anim, required this.strength, required this.color}) : super(repaint: anim);
  final Animation<double> anim;
  final double strength; // 0 hafif → 1 yoğun
  final Color color;

  /// 6 sn'de tam tur (2π/6): kontrolcü sarınca dalgalanma sıçramaz.
  static const _w = math.pi / 3;

  @override
  void paint(Canvas canvas, Size size) {
    final time = anim.value * 6.0; // saniye (6 sn döngü; _w ile dikişsiz sarar)
    final base = Offset(size.width / 2, size.height); // şeritler alttan (fincan ağzı) başlar
    final rise = size.height * (0.72 + 0.28 * strength);
    final blur = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    const wisps = 4;
    for (var i = 0; i < wisps; i++) {
      final ph = i * 1.7;
      // Her şerit kendi döngüsünde doğar, yükselir, söner (birbirini izleyerek).
      final cyc = ((time / 3.0) + i / wisps) % 1.0;
      final life = math.sin(cyc * math.pi); // 0→1→0
      final x0 = base.dx + (i - (wisps - 1) / 2) * size.width * 0.11;
      final path = Path();
      const steps = 18;
      for (var s = 0; s <= steps; s++) {
        final f = s / steps;
        final y = base.dy - rise * f * (0.55 + 0.45 * cyc);
        final amp = size.width * (0.025 + 0.07 * f);
        final x = x0 + math.sin(f * 5.2 + time * _w + ph) * amp + math.sin(time * _w + ph * 2) * size.width * 0.02 * f;
        s == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      final a = (0.17 + 0.17 * strength) * life;
      final top = base.dy - rise;
      blur
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5 + 4 * strength
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: a), color.withValues(alpha: 0)],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromLTRB(0, top, size.width, base.dy));
      canvas.drawPath(path, blur);
    }
  }

  @override
  bool shouldRepaint(_SteamPainter old) => old.strength != strength || old.color != color;
}
