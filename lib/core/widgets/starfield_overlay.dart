// lib/core/widgets/starfield_overlay.dart
//
// Nebula arka planının üstünde performanslı "kozmik gökyüzü" katmanı:
//   • Noktasal yıldızlar twinkle yapar (ışıyıp kaybolur; sönenler yeni yere atlar).
//   • Nadiren, uzakta bir kayan yıldız geçer.
//   • Kuzey ışığı perdeleri: yavaş dalgalanan, alt kenarı parlak, yukarı sönen
//     mat mor/teal kurdeleler (drawVertices, blur yok).
//   • Halelenmeler: ara ara bir yerde yavaşça açılıp sönen yumuşak ışık halesi.
//
// Mimari (Codex ile danışıldı + eleştirildi, 2026-11-04):
//   - Tek Ticker → _time (yıldızlar, ekran hızında) + _auroraTime (aurora/hale,
//     1/30 sn zaman dilimleriyle — hareket çok yavaş, judder olmaz).
//   - Painter'lar t'ye bağlı SAF fonksiyon: Random / setState / olay üretimi YOK.
//     Tüm takvim ve konumlar seed'li Random ile model kurulurken BİR KEZ üretilir.
//   - Işık: Paint.blendMode = plus (Porter-Duff, Impeller'da ucuz; düşük alpha'da
//     screen ile farkı yok). Blur / saveLayer YOK.
//   - IgnorePointer + iki ayrı RepaintBoundary (aurora / yıldız) + içerik ayrı.
//   - TickerMode ve reduced-motion'a saygılı (hareket durur, hale kapanır).

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class StarfieldOverlay extends StatefulWidget {
  /// Üretilecek maksimum yıldız; ekranda gösterilen sayı alana göre
  /// (telefon ~90, tablet ~170) paint() içinde belirlenir.
  final int starCount;
  final int seed;

  /// Kuzey ışığı perdeleri + halelenmeler.
  final bool aurora;

  const StarfieldOverlay({
    super.key,
    this.starCount = 170,
    this.seed = 7312,
    this.aurora = true,
  }) : assert(starCount > 0);

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

  /// Test/görsel doğrulama için: ilk hale.
  @visibleForTesting
  static ({double start, double duration, double x, double y}) debugFirstHalo(
      {int seed = 7312, int starCount = 170}) {
    final h = _SkyModel(seed, starCount).halos.first;
    return (start: h.startT, duration: h.duration, x: h.x, y: h.y);
  }

  @override
  State<StarfieldOverlay> createState() => _StarfieldOverlayState();
}

/// Nebula arka planını "gizemli" koyulaştırır (yıldız katmanının ALTINA konur):
///   1) Hafif dikey gradient (üst/alt ~%50, orta ~%40 — eski düz %38'den biraz koyu)
///   2) Ekran oranına normalize ELİPTİK vinyet: merkezdeki nebula korunur,
///      kenar/köşeler koyulaşır.
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
                Color(0x80000000), // üst ~%50
                Color(0x66000000), // orta ~%40 (nebula görünür kalsın)
                Color(0x80000000), // alt ~%50
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
  final ValueNotifier<double> _auroraTime = ValueNotifier<double>(3.0);
  int _auroraSlot = -1;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _sky = _SkyModel(widget.seed, widget.starCount);
    // Tek ticker: yıldızlar ekran hızında, aurora/hale 1/30 sn dilimlerinde.
    _ticker = createTicker((elapsed) {
      final sec = elapsed.inMicroseconds / 1e6;
      _time.value = sec;
      final slot = (sec * 30).floor();
      if (slot != _auroraSlot) {
        _auroraSlot = slot;
        _auroraTime.value = slot / 30.0;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion: animasyonu durdur, statik sabit kare göster.
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tk = _ticker;
    if (tk != null) {
      if (_reducedMotion) {
        if (tk.isActive) tk.stop();
        _time.value = 3.0;
        _auroraTime.value = 3.0;
      } else if (!tk.isActive) {
        _auroraSlot = -1; // ticker sıfırdan başlar → dilim sayacı da
        tk.start();
      }
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    _auroraTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = !_reducedMotion;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.aurora)
            RepaintBoundary(
              child: CustomPaint(
                painter: _AuroraPainter(_auroraTime, _sky, animate: animate),
                child: const SizedBox.expand(),
              ),
            ),
          RepaintBoundary(
            child: CustomPaint(
              painter: _SkyPainter(_time, _sky, animate: animate),
              child: const SizedBox.expand(),
            ),
          ),
        ],
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

class _Halo {
  final double startT, duration; // s
  final double x, y; // normalize merkez
  final double rFrac; // kısa kenarın oranı
  final Color color;
  final double peakA;
  const _Halo(this.startT, this.duration, this.x, this.y, this.rFrac,
      this.color, this.peakA);
}

/// Kuzey ışığı perdesi yapılandırması (geometri paint()'te t'den hesaplanır).
class _Ribbon {
  final double base; // parlak alt kenarın normalize y'si
  final double height; // perdenin yukarı uzanımı (normalize)
  final double peakA; // tepe alpha
  final Color top, edge; // üst ton, parlak kenar tonu (tek baskın aile)
  final double x0, x1; // yatay kapsam (normalize), uçlarda söner
  final double p1, p2, p3; // fazlar
  final double speed; // hız çarpanı
  /// Alt kenar yumuşaklığı: 1 = keskin aurora kenarı, >1 = pus bandı (çizgi gibi durmasın).
  final double edgeSoft;
  // Kalıcı tampon (her karede yeniden ayrılmasın).
  final Float32List pos = Float32List(_kCols * _kRows * 2);
  final Int32List cols = Int32List(_kCols * _kRows);
  _Ribbon(this.base, this.height, this.peakA, this.top, this.edge, this.x0,
      this.x1, this.p1, this.p2, this.p3, this.speed, [this.edgeSoft = 1.0]);
}

// Perde ızgarası: 72 sütun × 7 sıra. Sıralar üstten alta; alt kenar parlak/dar,
// yukarı uzun sönüm (gerçek aurora profili). Son sıra kenarın biraz altı (söner).
const int _kCols = 72;
const int _kRows = 7;
const List<double> _kRowS = [0.0, 0.30, 0.58, 0.80, 0.93, 1.0, 1.14];
const List<double> _kRowI = [0.0, 0.10, 0.30, 0.62, 0.92, 1.0, 0.0];
const List<double> _kRowEdgeMix = [0.0, 0.0, 0.10, 0.35, 0.70, 1.0, 1.0];

// Mat palet (neon değil) — uygulamanın mor-pembe kimliğiyle uyumlu.
const Color _kViolet = Color(0xFF7762B5);
const Color _kTeal = Color(0xFF4FA99F);
const Color _kMagenta = Color(0xFFA35B92);

class _SkyModel {
  final int seed;
  final List<_Star> stars;
  final List<_Shot> shots;
  final List<_Halo> halos;
  final List<_Ribbon> ribbons;
  final Uint16List ribbonIndices = _mkIndices();

  /// Döngüler: son olay tamamen bittikten sonra liste baştan tekrar eder
  /// (Codex incelemesi: ~22 dk sonra kayan yıldızlar bitiyordu).
  late final double shotCycle = shots.last.startT + shots.last.duration + 12;
  late final double haloCycle = halos.last.startT + halos.last.duration + 6;

  _SkyModel._(this.seed, Random r, int count)
      : stars = _mkStars(r, count),
        shots = _mkShots(r),
        halos = _mkHalos(r),
        ribbons = _mkRibbons(r);

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

  // Halelenmeler: aralık (10..18 sn) > süre (5..8 sn) → asla üst üste binmez.
  static List<_Halo> _mkHalos(Random r) {
    final halos = <_Halo>[];
    double t = 3 + r.nextDouble() * 4; // ilk hale 3..7 sn sonra
    for (var i = 0; i < 80; i++) {
      final dur = 5 + r.nextDouble() * 3;
      final top = r.nextDouble() < 0.3; // %30 üst şerit, %70 nebula bölgesi
      final x = 0.10 + r.nextDouble() * 0.80;
      final y = top ? 0.04 + r.nextDouble() * 0.14 : 0.46 + r.nextDouble() * 0.38;
      final rFrac = 0.12 + r.nextDouble() * 0.13; // kısa kenarın %12..25'i
      final pick = r.nextDouble();
      final color = pick < 0.5 ? _kViolet : (pick < 0.8 ? _kTeal : _kMagenta);
      // Görsel doğrulama: 0.10..0.18 mat renk + plus ile görünmüyordu → 0.32..0.48.
      final peakA = 0.32 + r.nextDouble() * 0.16;
      halos.add(_Halo(t, dur, x, y, rFrac, color, peakA));
      t += 10 + r.nextDouble() * 8;
    }
    return halos;
  }

  static List<_Ribbon> _mkRibbons(Random r) {
    double ph() => r.nextDouble() * 2 * pi;
    return [
      // Ana perde: üst şerit (dişliler/başlık hizası), mor baskın, kenar hafif teal.
      // Görsel doğrulama: peakA 0.16 neredeyse görünmüyordu → 0.50 (ikinci 0.08 → 0.26).
      _Ribbon(0.115, 0.085, 0.50, _kViolet,
          // Kenar teal-yeşile yakın: gerçek aurora imzası (altta yeşil, üstte mor).
          Color.lerp(_kViolet, _kTeal, 0.7)!, -0.05, 1.05, ph(), ph(), ph(), 1.0),
      // İkinci, çok soluk perde: kutular ile donutlar arası, teal baskın.
      _Ribbon(0.47, 0.06, 0.26, Color.lerp(_kTeal, _kViolet, 0.4)!, _kTeal,
          0.12, 0.95, ph(), ph(), ph(), 0.8, 2.6),
    ];
  }

  static Uint16List _mkIndices() {
    final idx = Uint16List((_kRows - 1) * (_kCols - 1) * 6);
    var k = 0;
    for (var rr = 0; rr < _kRows - 1; rr++) {
      for (var c = 0; c < _kCols - 1; c++) {
        final a = rr * _kCols + c, b = a + 1, d = a + _kCols, e = d + 1;
        idx[k++] = a;
        idx[k++] = b;
        idx[k++] = d;
        idx[k++] = d;
        idx[k++] = b;
        idx[k++] = e;
      }
    }
    return idx;
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

double _smooth(double e0, double e1, double x) {
  final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
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

// ── Kuzey ışığı perdeleri + halelenme painter'ı (30 Hz) ─────────────────────

class _AuroraPainter extends CustomPainter {
  final ValueNotifier<double> time;
  final _SkyModel sky;
  final bool animate;
  _AuroraPainter(this.time, this.sky, {required this.animate})
      : super(repaint: time);

  static final Paint _light = Paint()..blendMode = BlendMode.plus;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    for (final rb in sky.ribbons) {
      _drawRibbon(canvas, rb, w, h, t);
    }
    if (animate) _drawHalo(canvas, w, h, t);
  }

  void _drawRibbon(Canvas canvas, _Ribbon rb, double w, double h, double t) {
    final ts = t * rb.speed;
    // Yavaş genel nefes (parıltı tamamen sabit durmasın).
    final breath = 0.72 + 0.28 * sin(0.21 * ts + rb.p3);
    for (var c = 0; c < _kCols; c++) {
      final xi = rb.x0 + (rb.x1 - rb.x0) * c / (_kCols - 1);
      // Parlak alt kenar: katmanlı yavaş sinüsler (~2-5 px/sn hareket).
      final yb = rb.base +
          0.018 * sin(2 * pi * 0.9 * xi + 0.30 * ts + rb.p1) +
          0.010 * sin(2 * pi * 2.1 * xi - 0.22 * ts + rb.p2) +
          0.004 * sin(2 * pi * 4.3 * xi + 0.41 * ts + rb.p3);
      final hh = rb.height * (0.75 + 0.25 * sin(2 * pi * 0.6 * xi + 0.17 * ts + rb.p2));
      // Yatay yoğunluk: uçlarda söner, yamalı, hafif dikey ışın dokusu.
      final ends = _smooth(rb.x0, rb.x0 + 0.18, xi) * _smooth(rb.x1, rb.x1 - 0.18, xi);
      final patch = 0.35 +
          0.65 *
              (0.5 + 0.5 * sin(2 * pi * 0.75 * xi - 0.19 * ts + rb.p1)) *
              (0.6 + 0.4 * sin(2 * pi * 1.6 * xi + 0.13 * ts + rb.p3));
      final rays = 0.86 + 0.14 * sin(2 * pi * 8 * xi + 0.35 * ts);
      final inten = ends * patch * rays * breath;

      for (var r = 0; r < _kRows; r++) {
        final vi = r * _kCols + c;
        final s = r == _kRows - 1 ? 1 + 0.14 * rb.edgeSoft : _kRowS[r];
        final y = yb + (s - 1) * hh;
        rb.pos[vi * 2] = xi * w;
        rb.pos[vi * 2 + 1] = y * h;
        final a = (rb.peakA * inten * _kRowI[r]).clamp(0.0, 1.0);
        final col = Color.lerp(rb.top, rb.edge, _kRowEdgeMix[r])!;
        rb.cols[vi] = col.withValues(alpha: a).toARGB32();
      }
    }
    final v = ui.Vertices.raw(ui.VertexMode.triangles, rb.pos,
        colors: rb.cols, indices: sky.ribbonIndices);
    try {
      // BlendMode.dst → köşe renkleri aynen; Paint.blendMode=plus → ışık gibi toplanır.
      canvas.drawVertices(v, BlendMode.dst, _light);
    } finally {
      // 30 Hz × 2 kurdele: native belleği GC'yi beklemeden bırak. Güvenli —
      // kaydedilen çizim alttaki köşe verisine kendi referansını tutar
      // (Flutter 3.29.2 painting.dart Vertices.dispose; Codex incelemesi).
      v.dispose();
    }
  }

  void _drawHalo(Canvas canvas, double w, double h, double time) {
    final t = time % sky.haloCycle;
    _Halo? cur;
    for (final hl in sky.halos) {
      if (hl.startT > t) break;
      if (t <= hl.startT + hl.duration) {
        cur = hl;
        break;
      }
    }
    if (cur == null) return;
    final p = (t - cur.startT) / cur.duration; // 0..1
    final s = sin(pi * p);
    final env = s * s; // uçlarda eğimi sıfır → yumuşak açılıp sönme
    final a = cur.peakA * env;
    if (a < 0.004) return;
    // Halelenme: açılırken hafifçe genişler.
    final r = cur.rFrac * min(w, h) * (0.85 + 0.25 * p);
    final center = Offset(cur.x * w, cur.y * h);
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(
        center,
        r,
        [
          cur.color.withValues(alpha: a),
          cur.color.withValues(alpha: a * 0.55),
          cur.color.withValues(alpha: 0),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.animate != animate;
}
