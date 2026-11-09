// lib/core/widgets/burning_paper.dart
//
// Acı Gerçekler açılışı — SİNEMATİK yanan-papirüs sekansı (Anıl 2026-11-07).
//
// İki parça:
//   • BurningPaper      — papirüs → sağ alt köşeden tutuşur → ak-sıcak cephe + alev +
//     köz + YOĞUN duman tüm kağıdı sarar → kağıdın kendisi siyaha yakın koyulaşır → dumanlar dağılır.
//     shaders/burning_paper.frag (saf fragment; Impeller GEREKMEZ, Skia'da da çalışır).
//     Gerçek papirüs görseli (assets/images/papirus.png) varsa KULLANILIR; yoksa
//     prosedürel papirüs yedeği. Görsel sonradan eklenince otomatik devreye girer.
//   • GoldenScriptText  — kara kağıtta altın-sarısı yazı; ışık huzmeleri harflerin
//     İÇİNDEN geçer (ShaderMask + shaders/golden_script.frag). Metin dinamik; gerçek
//     metin widget'ı maskeyi verir → uzun metinde kaydırma/satır kırma korunur.
//
// Sağlamlık: shader/görsel yüklenemezse koyu kömür / düz altın yazı yedeği; asla çökmez.
// Reduced-motion: anında son kareye (kömür + durgun altın yazı, ışık taraması yok).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/rich_text_parser.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BurningPaper — yanan papirüs sahnesi (Faz 1-4)
// ═══════════════════════════════════════════════════════════════════════════════

class BurningPaper extends StatefulWidget {
  const BurningPaper({
    super.key,
    this.onBurnComplete,
    this.burnDuration = const Duration(milliseconds: 6000),
    this.seed = 1.0,
    this.paperAsset = 'assets/images/papirus.png',
  });

  /// Dumanlar büyük ölçüde dağılıp kara kağıt ortaya çıkınca çağrılır (yazı belirsin).
  final VoidCallback? onBurnComplete;

  /// Sekansın toplam süresi (tutuşma → kül → duman dağılması).
  final Duration burnDuration;

  /// Desen çeşitlemesi (her açılışta farklı çatlak/alev/duman).
  final double seed;

  /// Gerçek papirüs görseli. Yoksa prosedürel papirüs yedeği çizilir.
  final String paperAsset;

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
  bool _shaderFailed = false;

  // Papirüs görseli (opsiyonel) + sampler için 1×1 kukla (görsel yokken bağlı kalsın).
  ui.Image? _paperImage;
  ui.Image? _dummy;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _hasPaper = false;

  late final AnimationController _seq;
  Ticker? _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  double _lastSecs = -1;
  bool _reducedMotion = false;
  bool _burnStarted = false;
  bool _completedNotified = false;

  // Duman dağılıp kara kağıt netleşince (altın yazı bu eşikte belirmeli).
  static const _revealAt = 0.84;

  @override
  void initState() {
    super.initState();
    _dummy = _make1x1();
    _seq = AnimationController(vsync: this, duration: widget.burnDuration)
      ..addListener(_onSeqTick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _notifyComplete();
          _ticker?.stop(); // son kare durgun → boşa kare yakma
        }
      });
    _ticker = createTicker((elapsed) {
      final secs = elapsed.inMicroseconds / 1e6;
      if (secs >= _lastSecs && secs - _lastSecs < 1 / 50) return; // ~50 Hz akıcı alev/duman
      _lastSecs = secs;
      _time.value = secs % 600.0; // mediump GPU: zaman sarması
    });
    _loadShader();
  }

  ui.Image _make1x1() {
    final rec = ui.PictureRecorder();
    ui.Canvas(rec).drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..color = const Color(0xFF7A6A4A),
    );
    return rec.endRecording().toImageSync(1, 1);
  }

  void _onSeqTick() {
    if (!_completedNotified && _seq.value >= _revealAt) _notifyComplete();
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
      if (mounted) setState(() => _shaderFailed = true);
    }
    _startBurn();
  }

  void _startBurn() {
    if (!mounted || _burnStarted) return;
    _burnStarted = true;
    if (_reducedMotion) {
      _seq.value = 1.0; // anında son kare
      _notifyComplete();
    } else if (_seq.status == AnimationStatus.dismissed) {
      _seq.forward();
    }
    _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _resolvePaper();
    _syncTicker();
  }

  void _resolvePaper() {
    final stream = AssetImage(widget.paperAsset)
        .resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    if (_listener != null) _stream?.removeListener(_listener!);
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) {
          info.dispose();
          return;
        }
        setState(() {
          _paperImage?.dispose();
          _paperImage = info.image.clone();
          _hasPaper = true;
        });
        info.dispose();
      },
      onError: (e, _) {
        // Görsel yoksa sorun değil: prosedürel papirüs yedeği çizilir.
        if (!mounted) return;
        if (_hasPaper || _paperImage != null) {
          setState(() {
            _paperImage?.dispose();
            _paperImage = null;
            _hasPaper = false;
          });
        }
      },
    );
    stream.addListener(_listener!);
    _stream = stream;
  }

  void _syncTicker() {
    final tk = _ticker;
    if (tk == null) return;
    final run = !_reducedMotion &&
        _shader != null &&
        _seq.status == AnimationStatus.forward;
    if (run && !tk.isActive) {
      tk.start();
    } else if (!run && tk.isActive) {
      tk.stop();
    }
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _ticker?.dispose();
    _seq.dispose();
    _shader?.dispose();
    _paperImage?.dispose();
    _dummy?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shaderFailed || _shader == null) {
      // Yedek: koyulaşmış kağıt (shader gelene kadar / desteklenmezse).
      return SizedBox.expand(
        child: Image.asset(
          widget.paperAsset,
          fit: BoxFit.cover,
          color: const Color(0xFF2A2019),
          colorBlendMode: BlendMode.multiply,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF120D09)),
        ),
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_seq, _time]),
        builder: (context, _) => CustomPaint(
          painter: _BurnPainter(
            shader: _shader!,
            paper: _hasPaper ? _paperImage! : _dummy!,
            hasPaper: _hasPaper && _paperImage != null,
            time: _time.value,
            burn: _seq.value,
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
    required this.paper,
    required this.hasPaper,
    required this.time,
    required this.burn,
    required this.seed,
  });

  final ui.FragmentShader shader;
  final ui.Image paper;
  final bool hasPaper;
  final double time;
  final double burn;
  final double seed;

  static double _smoothstep(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Cephe ilk ~%62'de sol-üst köşeye varır; kalan süre dumanın dağılması.
    final uBurn = (burn / 0.62).clamp(0.0, 1.0);
    // Duman: tutuşmayla yükselir, "ortalık dumanlanır", kül tamamlanınca yavaşça dağılır.
    final rise = _smoothstep(0.08, 0.42, burn);
    final fall = 1.0 - _smoothstep(0.60, 0.90, burn);
    final uSmoke = (rise * fall).clamp(0.0, 1.0);

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, uBurn)
      ..setFloat(4, uSmoke)
      ..setFloat(5, seed)
      ..setFloat(6, hasPaper ? 1.0 : 0.0)
      ..setFloat(7, paper.width.toDouble())
      ..setFloat(8, paper.height.toDouble())
      ..setImageSampler(0, paper, filterQuality: FilterQuality.low);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    assert(() {
      BurningPaper.debugShaderPainted = true;
      return true;
    }());
  }

  @override
  bool shouldRepaint(_BurnPainter old) =>
      old.time != time ||
      old.burn != burn ||
      old.seed != seed ||
      old.hasPaper != hasPaper ||
      old.paper != paper ||
      old.shader != shader;
}

// ═══════════════════════════════════════════════════════════════════════════════
// GoldenScriptText — kara kağıtta altın yazı; ışık harflerin İÇİNDEN geçer (Faz 5-6)
// ═══════════════════════════════════════════════════════════════════════════════

class GoldenScriptText extends StatefulWidget {
  const GoldenScriptText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.fromLTRB(30, 26, 30, 30),
  });

  /// Gösterilecek metin (`<color=…>` etiketleri RichTextParser ile işlenir).
  final String text;

  /// Durgun altın metin stili (yedekte ve maske metriğinde kullanılır).
  final TextStyle style;

  final TextAlign textAlign;
  final EdgeInsets padding;

  @visibleForTesting
  static bool debugShaderPainted = false;

  @override
  State<GoldenScriptText> createState() => _GoldenScriptTextState();
}

class _GoldenScriptTextState extends State<GoldenScriptText>
    with SingleTickerProviderStateMixin {
  static const _shaderAsset = 'shaders/golden_script.frag';

  ui.FragmentShader? _shader;
  bool _failed = false;
  Ticker? _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  double _lastSecs = -1;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final secs = elapsed.inMicroseconds / 1e6;
      if (secs >= _lastSecs && secs - _lastSecs < 1 / 40) return; // ~40 Hz, ışık bandı
      _lastSecs = secs;
      _time.value = secs % 600.0;
    });
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_shaderAsset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (e) {
      debugPrint('[GoldenScriptText] shader yüklenemedi, düz altın yedeği: $e');
      if (mounted) setState(() => _failed = true);
    }
    _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  void _syncTicker() {
    final tk = _ticker;
    if (tk == null) return;
    final run = !_reducedMotion && !_failed && _shader != null;
    if (run && !tk.isActive) {
      tk.start();
    } else if (!run && tk.isActive) {
      tk.stop();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  // Maske metni: RENK önemsiz (srcIn yalnız ALFAYI kullanır); beyaz + yumuşak gölge
  // → shader altını gölge halesinde de görünür (yumuşak bloom).
  TextStyle get _maskStyle => widget.style.copyWith(
        color: Colors.white,
        shadows: const [
          Shadow(color: Color(0x8CFFFFFF), blurRadius: 9),
          Shadow(color: Color(0x4DFFFFFF), blurRadius: 22),
        ],
      );

  Widget _scrollable(Widget child) {
    return ScrollConfiguration(
      behavior: const _NoGlowBehavior(),
      child: Center(
        child: SingleChildScrollView(
          padding: widget.padding,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Yedek: shader yok/başarısız → düz altın yazı (eski görünüm; ışık taraması yok).
    if (_failed || _shader == null) {
      return _scrollable(RichTextParser.build(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
      ));
    }

    final mask = _scrollable(RichTextParser.build(
      widget.text,
      style: _maskStyle,
      textAlign: widget.textAlign,
    ));

    return AnimatedBuilder(
      animation: _time,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn, // çocuk = glif alfası (maske), shader = renk
          shaderCallback: (Rect bounds) {
            final s = _shader!;
            s
              ..setFloat(0, bounds.width <= 0 ? 1.0 : bounds.width)
              ..setFloat(1, bounds.height <= 0 ? 1.0 : bounds.height)
              ..setFloat(2, _time.value)
              ..setFloat(3, _reducedMotion ? 0.0 : 1.0) // ışık huzmesi gücü
              ..setFloat(4, 7.0);
            assert(() {
              GoldenScriptText.debugShaderPainted = true;
              return true;
            }());
            return s;
          },
          child: child,
        );
      },
      child: mask,
    );
  }
}

/// Overscroll parıltısını kaldırır (altın maskede kenar parlaması olmasın).
class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
