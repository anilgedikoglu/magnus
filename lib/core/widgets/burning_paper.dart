// lib/core/widgets/burning_paper.dart
//
// Yanan kağıt (Acı Gerçekler, Anıl 2026-11-06): beyaz kağıdın köşesi tutuşur, alev kağıdı sarar,
// kağıt KÜLE döner (bütünlüğü bozulmaz) — simsiyah kömürde çatlaklardan altın-turuncu ışık sızar.
// shaders/burning_paper.frag ile (saf fragment shader; Impeller GEREKMEZ, Skia'da da çalışır).
// Shader yüklenemezse koyu kömür yedeği çizilir; asla çökmez. Reduced-motion: anında küle döner.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class BurningPaper extends StatefulWidget {
  const BurningPaper({
    super.key,
    this.onBurnComplete,
    this.burnDuration = const Duration(milliseconds: 3200),
    this.seed = 1.0,
    this.animateCracks = true,
  });

  /// Yanma bittiğinde (kağıt tamamen küle döndüğünde) çağrılır — yazı belirsin diye.
  final VoidCallback? onBurnComplete;

  /// Kağıdın yanma süresi.
  final Duration burnDuration;

  /// Desen çeşitlemesi (her açılışta farklı çatlak/alev için).
  final double seed;

  /// Küle döndükten sonra çatlakların canlı titreşimi (pil için kapatılabilir).
  final bool animateCracks;

  /// Görsel doğrulama: shader en az bir kez çizdi mi?
  @visibleForTesting
  static bool debugShaderPainted = false;

  @override
  State<BurningPaper> createState() => _BurningPaperState();
}

class _BurningPaperState extends State<BurningPaper>
    with TickerProviderStateMixin {
  static const _shaderAsset = 'shaders/burning_paper.frag';

  ui.FragmentShader? _shader;
  bool _failed = false;

  late final AnimationController _burn;
  Ticker? _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  double _lastSecs = -1;
  bool _reducedMotion = false;
  bool _completedNotified = false;

  @override
  void initState() {
    super.initState();
    _burn = AnimationController(vsync: this, duration: widget.burnDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _notifyComplete();
      });
    _ticker = createTicker((elapsed) {
      final secs = elapsed.inMicroseconds / 1e6;
      if (secs >= _lastSecs && secs - _lastSecs < 1 / 30) return; // ~30 Hz
      _lastSecs = secs;
      _time.value = secs % 600.0; // mediump GPU: zaman sarması
    });
    _loadShader();
  }

  void _notifyComplete() {
    if (_completedNotified) return;
    _completedNotified = true;
    widget.onBurnComplete?.call();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_shaderAsset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (e) {
      debugPrint('[BurningPaper] shader yüklenemedi, kömür yedeği: $e');
      if (mounted) setState(() => _failed = true);
    }
    _startBurn();
  }

  void _startBurn() {
    if (!mounted) return;
    if (_reducedMotion) {
      _burn.value = 1.0; // anında küle dönmüş
      _notifyComplete();
    } else if (_burn.status == AnimationStatus.dismissed) {
      _burn.forward();
    }
    _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncTicker();
  }

  void _syncTicker() {
    final tk = _ticker;
    if (tk == null) return;
    final run = !_reducedMotion && widget.animateCracks && (_shader != null);
    if (run && !tk.isActive) {
      tk.start();
    } else if (!run && tk.isActive) {
      tk.stop();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _burn.dispose();
    _shader?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _shader == null) {
      // Yedek: koyu kömür zemin (shader gelene kadar / desteklenmezse).
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.2, 0.1),
            radius: 1.1,
            colors: [Color(0xFF1A120B), Color(0xFF0A0706)],
          ),
        ),
        child: SizedBox.expand(),
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_burn, _time]),
        builder: (context, _) => CustomPaint(
          painter: _BurnPainter(
            shader: _shader!,
            time: _time.value,
            burn: _burn.value,
            seed: widget.seed,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BurnPainter extends CustomPainter {
  _BurnPainter({
    required this.shader,
    required this.time,
    required this.burn,
    required this.seed,
  });

  final ui.FragmentShader shader;
  final double time;
  final double burn;
  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, burn)
      ..setFloat(4, seed);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    BurningPaper.debugShaderPainted = true;
  }

  @override
  bool shouldRepaint(_BurnPainter old) =>
      old.time != time || old.burn != burn || old.seed != seed;
}
