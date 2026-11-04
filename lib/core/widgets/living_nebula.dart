// lib/core/widgets/living_nebula.dart
//
// "Yaşayan nebula" arka planı — shaders/living_nebula.frag ile:
//   • nebulanın kendisi çok yavaş dalgalanır (domain-warp),
//   • bulutlarda gezinen ALACALI renk yamaları (mor / indigo / magenta / az teal),
//   • bölgeden bölgeye değişen yavaş parlaklık nefesi,
//   • koyulaştırma + eliptik vinyet.
//
// Sağlamlık (Codex ile tasarlandı + eleştirildi, 2026-11-04):
//   - Shader ve görsel hazır olana kadar statik görsel + SkyDarkenOverlay görünür
//     (ilk karede siyah flaş yok); hazır olunca 600 ms cross-fade.
//   - Shader yüklenemezse (cihaz/test) statik görselde kalır — asla çökmez.
//   - Gürültü ofsetleri Dart'ta double hassasiyetle SINIRLI dairesel yörüngelerden
//     hesaplanır → GPU'da mediump hassasiyet bozulması / zaman sarma sıçraması yok.
//   - 30 Hz güncelleme (hareket çok yavaş), ayrı RepaintBoundary.
//   - Görsel, Image.asset ile AYNI ImageProvider'dan çözülür (ImageCache paylaşımı).
//   - Reduced-motion: zaman sabit, ticker çalışmaz.

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'starfield_overlay.dart' show SkyDarkenOverlay;

/// Doygunluk 0.58 matrisi (Rec.601 luma — shader GRIMOIRE_SAT ile aynı).
const List<double> _kSat058 = <double>[0.7056, 0.2465, 0.0479, 0, 0, 0.1256, 0.8265, 0.0479, 0, 0, 0.1256, 0.2465, 0.6279, 0, 0, 0, 0, 0, 1, 0];

class LivingNebulaBackground extends StatefulWidget {
  final String asset;

  /// Ek karartma (shader). 0.07 ≈ eski SkyDarkenOverlay'den biraz koyu.
  final double dark;

  const LivingNebulaBackground({super.key, required this.asset, this.dark = 0.07});

  /// Test/görsel doğrulama: shader en az bir kez gerçekten çizdi mi?
  @visibleForTesting
  static bool debugShaderPainted = false;

  @override
  State<LivingNebulaBackground> createState() => _LivingNebulaBackgroundState();
}

class _LivingNebulaBackgroundState extends State<LivingNebulaBackground>
    with SingleTickerProviderStateMixin {
  static const _shaderAsset = 'shaders/living_nebula.frag';

  ui.FragmentShader? _shader;
  ui.Image? _image;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  // Hata bayrakları ayrı (Codex incelemesi): asset değişince yalnız görsel sıfırlanır.
  bool _shaderFailed = false;
  bool _imageFailed = false;
  bool _fallbackGone = false;

  Ticker? _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(3.0);
  int _slot = -1;
  /// Ticker durup yeniden başlayınca (reduced-motion aç/kapa) nebula sıçramasın:
  /// yeni koşu kaldığı zamandan devam eder (Codex incelemesi).
  double _timeBase = 3.0;
  bool _reducedMotion = false;

  bool get _ready =>
      !_shaderFailed && !_imageFailed && _shader != null && _image != null;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      // 30 Hz dilim: hareket çok yavaş, judder olmaz; GPU yükü azalır.
      final slot = (elapsed.inMicroseconds * 30 / 1e6).floor();
      if (slot != _slot) {
        _slot = slot;
        _time.value = _timeBase + slot / 30.0;
      }
    });
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_shaderAsset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (e) {
      debugPrint('[LivingNebula] shader yüklenemedi, statik arka plan: $e');
      if (mounted) setState(() => _shaderFailed = true);
    }
    if (mounted) _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _resolveImage();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant LivingNebulaBackground old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) {
      // Yeni görsel gelene kadar eskisini gösterme; önceki hata yeni görseli kilitlemesin.
      _image?.dispose();
      _image = null;
      _imageFailed = false;
      _fallbackGone = false;
      _resolveImage();
      _syncTicker();
    }
  }

  void _resolveImage() {
    final stream =
        AssetImage(widget.asset).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    if (_listener != null) _stream?.removeListener(_listener!);
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) {
          info.dispose();
          return;
        }
        setState(() {
          _image?.dispose();
          _image = info.image.clone(); // kendi handle'ımız; dispose'ta bırakılır
        });
        info.dispose();
        _syncTicker();
      },
      onError: (e, _) {
        debugPrint('[LivingNebula] görsel yüklenemedi: $e');
        if (!mounted) return;
        setState(() => _imageFailed = true);
        _syncTicker(); // fallback üstünde boşa çalışmasın (Codex incelemesi)
      },
    );
    stream.addListener(_listener!);
    _stream = stream;
  }

  /// Ticker yalnız shader hazır + hareket serbestken çalışır (boşa kare istemesin).
  void _syncTicker() {
    final tk = _ticker;
    if (tk == null) return;
    final shouldRun = _ready && !_reducedMotion;
    if (shouldRun && !tk.isActive) {
      _timeBase = _time.value; // kaldığı yerden devam (Ticker elapsed 0'dan başlar)
      _slot = -1;
      tk.start();
    } else if (!shouldRun && tk.isActive) {
      tk.stop();
    }
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _ticker?.dispose();
    _time.dispose();
    _shader?.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ready;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Statik yedek: ilk kare + shader yoksa kalıcı. Geçiş bitince ağaçtan çıkar.
        if (!_fallbackGone || !ready)
          Stack(fit: StackFit.expand, children: [
            // Shader'daki GRIMOIRE_SAT (0.58) ile aynı doygunluk → geçişte renk sıçramaz.
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(_kSat058),
              child: Image.asset(
                widget.asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF07080B)),
              ),
            ),
            const SkyDarkenOverlay(),
          ]),
        if (ready)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: _reducedMotion ? 0 : 600),
            curve: Curves.easeOut,
            onEnd: () {
              // Süre 0 iken (reduced-motion) onEnd build SIRASINDA senkron gelir →
              // doğrudan setState "build içinde setState" assert'i verir (testte
              // yakalandı). Kare sonrasına ertele.
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_fallbackGone) setState(() => _fallbackGone = true);
              });
            },
            builder: (context, v, child) => Opacity(opacity: v, child: child),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _NebulaPainter(_time, _shader!, _image!, dark: widget.dark),
                child: const SizedBox.expand(),
              ),
            ),
          ),
      ],
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final ValueNotifier<double> time;
  final ui.FragmentShader shader;
  final ui.Image image;
  final double dark;
  _NebulaPainter(this.time, this.shader, this.image, {required this.dark})
      : super(repaint: time);

  /// Noise uzayında sınırlı dairesel yörünge: hız = r·ω (birim/sn), değer hep ≤ r.
  static Offset _orbit(double t, double r, double w, double ph) =>
      Offset(r * cos(w * t + ph), r * sin(w * t + ph));

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = time.value;
    // Hızlar Codex taslağının ~2.4 katı (taslakta desen ~1.5 px/sn kayıyordu → algılanmaz).
    final f1 = _orbit(t, 3.2, 0.0068, 0.0); // ~4 px/sn warp desen kayması
    final f2 = _orbit(t, 2.7, -0.0081, 1.3);
    // Renk yamaları v2: daha küçük yama (2.4) → px hızı düşmesin diye ω ×1.5.
    final c1 = _orbit(t, 2.4, 0.0093, 2.1);
    final c2 = _orbit(t, 2.0, -0.0128, 4.0);
    final breath = (0.075 * t) % (2 * pi);

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, image.width.toDouble())
      ..setFloat(3, image.height.toDouble())
      ..setFloat(4, dark)
      ..setFloat(5, f1.dx)
      ..setFloat(6, f1.dy)
      ..setFloat(7, f2.dx)
      ..setFloat(8, f2.dy)
      ..setFloat(9, c1.dx)
      ..setFloat(10, c1.dy)
      ..setFloat(11, c2.dx)
      ..setFloat(12, c2.dy)
      ..setFloat(13, breath)
      // Varsayılan FilterQuality.none: yavaş subpixel harekette pikselleşir → low.
      ..setImageSampler(0, image, filterQuality: FilterQuality.low);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    assert(() {
      LivingNebulaBackground.debugShaderPainted = true;
      return true;
    }());
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter old) =>
      old.shader != shader || old.image != image || old.dark != dark;
}
