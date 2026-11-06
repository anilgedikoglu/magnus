import 'dart:math';
import 'package:flutter/material.dart';

/// Zarif, SÜREKLİ kum saati bekleme animasyonu (Anıl, 2026-11-06 — Codex incelemesiyle).
///
/// Eski sürüm kum bitince GÖRSEL SIÇRAMAYLA baştan başlıyordu. Bu sürümde kum aşağı akar,
/// alt hazne dolunca kum saati 180° DÖNER ve diğer yönden akmaya devam eder — dikişsiz.
/// Dönüşün sonu (angle=π, alt dolu) ile döngü başı (angle=0, üst dolu) birebir aynı görüntüyü
/// verir (cam + kapaklar + kum konturları 180° simetrik) → reset görünmez.
///
/// API değişmedi: [size], [color], [animate]. (color'dan tüm tonlar türetilir — her ekranda
/// farklı renkle çağrılabilir.)
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
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000), // 2400 akış + 600 dönüş
  );
  late _HgGeometry _geo = _HgGeometry(widget.size);
  bool _reduced = false;

  @override
  void didUpdateWidget(ElegantHourglass old) {
    super.didUpdateWidget(old);
    if (old.size != widget.size) _geo = _HgGeometry(widget.size);
    if (old.animate != widget.animate) _apply();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced != _reduced) {
      _reduced = reduced;
      _apply();
    } else if (!_ctrl.isAnimating && widget.animate && !_reduced) {
      _apply();
    }
  }

  void _apply() {
    if (widget.animate && !_reduced) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = !widget.animate || _reduced;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _HourglassPainter(
          anim: _ctrl,
          geo: _geo,
          color: widget.color,
          still: still,
        ),
      ),
    );
  }
}

/// Kum saati iç geometrisi + alan→yükseklik tablosu (boyut başına bir kez hesaplanır).
class _HgGeometry {
  _HgGeometry(this.s) {
    topY = s * 0.09;
    botY = s * 0.91;
    neckY = s * 0.50;
    halfW = s * 0.36;
    halfNeck = s * 0.05;
    _buildTable();
  }

  final double s;
  late final double topY, botY, neckY, halfW, halfNeck;

  // Kümülatif kum alanı tablosu (topY..botY), ve bir haznenin alanı A.
  final List<double> _ys = [];
  final List<double> _cum = [];
  late final double area; // tek hazne alanı

  /// Belirli Y'deki iç cam yarı genişliği — boyuna doğru daralan, simetrik "bel".
  double hwAt(double y) {
    final d = (y - neckY).abs();
    final maxD = neckY - topY;
    final u = (d / maxD).clamp(0.0, 1.0);
    return halfNeck + (halfW - halfNeck) * pow(u, 1.5).toDouble();
  }

  void _buildTable() {
    const m = 96;
    double acc = 0;
    double prevY = topY;
    _ys.add(topY);
    _cum.add(0);
    for (var k = 1; k <= m; k++) {
      final y = topY + (botY - topY) * k / m;
      final midY = (prevY + y) / 2;
      acc += 2 * hwAt(midY) * (y - prevY);
      _ys.add(y);
      _cum.add(acc);
      prevY = y;
    }
    // neckY tam ortada → tek hazne alanı toplamın yarısı.
    area = acc / 2;
  }

  /// Kümülatif alan (topY'den) hedefe eşit olduğu Y (lineer interpolasyon).
  double yForCum(double target) {
    target = target.clamp(0.0, _cum.last);
    // ikili arama
    var lo = 0, hi = _cum.length - 1;
    while (lo + 1 < hi) {
      final mid = (lo + hi) >> 1;
      if (_cum[mid] < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final c0 = _cum[lo], c1 = _cum[hi];
    final t = (c1 - c0).abs() < 1e-6 ? 0.0 : (target - c0) / (c1 - c0);
    return _ys[lo] + (_ys[hi] - _ys[lo]) * t;
  }
}

class _HourglassPainter extends CustomPainter {
  _HourglassPainter({
    required this.anim,
    required this.geo,
    required this.color,
    required this.still,
  }) : super(repaint: anim);

  final Animation<double> anim;
  final _HgGeometry geo;
  final Color color;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    // Faz: 0..0.8 akış (q: 0→1), 0.8..1 dönüş (q=1, angle 0→π).
    double q, angle;
    if (still) {
      q = 0.5;
      angle = 0;
    } else if (t < 0.8) {
      q = t / 0.8;
      angle = 0;
    } else {
      q = 1;
      final f = (t - 0.8) / 0.2;
      angle = pi * (3 * f * f - 2 * f * f * f); // smoothstep
    }

    final cx = size.width / 2;
    final cyY = size.height / 2;

    // Ekrana sabit, çok hafif ışıma (dönüşte kaymasın → simetri bozulmaz).
    canvas.drawCircle(
      Offset(cx, cyY),
      geo.halfW * 1.15,
      Paint()
        ..color = color.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.save();
    canvas.translate(cx, cyY);
    canvas.rotate(angle);
    canvas.translate(-cx, -cyY);

    _paintSand(canvas, q, t);
    _paintGlass(canvas);

    canvas.restore();
  }

  // ── Kum ────────────────────────────────────────────────────────────────────
  void _paintSand(Canvas canvas, double q, double t) {
    final cx = geo.s / 2;
    final a = geo.area;
    final sand = Paint()
      ..color = Color.lerp(color, Colors.white, 0.10)!.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    // Üst kum: [topSurf, neckY], alan A*(1-q) → cum(topSurf)=A*q.
    if (q < 0.995) {
      final topSurf = geo.yForCum(a * q);
      final path = _bulbPath(topSurf, geo.neckY, domeAt: topSurf, dome: 0);
      canvas.drawPath(path, sand);
    }

    // Alt kum: [botSurf, botY], alan A*q → cum(botSurf)=A*(2-q). Üstte hafif kubbe.
    if (q > 0.005) {
      final botSurf = geo.yForCum(a * (2 - q));
      final dome = (geo.hwAt(botSurf) * 0.18).clamp(0.0, geo.s * 0.03);
      final path = _bulbPath(botSurf, geo.botY, domeAt: botSurf, dome: dome);
      canvas.drawPath(path, sand);
    }

    // Akan kum şeridi + taneler (yalnız akışta; uçlarda yumuşak açılıp kapanır).
    if (!still && t < 0.8 && q > 0.02 && q < 0.98) {
      final botSurf = geo.yForCum(a * (2 - q));
      final fade = (sin(pi * (q.clamp(0.0, 1.0))) * 1.4).clamp(0.0, 1.0);
      final streamPaint = Paint()
        ..color = Color.lerp(color, Colors.white, 0.2)!.withValues(alpha: 0.55 * fade)
        ..style = PaintingStyle.fill;
      final sw = geo.s * 0.016;
      final top = geo.neckY + geo.s * 0.01;
      final bottom = botSurf - geo.s * 0.005;
      if (bottom > top) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(cx - sw, top, cx + sw, bottom),
            Radius.circular(sw),
          ),
          streamPaint,
        );
        // 2 küçük tane, zamana bağlı aşağı akar
        final grainPaint = Paint()..color = streamPaint.color.withValues(alpha: 0.75 * fade);
        for (var i = 0; i < 2; i++) {
          final ph = ((t * 6) + i * 0.5) % 1.0;
          final gy = top + (bottom - top) * ph;
          canvas.drawCircle(Offset(cx, gy), sw * 0.9, grainPaint);
        }
      }
    }
  }

  /// Verilen y aralığında, cam duvarlarına oturan kum poligonu. [dome]>0 ise üst kenar
  /// (domeAt) ortada hafif kubbeli.
  Path _bulbPath(double yTop, double yBot, {required double domeAt, required double dome}) {
    final cx = geo.s / 2;
    const n = 14;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final y = yTop + (yBot - yTop) * i / n;
      var yy = y;
      if (dome > 0 && i == 0) yy = y; // üst kenarı ayrı işleyeceğiz
      final hw = geo.hwAt(yy);
      left.add(Offset(cx - hw, yy));
      right.add(Offset(cx + hw, yy));
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    // Üst kenar kubbesi (alt kum): düz kenar yerine ortada yukarı doğru çıkıntı.
    if (dome > 0) {
      final hw = geo.hwAt(domeAt);
      path.moveTo(cx - hw, domeAt);
      path.quadraticBezierTo(cx, domeAt - dome, cx + hw, domeAt);
    }
    path.close();
    return path;
  }

  // ── Cam + kapaklar (180° simetrik) ──────────────────────────────────────────
  void _paintGlass(Canvas canvas) {
    final cx = geo.s / 2;
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = geo.s * 0.028
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Sol + sağ cam duvar (eğri "bel").
    const n = 20;
    Path wall(double sign) {
      final p = Path();
      for (var i = 0; i <= n; i++) {
        final y = geo.topY + (geo.botY - geo.topY) * i / n;
        final x = cx + sign * geo.hwAt(y);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p;
    }

    canvas.drawPath(wall(-1), stroke);
    canvas.drawPath(wall(1), stroke);

    // Kapaklar: üst ve alt, aynı yuvarlatılmış kısa çubuk (simetrik).
    final capW = geo.halfW + geo.s * 0.02;
    final capStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = geo.s * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - capW, geo.topY), Offset(cx + capW, geo.topY), capStroke);
    canvas.drawLine(Offset(cx - capW, geo.botY), Offset(cx + capW, geo.botY), capStroke);

    // İnce cam parlaması (tek, sol duvarda).
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = geo.s * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - geo.halfW * 0.72, geo.topY + geo.s * 0.08),
      Offset(cx - geo.halfNeck * 1.4, geo.neckY - geo.s * 0.06),
      shine,
    );
  }

  @override
  bool shouldRepaint(_HourglassPainter old) =>
      old.color != color || old.geo != geo || old.still != still;
}

/// Yalnız görsel doğrulama: kum saatini sabit bir faz [t] (0..1) ile çizer (canlı controller
/// olmadan → testte bekleyen zamanlayıcı yok).
@visibleForTesting
Widget debugHourglassFrame({required double size, required Color color, required double t}) {
  return CustomPaint(
    size: Size(size, size),
    painter: _HourglassPainter(
      anim: AlwaysStoppedAnimation<double>(t),
      geo: _HgGeometry(size),
      color: color,
      still: false,
    ),
  );
}

/// Flip animasyonlu eski ad — artık ana [ElegantHourglass] zaten dikişsiz döner.
class FlipHourglass extends StatelessWidget {
  final double size;
  final Color color;
  final Duration flipInterval; // yok sayılır (geriye dönük uyumluluk)

  const FlipHourglass({
    super.key,
    this.size = 56,
    this.color = Colors.white,
    this.flipInterval = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) => ElegantHourglass(size: size, color: color);
}

/// Pulse (hafif büyüyüp küçülen) sarmalayıcı.
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
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
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

/// Numeroloji'deki dönen kalıp — artık kum saati zaten kendi içinde dönüyor, bu yüzden
/// yalnız hafif bir nabızla sarmalar (çift 360° dönüş gürültü yapıyordu).
class SpinningHourglass extends StatelessWidget {
  final double size;
  final Color color;

  const SpinningHourglass({
    super.key,
    this.size = 64,
    this.color = const Color(0xFFBBAAFF),
  });

  @override
  Widget build(BuildContext context) =>
      PulsingHourglass(size: size, color: color);
}
