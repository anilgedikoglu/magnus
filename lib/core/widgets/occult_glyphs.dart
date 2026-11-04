// lib/core/widgets/occult_glyphs.dart
//
// "Gece Grimuarı" çizgi glif seti (2026-11). Material'ın genel ikonları yerine
// uygulamaya özgü, tek elden çıkmış okült işaretler. Hepsi 24'lük ızgarada, aynı
// çizgi kalınlığında (1.5), yuvarlak uç/birleşim; dolgu yalnız göz bebeği gibi küçük
// odaklarda. Font yok, PNG yok → her boyutta keskin, renk `color` ile.
//
// Kullanım: OccultGlyphIcon(OccultGlyph.eye, color: AppColors.gold, size: 32)
// GlyphBuilder ile: (c, s) => OccultGlyphIcon(OccultGlyph.key, color: c, size: s)

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum OccultGlyph {
  /// Her şeyi gören göz — "Genel".
  eye,

  /// İnce hançerle delinmiş kalp — "Aşk".
  heart,

  /// Mühürlü anahtar — "Kariyer".
  key,

  /// Şifalı dal — "Sağlık".
  sprig,

  /// Dört köşeli pusula yıldızı + iç halka — "Yön / genel dert".
  compass,

  /// Hilal + küçük yıldız — gece / maneviyat.
  moon,
}

class OccultGlyphIcon extends StatelessWidget {
  final OccultGlyph glyph;
  final Color color;
  final double size;

  const OccultGlyphIcon(this.glyph, {super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: OccultGlyphPainter(glyph, color)),
    );
  }
}

class OccultGlyphPainter extends CustomPainter {
  final OccultGlyph glyph;
  final Color color;
  const OccultGlyphPainter(this.glyph, this.color);

  static const double stroke = 1.5; // ızgara birimi

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 24.0;
    canvas.save();
    canvas.translate((size.width - 24 * k) / 2, (size.height - 24 * k) / 2);
    canvas.scale(k);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (glyph) {
      case OccultGlyph.eye:
        _eye(canvas, line, fill);
      case OccultGlyph.heart:
        _heart(canvas, line, fill);
      case OccultGlyph.key:
        _key(canvas, line, fill);
      case OccultGlyph.sprig:
        _sprig(canvas, line);
      case OccultGlyph.compass:
        _compass(canvas, line, fill);
      case OccultGlyph.moon:
        _moon(canvas, line, fill);
    }
    canvas.restore();
  }

  void _eye(Canvas c, Paint line, Paint fill) {
    final lid = Path()
      ..moveTo(2.6, 13)
      ..quadraticBezierTo(12, 4.6, 21.4, 13)
      ..quadraticBezierTo(12, 21.4, 2.6, 13)
      ..close();
    c.drawPath(lid, line);
    c.drawCircle(const Offset(12, 13), 3.3, line);
    c.drawCircle(const Offset(12, 13), 1.15, fill);
    // Üç ışın — tepe ortada uzun, yanlar kısa.
    c.drawLine(const Offset(12, 2.6), const Offset(12, 5.2), line);
    c.drawLine(const Offset(6.6, 4.4), const Offset(7.7, 6.6), line);
    c.drawLine(const Offset(17.4, 4.4), const Offset(16.3, 6.6), line);
  }

  void _heart(Canvas c, Paint line, Paint fill) {
    final h = Path()
      ..moveTo(12, 20.2)
      ..cubicTo(6.4, 16.2, 3.4, 13.0, 3.4, 9.3)
      ..cubicTo(3.4, 6.7, 5.3, 4.9, 7.6, 4.9)
      ..cubicTo(9.4, 4.9, 11.0, 6.0, 12, 7.7)
      ..cubicTo(13.0, 6.0, 14.6, 4.9, 16.4, 4.9)
      ..cubicTo(18.7, 4.9, 20.6, 6.7, 20.6, 9.3)
      ..cubicTo(20.6, 13.0, 17.6, 16.2, 12, 20.2)
      ..close();
    c.drawPath(h, line);
    // İnce hançer: sol alttan sağ üste; kalbin içinden geçen kısım çizilmez
    // (kalp konturunu bozmasın) — yalnız sap ve uç dışarıda görünür.
    c.drawLine(const Offset(3.0, 21.0), const Offset(6.0, 18.0), line); // sap
    c.drawLine(const Offset(3.9, 16.9), const Offset(7.1, 20.1), line); // siper
    c.drawLine(const Offset(18.6, 5.4), const Offset(21.2, 2.8), line); // uç
    c.drawCircle(const Offset(2.5, 21.5), 0.55, fill); // topuz
  }

  void _key(Canvas c, Paint line, Paint fill) {
    c.drawCircle(const Offset(7.2, 12), 3.9, line);
    c.drawCircle(const Offset(7.2, 12), 1.2, fill);
    c.drawLine(const Offset(11.1, 12), const Offset(21.0, 12), line);
    c.drawLine(const Offset(17.6, 12), const Offset(17.6, 15.4), line);
    c.drawLine(const Offset(20.4, 12), const Offset(20.4, 14.4), line);
    // Halkanın tepesinde küçük mühür çentiği.
    c.drawLine(const Offset(7.2, 6.4), const Offset(7.2, 8.1), line);
  }

  void _sprig(Canvas c, Paint line) {
    final stem = Path()
      ..moveTo(12, 21.2)
      ..quadraticBezierTo(11.2, 13.5, 12, 3.4);
    c.drawPath(stem, line);
    Path leaf(double y, double dir, double len) {
      final tipX = 12 + dir * len;
      final tipY = y - len * 0.55;
      return Path()
        ..moveTo(11.8, y)
        ..quadraticBezierTo(12 + dir * len * 0.30, y - len * 0.85, tipX, tipY)
        ..quadraticBezierTo(12 + dir * len * 0.80, y + len * 0.10, 11.8, y);
    }

    c.drawPath(leaf(16.6, -1, 6.0), line);
    c.drawPath(leaf(13.4, 1, 6.0), line);
    c.drawPath(leaf(9.6, -1, 4.6), line);
    c.drawPath(leaf(7.0, 1, 4.0), line);
  }

  void _compass(Canvas c, Paint line, Paint fill) {
    final star = Path()
      ..moveTo(12, 2.2)
      ..lineTo(13.7, 10.3)
      ..lineTo(21.8, 12)
      ..lineTo(13.7, 13.7)
      ..lineTo(12, 21.8)
      ..lineTo(10.3, 13.7)
      ..lineTo(2.2, 12)
      ..lineTo(10.3, 10.3)
      ..close();
    c.drawPath(star, line);
    c.drawCircle(const Offset(12, 12), 6.4, line..strokeWidth = stroke * 0.8);
    line.strokeWidth = stroke;
    c.drawCircle(const Offset(12, 12), 1.0, fill);
  }

  void _moon(Canvas c, Paint line, Paint fill) {
    // Hilal: dış daire yayı + içe kayık daire yayı.
    const outer = Offset(11.0, 12.5);
    const ro = 8.6;
    const inner = Offset(14.6, 10.2);
    const ri = 7.0;
    // Kesişim noktaları (iki daire) — sayısal.
    final d = (inner - outer).distance;
    final a = (ro * ro - ri * ri + d * d) / (2 * d);
    final h = math.sqrt(math.max(0, ro * ro - a * a));
    final dir = (inner - outer) / d;
    final mid = outer + dir * a;
    final perp = Offset(-dir.dy, dir.dx);
    final p1 = mid + perp * h;
    final p2 = mid - perp * h;
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..arcToPoint(p2, radius: const Radius.circular(ro), largeArc: true, clockwise: true)
      ..arcToPoint(p1, radius: const Radius.circular(ri), largeArc: true, clockwise: false)
      ..close();
    c.drawPath(path, line);
    // Küçük dört köşeli yıldız.
    // Hilalin boşluğunda (iç dairenin içinde) — uçlara değmez.
    const sc = Offset(16.4, 9.6);
    final s = Path()
      ..moveTo(sc.dx, sc.dy - 2.0)
      ..lineTo(sc.dx + 0.6, sc.dy - 0.6)
      ..lineTo(sc.dx + 2.0, sc.dy)
      ..lineTo(sc.dx + 0.6, sc.dy + 0.6)
      ..lineTo(sc.dx, sc.dy + 2.0)
      ..lineTo(sc.dx - 0.6, sc.dy + 0.6)
      ..lineTo(sc.dx - 2.0, sc.dy)
      ..lineTo(sc.dx - 0.6, sc.dy - 0.6)
      ..close();
    c.drawPath(s, fill);
  }

  @override
  bool shouldRepaint(covariant OccultGlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
