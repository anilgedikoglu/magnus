// lib/core/widgets/starfield_overlay.dart
//
// Nebula arka planının üstünde performanslı yıldız katmanı:
//   • Noktasal yıldızlar twinkle yapar (ışıyıp kaybolur; sönenler yeni yere atlar).
//   • Nadiren, uzakta bir kayan yıldız geçer.
// (Gökyüzü dalgalanması / alacalı renk → living_nebula.dart shader'ı.
//  Eski aurora kurdeleleri + haleler 2026-11-04'te kullanıcı isteğiyle kaldırıldı.)
//
// Mimari (Codex ile danışıldı + eleştirildi, 2026-11-04):
//   - Tek Ticker → _time; painter t'ye bağlı SAF fonksiyon (Random/setState yok).
//   - Yıldız konumları ve kayan yıldız takvimi seed'li Random ile BİR KEZ üretilir.
//   - IgnorePointer + RepaintBoundary; TickerMode ve reduced-motion'a saygılı.

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class StarfieldOverlay extends StatefulWidget {
  /// Üretilecek maksimum yıldız; ekranda gösterilen sayı alana göre
  /// (telefon ~90, tablet ~170) paint() içinde belirlenir.
  final int starCount;
  final int seed;

  const StarfieldOverlay({super.key, this.starCount = 170, this.seed = 7312})
      : assert(starCount > 0);

  /// Test/görsel doğrulama için: ilk kayan yıldız.
  @visibleForTesting
  static ({double start, double duration, double x0, double y0, double dx, double dy})
      debugFirstShot({int seed = 7312, int starCount = 170}) {
    final s = _SkyModel(seed, starCount).shots.first;
    return (
      start: s.startT,
      duration: s.duration,
      x0: s.x0,
      y0: s.y0,
      dx: s.dx,
      dy: s.dy,
    );
  }

  @override
  State<StarfieldOverlay> createState() => _StarfieldOverlayState();
}

/// Statik koyulaştırma (shader yokken / yüklenirken yedek — LivingNebulaBackground):
///   1) Dikey gradient (üst/alt ~%55, orta ~%47) — shader'ın koyuluğuna yakın.
///   2) Ekran oranına normalize ELİPTİK vinyet: merkez korunur, kenar/köşeler koyu.
/// Not (Codex incelemesi): düz RadialGradient yarıçapı kısa kenara göre çizildiği
/// için uzun ekranlarda üst/alt aşırı kararıyordu → _FitEllipse ile düzeltildi.
class SkyDarkenOverlay extends StatelessWidget {
  const SkyDarkenOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.5, 1.0],
              colors: [
                Color(0x8C000000), // üst ~%55
                Color(0x78000000), // orta ~%47
                Color(0x8C000000), // alt ~%55
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.75,
              stops: [0.0, 0.55, 1.0],
              colors: [
                Color(0x00000000),
                Color(0x1A000000),
                Color(0x99000000),
              ],
              transform: _FitEllipse(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Daireyi kutu oranına göre elipse çevirir (merkez etrafında ölçekler).
class _FitEllipse extends GradientTransform {
  const _FitEllipse();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final w = bounds.width, h = bounds.height;
    if (w <= 0 || h <= 0) return Matrix4.identity();
    final sx = w > h ? w / h : 1.0;
    final sy = h > w ? h / w : 1.0;
    final c = bounds.center;
    return Matrix4.translationValues(c.dx, c.dy, 0)
      ..multiply(Matrix4.diagonal3Values(sx, sy, 1))
      ..multiply(Matrix4.translationValues(-c.dx, -c.dy, 0));
  }
}

class _StarfieldOverlayState extends State<StarfieldOverlay>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  late final _SkyModel _sky;
  final ValueNotifier<double> _time = ValueNotifier<double>(3.0);
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _sky = _SkyModel(widget.seed, widget.starCount);
    // Tek ticker — mutlak geçen süreyi saniye olarak _time'a yazar.
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1e6;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion: animasyonu durdur, yıldızları statik sabit karede göster.
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tk = _ticker;
    if (tk != null) {
      if (_reducedMotion) {
        if (tk.isActive) tk.stop();
        _time.value = 3.0; // sabit kare
      } else if (!tk.isActive) {
        tk.start();
      }
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SkyPainter(_time, _sky, animate: !_reducedMotion),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ── Model (bir kez üretilir) ─────────────────────────────────────────────────

class _Star {
  final double x, y; // normalize 0..1
  final double radius; // px
  final double period; // s (twinkle döngüsü)
  final double phase; // rad (senkron olmasınlar)
  final double minA, maxA; // opaklık zarfı
  final double warmth; // 0 beyaz .. 1 sıcak ton
  final double sharp; // >1 → daha keskin nabız
  /// Tamamen sönen yıldızlar her döngüde yeni rastgele konuma geçer
  /// (geçiş, opaklık tam 0 iken olur → görünmez).
  final bool relocate;
  const _Star(this.x, this.y, this.radius, this.period, this.phase, this.minA,
      this.maxA, this.warmth, this.sharp, this.relocate);
}

class _Shot {
  final double startT, duration; // s
  final double x0, y0; // normalize başlangıç
  final double dx, dy; // normalize yön × uzunluk
  final double thickness; // px
  final double maxA;
  const _Shot(this.startT, this.duration, this.x0, this.y0, this.dx, this.dy,
      this.thickness, this.maxA);
}

class _SkyModel {
  final int seed;
  final List<_Star> stars;
  final List<_Shot> shots;

  /// Takvim döngüsü: son kaymadan 12 sn sonra liste baştan tekrar eder
  /// (Codex incelemesi: ~22 dk sonra kayan yıldızlar bitiyordu).
  late final double shotCycle = shots.last.startT + shots.last.duration + 12;

  _SkyModel._(this.seed, Random r, int count)
      : stars = _mkStars(r, count),
        shots = _mkShots(r);

  factory _SkyModel(int seed, int count) =>
      _SkyModel._(seed, Random(seed), count);

  static List<_Star> _mkStars(Random r, int n) {
    return List.generate(n, (_) {
      final bright = r.nextDouble() < 0.18; // birkaç tane daha parlak
      final radius =
          bright ? 1.1 + r.nextDouble() * 0.9 : 0.4 + r.nextDouble() * 0.8;
      final maxA =
          bright ? 0.85 + r.nextDouble() * 0.15 : 0.35 + r.nextDouble() * 0.45;
      // Yarısı tamamen kaybolsun ("ışıyıp kaybolur"), yarısı hafif parıldasın.
      final fadeOut = r.nextDouble() < 0.5;
      final minA = fadeOut ? 0.0 : 0.05 + r.nextDouble() * 0.18;
      final period = 1.6 + r.nextDouble() * 3.4;
      final phase = r.nextDouble() * 2 * pi;
      final warmth = r.nextDouble() < 0.25 ? r.nextDouble() * 0.8 : 0.0;
      final sharp = 0.8 + r.nextDouble() * 1.8;
      return _Star(r.nextDouble(), r.nextDouble(), radius, period, phase, minA,
          maxA, warmth, sharp, fadeOut);
    });
  }

  // Seyrek kayan yıldız zamanlaması — deterministik.
  static List<_Shot> _mkShots(Random r) {
    final shots = <_Shot>[];
    double t = 6 + r.nextDouble() * 9; // ilk kayma 6..15 sn sonra
    for (var i = 0; i < 80; i++) {
      final dur = 0.7 + r.nextDouble() * 0.7; // 0.7..1.4 sn
      // "Uzakta": üst bölge, ince ve soluk.
      final x0 = 0.04 + r.nextDouble() * 0.55; // sol/orta üst
      final y0 = 0.04 + r.nextDouble() * 0.38; // üst %42
      final angle = (22 + r.nextDouble() * 24) * pi / 180; // sağ-aşağı eğim
      // Görsel doğrulama: 0.11..0.26 telefonda fark edilmiyordu → 0.16..0.32.
      final len = 0.16 + r.nextDouble() * 0.16;
      final dx = cos(angle) * len;
      final dy = sin(angle) * len;
      final thickness = 0.9 + r.nextDouble() * 0.6;
      final maxA = 0.38 + r.nextDouble() * 0.34;
      shots.add(_Shot(t, dur, x0, y0, dx, dy, thickness, maxA));
      t += 9 + r.nextDouble() * 15; // sonraki 9..24 sn sonra
    }
    return shots;
  }

  /// Deterministik tamsayı hash → [0,1). Seed dahil (Codex incelemesi).
  double hash01(int i, int c, int salt) {
    var x = (i * 374761393 + c * 668265263 + (salt + seed * 7919) * 1442695041) &
        0x7fffffff;
    x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
    x = (x ^ (x >> 16)) & 0x7fffffff;
    return x / 0x80000000;
  }
}

// ── Yıldız + kayan yıldız painter'ı (ekran hızında) ─────────────────────────

class _SkyPainter extends CustomPainter {
  final ValueNotifier<double> time;
  final _SkyModel sky;
  final bool animate;
  _SkyPainter(this.time, this.sky, {required this.animate})
      : super(repaint: time);

  static const _white = Color(0xFFFFFFFF);
  static const _warm = Color(0xFFFFE6B8);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    final p = Paint()..style = PaintingStyle.fill;

    // Ekran alanına göre yoğunluk: telefon ~90, tablet en fazla starCount.
    // Alt sınır min(60, n): starCount<60 verilirse clamp ArgumentError atmasın.
    final n = sky.stars.length;
    final visible = ((w * h) / 3650).round().clamp(min(60, n), n);

    for (var i = 0; i < visible; i++) {
      final s = sky.stars[i];
      final double raw = animate
          ? (sin(2 * pi * (t / s.period) + s.phase) * 0.5 + 0.5)
          : (sin(s.phase) * 0.5 + 0.5);
      final env = pow(raw, s.sharp).toDouble(); // 0..1
      final a = s.minA + (s.maxA - s.minA) * env;
      if (a <= 0.02) continue;

      // Sönen yıldız: döngü sınırı sinüsün dibine (opaklık 0) hizalı →
      // u tamsayıyı geçtiği an yıldız görünmezken yeni konuma atlar.
      double nx = s.x, ny = s.y;
      if (animate && s.relocate) {
        final u = t / s.period + s.phase / (2 * pi) - 0.75;
        final cycle = u.floor();
        nx = 0.01 + 0.98 * sky.hash01(i, cycle, 1);
        ny = 0.01 + 0.98 * sky.hash01(i, cycle, 2);
      }
      final cx = nx * w, cy = ny * h;
      final col = Color.lerp(_white, _warm, s.warmth)!;

      // Parlak yıldızlara hafif halo (saveLayer/blur YOK — sadece büyük soluk daire).
      if (s.radius > 1.0) {
        p.color = col.withValues(alpha: a * 0.16);
        canvas.drawCircle(Offset(cx, cy), s.radius * 2.6, p);
      }
      p.color = col.withValues(alpha: a);
      canvas.drawCircle(Offset(cx, cy), s.radius, p);
    }

    if (animate) _drawShot(canvas, w, h, t);
  }

  void _drawShot(Canvas canvas, double w, double h, double time) {
    final t = time % sky.shotCycle; // döngüsel takvim
    _Shot? cur;
    for (final sh in sky.shots) {
      if (sh.startT > t) break; // zaman sıralı
      if (t <= sh.startT + sh.duration) {
        cur = sh;
        break;
      }
    }
    if (cur == null) return;

    final prog = (t - cur.startT) / cur.duration; // 0..1
    final fade = sin(pi * prog); // 0→1→0 (giriş/çıkış sönümü)
    final alpha = cur.maxA * fade;
    if (alpha <= 0.02) return;

    // Kuyruk yolun %45'i (görsel doğrulama: %16 telefonda çentik gibi kalıyordu).
    // Başta kuyruk başlangıç noktasından taşmaz → meteor "doğup uzar".
    const tailLen = 0.45;
    final tailProg = max(0.0, prog - tailLen);
    final headX = (cur.x0 + cur.dx * prog) * w;
    final headY = (cur.y0 + cur.dy * prog) * h;
    final tailX = (cur.x0 + cur.dx * tailProg) * w;
    final tailY = (cur.y0 + cur.dy * tailProg) * h;

    final trail = Paint()
      ..strokeWidth = cur.thickness
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset(tailX, tailY),
        Offset(headX, headY),
        [const Color(0x00FFFFFF), _white.withValues(alpha: alpha)],
      );
    canvas.drawLine(Offset(tailX, tailY), Offset(headX, headY), trail);

    // Baş: hafif parıltı (büyük soluk daire, blur yok) + parlak çekirdek.
    final head = Offset(headX, headY);
    canvas.drawCircle(head, cur.thickness * 2.6,
        Paint()..color = _white.withValues(alpha: alpha * 0.22));
    canvas.drawCircle(head, cur.thickness * 0.95,
        Paint()..color = _white.withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.animate != animate;
}
