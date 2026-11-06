// lib/core/widgets/unlock_flash.dart
//
// Kilitli kutu açıldığı an (2026-11-06, Grok/Codex: Kısmetim/Arabam/Evim'de "kilidin
// açıldığı an sadece çapraz geçiş"). [revealed] false→true olunca bir kez: kutunun
// üzerinden çapraz bir ışık şeridi geçer ve çevresinde renkli bir hale parlayıp söner.
// Baştan açık gelen kutularda (sayfa yeniden açılınca) oynamaz. Azaltılmış harekette yok.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class UnlockFlash extends StatefulWidget {
  const UnlockFlash({
    super.key,
    required this.revealed,
    required this.color,
    required this.child,
    this.radius = 12,
  });

  final bool revealed;
  final Color color;
  final double radius;
  final Widget child;

  @override
  State<UnlockFlash> createState() => _UnlockFlashState();
}

class _UnlockFlashState extends State<UnlockFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    value: 1, // baştan açık kutu: efekt yok
  );

  @override
  void didUpdateWidget(UnlockFlash old) {
    super.didUpdateWidget(old);
    if (!old.revealed && widget.revealed && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // Ağaç şekli her zaman aynı (DecoratedBox > Stack > [child, ...]): flaş başlarken/biterken
        // çocuğun durumu (AnimatedContainer, AnimatedSwitcher, kayan yazı) sıfırlanmaz.
        final t = _c.value;
        final glow = t >= 1 ? 0.0 : math.sin(t * math.pi); // 0→1→0
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: glow <= 0
                ? const []
                : [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.55 * glow),
                      blurRadius: 6 + 16 * glow,
                      spreadRadius: 1.5 * glow,
                    ),
                  ],
          ),
          child: Stack(children: [
            child!,
            if (t < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.radius),
                    child: CustomPaint(painter: _SheenPainter(t: t)),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Çapraz ışık şeridi soldan sağa geçer.
    final band = size.height * 1.6;
    final x = -band + (size.width + band * 2) * Curves.easeInOutCubic.transform(t);
    final rect = Rect.fromLTWH(x - band, 0, band * 2, size.height);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: const GradientRotation(-0.35),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t;
}
