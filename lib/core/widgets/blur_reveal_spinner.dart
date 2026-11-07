// Sinematik "bulanıktan netleşen" slot-makinesi reveal animasyonu (Anıl, 2026-11-07).
//
// Bir görsel yolu listesi alır; görseller arasında HIZLA döner, easing ile YAVAŞLAYARAK
// (easeOutQuart) ~5.5 saniyede birinde DURUR, sonra onDone(finalIndex) çağrılır.
// Dönerken hız oranında bulanıklık (motion-blur hissi) uygulanır; yavaşladıkça netleşir →
// son görsel keskin olarak "ifşa" olur. Üstte gizemli vinyet + hafif renk tonu.
//
// Görseller henüz YOKKEN de ÇALIŞIR: her Image.asset errorBuilder ile prosedürel bir
// yedeğe (bulanık koyu siluet, _SilhouettePainter) düşer. assetPaths boşsa yalnızca yedek
// siluetler döner. Böylece asset'ler eklenmeden de derlenir ve akış devam eder.
//
// Azaltılmış hareket (MediaQuery.maybeDisableAnimationsOf): dönme atlanır, net son kare
// gösterilir ve kısa bir beklemeden sonra onDone çağrılır (akış yine ilerler).
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class BlurRevealSpinner extends StatefulWidget {
  /// Dönülecek görsel yolları (ör. portre_01.jpg ... portre_16.jpg). Boşsa yedek siluetler.
  final List<String> assetPaths;

  /// Dönme bitip son kareye oturunca çağrılır. [finalIndex] duran görselin indeksi.
  final ValueChanged<int>? onDone;

  /// Dönme süresi (son kareye oturma anı). Varsayılan 5.5 sn.
  final Duration duration;

  /// Kare (viewport) boyutu.
  final double size;

  /// Vinyet / rim / siluet tonu için vurgu rengi.
  final Color accent;

  /// Belirli bir sonucu tekrarlamak için opsiyonel seed (test). Yoksa her açılış farklı.
  final int? seed;

  const BlurRevealSpinner({
    super.key,
    required this.assetPaths,
    this.onDone,
    this.duration = const Duration(milliseconds: 5500),
    this.size = 190,
    this.accent = const Color(0xFFFF55FF),
    this.seed,
  });

  @override
  State<BlurRevealSpinner> createState() => _BlurRevealSpinnerState();
}

class _BlurRevealSpinnerState extends State<BlurRevealSpinner>
    with SingleTickerProviderStateMixin {
  // assetPaths boşken dönecek sentetik yedek-siluet sayısı.
  static const int _kFallbackCount = 10;

  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);
  late final int _count; // efektif görsel sayısı (boşsa yedek sayısı)
  late final int _totalSpins; // toplam görsel değişim adımı (tam sayı → son kare net oturur)
  late final int _finalIndex; // durulacak görsel indeksi
  Timer? _holdTimer;
  bool _reduced = false;
  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _count = widget.assetPaths.isEmpty ? _kFallbackCount : widget.assetPaths.length;
    final rnd = math.Random(widget.seed ?? DateTime.now().microsecondsSinceEpoch);
    // En az birkaç tam tur dön, sonra rastgele birinde dur. Tam sayı tutulur ki
    // easeOutQuart(1)=1 → son konum tam _totalSpins olsun, kesirli kalıp titremesin.
    final baseTurns = _count <= 1 ? 8 : 5;
    _totalSpins = _count * baseTurns + rnd.nextInt(math.max(1, _count));
    _finalIndex = _count <= 0 ? 0 : _totalSpins % _count;
    _ctrl.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_done) {
      // Net son kareyi kısa bir an tut, sonra bitir (reveal nefesi).
      _holdTimer?.cancel();
      _holdTimer = Timer(const Duration(milliseconds: 420), _finish);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ekran açıkken ayar değişse de uyulsun diye burada oku (platformDispatcher değil).
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_started) {
      _started = true;
      if (_reduced) {
        _ctrl.value = 1.0; // net son kare
        _holdTimer = Timer(const Duration(milliseconds: 500), _finish);
      } else {
        _ctrl.forward();
      }
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone?.call(_finalIndex);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _ctrl.removeStatusListener(_onStatus);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => _frame(),
        ),
      ),
    );
  }

  Widget _frame() {
    final t = _ctrl.value;
    final eased = Curves.easeOutQuart.transform(t);
    final spinPos = eased * _totalSpins;
    final idx = spinPos.floor();
    final frac = (spinPos - idx).clamp(0.0, 1.0);
    final curIndex = _count <= 0 ? 0 : idx % _count;
    final nextIndex = _count <= 0 ? 0 : (idx + 1) % _count;

    // Hız → bulanıklık: başta yüksek, sonda ~0 (netleşerek ifşa).
    final maxBlur = widget.size * 0.085;
    final sigma = _reduced ? 0.0 : maxBlur * math.pow(1.0 - t, 1.4).toDouble();

    // Taban tam opak (kararma olmasın), üstteki bir sonraki kare frac ile belirir → yumuşak geçiş.
    Widget frames = Stack(
      fit: StackFit.expand,
      children: [
        _tile(curIndex),
        if (frac > 0.001) Opacity(opacity: frac, child: _tile(nextIndex)),
      ],
    );

    if (sigma >= 0.05) {
      frames = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: frames,
      );
    }

    final radius = BorderRadius.circular(widget.size * 0.12);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0B0718)),
          frames,
          // Gizemli vinyet + hafif rim.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: widget.accent.withValues(alpha: 0.30), width: 1.2),
              gradient: RadialGradient(
                radius: 0.95,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.45, 0.78, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(int index) {
    if (widget.assetPaths.isEmpty || index >= widget.assetPaths.length) {
      return _fallback(index);
    }
    return Image.asset(
      widget.assetPaths[index],
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _fallback(index),
    );
  }

  Widget _fallback(int index) => CustomPaint(
        painter: _SilhouettePainter(seed: index, accent: widget.accent),
        size: Size.square(widget.size),
      );
}

/// Görsel yoksa: bulanık, koyu, belirsiz bir siluet (baş + omuz / gizemli gölge).
/// Seed'e göre hafifçe değişir ki dönme yedekle de görünür olsun.
class _SilhouettePainter extends CustomPainter {
  final int seed;
  final Color accent;
  _SilhouettePainter({required this.seed, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random((seed + 1) * 2654435761 & 0x7fffffff);
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Koyu zemin (hafif derinlik için radyal).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF1A1030), Color(0xFF0A0616)],
        ).createShader(rect),
    );

    // Vurgu renginden türetilmiş sıcak/soğuk kayan hafif ton.
    final base = HSVColor.fromColor(accent);
    final tint = base
        .withHue((base.hue + (rnd.nextDouble() * 80 - 40)) % 360)
        .withSaturation(0.5)
        .withValue(0.28)
        .toColor();

    final cx = w * (0.5 + (rnd.nextDouble() * 0.12 - 0.06));
    final headR = w * (0.15 + rnd.nextDouble() * 0.03);
    final headCy = h * 0.40;

    // Arka hafif ışıma.
    canvas.drawCircle(
      Offset(cx, headCy + h * 0.1),
      headR * 2.6,
      Paint()
        ..color = tint.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.13),
    );

    final sil = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.055);

    // Baş.
    canvas.drawCircle(Offset(cx, headCy), headR, sil);
    // Omuz / gövde — alt yarıya oturan geniş oval.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.95),
        width: w * (0.64 + rnd.nextDouble() * 0.1),
        height: h * 0.62,
      ),
      sil,
    );
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => old.seed != seed || old.accent != accent;
}
