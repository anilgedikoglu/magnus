// lib/presentation/tarot/tarot_table.dart
//
// Tarot masası (2026-11-06, Grok/Codex: "masa/örtü yok", kartlar düz zeminde duruyordu).
// Koyu mor kadife örtü: merkezden yayılan derinlik, ince altın mühür halkaları ve yıldız,
// kenarlarda karanlık. Statik (her karede çizilmez; RepaintBoundary).

import 'dart:math' as math;

import 'package:flutter/material.dart';

class TarotTable extends StatelessWidget {
  const TarotTable({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const RepaintBoundary(child: CustomPaint(painter: _VelvetPainter())),
      child,
    ]);
  }
}

class _VelvetPainter extends CustomPainter {
  const _VelvetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Kadife: merkez açık mor → koyu kenar
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.15),
          radius: 0.95,
          colors: [Color(0xFF3A1458), Color(0xFF1E0A30), Color(0xFF0A0412)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    // Kumaş dokusu: çok ince çapraz iplik (düşük opaklık)
    final iplik = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), iplik);
    }
    // Mühür: deste hizasında ince altın halkalar + sekiz köşeli yıldız
    final c = Offset(size.width / 2, size.height * 0.62);
    final r = math.min(size.width, size.height) * 0.36;
    final altin = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x40D4AF37)
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, r, altin);
    canvas.drawCircle(c, r * 0.93, altin..color = const Color(0x28D4AF37));
    canvas.drawCircle(c, r * 0.55, altin..color = const Color(0x22D4AF37));
    final yildiz = Path();
    for (var i = 0; i < 16; i++) {
      final a = -math.pi / 2 + i * math.pi / 8;
      final rr = i.isEven ? r * 0.9 : r * 0.58;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? yildiz.moveTo(p.dx, p.dy) : yildiz.lineTo(p.dx, p.dy);
    }
    yildiz.close();
    canvas.drawPath(
        yildiz,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0x1FD4AF37)
          ..strokeWidth = 1);
    // Vinyet
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: 1.0,
          colors: [Color(0x00000000), Color(0x99000000)],
          stops: [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_VelvetPainter old) => false;
}
