// lib/core/widgets/living_sea.dart
//
// Yaşayan deniz arka planı (Kader Kitabı, Anıl 2026-11-06). Boyalı deniz görselinin ufkunun
// altı shaders/living_sea.frag ile dalgalanır (Hooop'un MenuSea'sinden uyarlandı).
// Shader/görsel hazır değilse ya da yüklenemezse statik görsel; asla çökmez.
// Reduced-motion: ticker durur (tek kare), geri açılınca kaldığı yerden sürer.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LivingSeaBackground extends StatefulWidget {
  const LivingSeaBackground({
    super.key,
    required this.asset,
    this.horizon = 0.28,
    this.ripple = 0.0085,
    this.dark = 0.0,
  });

  final String asset;

  /// Ufuk çizgisinin görseldeki yeri (0 üst … 1 alt).
  final double horizon;

  /// Dalga gücü (uv biriminde; Hooop menüsünde 0.0095).
  final double ripple;

  /// Ek karartma (0 … 1).
  final double dark;

  /// Test/görsel doğrulama: shader en az bir kez çizdi mi?
  @visibleForTesting
  static bool debugShaderPainted = false;

  @override
  State<LivingSeaBackground> createState() => _LivingSeaBackgroundState();
}

class _LivingSeaBackgroundState extends State<LivingSeaBackground>
    with SingleTickerProviderStateMixin {
  static const _shaderAsset = 'shaders/living_sea.frag';

  ui.FragmentShader? _shader;
  ui.Image? _image;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _failed = false;
  Ticker? _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  double _timeBase = 0;
  double _lastSecs = -1;
  bool _reducedMotion = false;

  bool get _ready => !_failed && _shader != null && _image != null;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      // ~30 Hz yeter (yavaş deniz; nebula ile aynı kural): ekran hızında tam ekran shader pil yer.
      final secs = elapsed.inMicroseconds / 1e6;
      if (secs >= _lastSecs && secs - _lastSecs < 1 / 30) return;
      _lastSecs = secs;
      // Sarma: mediump GPU'da büyük zaman değerleri sinüsü bozmasın (10 dk'da bir).
      _time.value = (_timeBase + secs) % 600.0;
    });
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_shaderAsset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (e) {
      debugPrint('[LivingSea] shader yüklenemedi, statik arka plan: $e');
      if (mounted) setState(() => _failed = true);
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

  void _resolveImage() {
    final stream = AssetImage(widget.asset).resolve(createLocalImageConfiguration(context));
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
          _image = info.image.clone();
        });
        info.dispose();
        _syncTicker();
      },
      onError: (e, _) {
        debugPrint('[LivingSea] görsel yüklenemedi: $e');
        if (!mounted) return;
        setState(() => _failed = true);
        _syncTicker();
      },
    );
    stream.addListener(_listener!);
    _stream = stream;
  }

  void _syncTicker() {
    final tk = _ticker;
    if (tk == null) return;
    final run = _ready && !_reducedMotion;
    if (run && !tk.isActive) {
      _timeBase = _time.value;
      tk.start();
    } else if (!run && tk.isActive) {
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
    if (!_ready) {
      return Stack(fit: StackFit.expand, children: [
        Image.asset(widget.asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF05070F))),
        if (widget.dark > 0)
          ColoredBox(color: Colors.black.withValues(alpha: widget.dark)),
      ]);
    }
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SeaPainter(_time, _shader!, _image!,
            horizon: widget.horizon, ripple: widget.ripple, dark: widget.dark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SeaPainter extends CustomPainter {
  _SeaPainter(this.time, this.shader, this.image,
      {required this.horizon, required this.ripple, required this.dark})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final ui.FragmentShader shader;
  final ui.Image image;
  final double horizon, ripple, dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, image.width.toDouble())
      ..setFloat(3, image.height.toDouble())
      ..setFloat(4, time.value)
      ..setFloat(5, horizon)
      ..setFloat(6, ripple)
      ..setFloat(7, dark)
      ..setImageSampler(0, image, filterQuality: FilterQuality.low);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    assert(() {
      LivingSeaBackground.debugShaderPainted = true;
      return true;
    }());
  }

  @override
  bool shouldRepaint(covariant _SeaPainter old) =>
      old.shader != shader ||
      old.image != image ||
      old.horizon != horizon ||
      old.ripple != ripple ||
      old.dark != dark;
}
