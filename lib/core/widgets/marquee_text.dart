// Tek satır kayan yazı (2026-11-05, Anıl: "arabanın adı sığmazsa alt satıra inmesin,
// kendi kayan yazı olsun, sürekli dönsün dursun yavaşça").
//
// • Metin alana SIĞARSA: düz, tek satır Text (hareket yok).
// • SIĞMAZSA: metin + boşluk + metin yan yana dizilir ve bir tur (metin+boşluk) boyunca
//   sabit hızla sola kayar → tur sonunda görüntü başlangıçla birebir aynıdır, "tak" yok
//   (home_screen balonundaki dikişsiz döngüyle aynı ilke). Kenarlarda yumuşak solma.
// • Hareket azaltma (disableAnimations) açıksa kaymaz, üç noktayla kısalır.
import 'package:flutter/material.dart';

class MarqueeText extends StatelessWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.velocity = 28,
    this.gap = 48,
    this.fadeWidth = 14,
  });

  final String text;
  final TextStyle? style;

  /// Sığdığında hizalama (kayarken her zaman soldan akar).
  final TextAlign textAlign;

  /// Kayma hızı (mantıksal piksel / saniye) — yavaş, okunur.
  final double velocity;

  /// İki kopya arasındaki boşluk.
  final double gap;

  /// Kayarken sol/sağ kenardaki solma genişliği.
  final double fadeWidth;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, c) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: effective),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      final textW = tp.width, textH = tp.height;
      tp.dispose();
      final fits = !c.maxWidth.isFinite || textW <= c.maxWidth + 0.5;
      final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (fits || reduceMotion) {
        return SizedBox(
          width: c.maxWidth.isFinite ? c.maxWidth : null,
          child: Text(text,
              style: effective,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign),
        );
      }
      return _MarqueeRunner(
        text: text,
        style: effective,
        width: c.maxWidth,
        height: textH,
        cycle: textW + gap,
        gap: gap,
        velocity: velocity,
        fadeWidth: fadeWidth,
      );
    });
  }
}

class _MarqueeRunner extends StatefulWidget {
  const _MarqueeRunner({
    required this.text,
    required this.style,
    required this.width,
    required this.height,
    required this.cycle,
    required this.gap,
    required this.velocity,
    required this.fadeWidth,
  });

  final String text;
  final TextStyle style;
  final double width, height, cycle, gap, velocity, fadeWidth;

  @override
  State<_MarqueeRunner> createState() => _MarqueeRunnerState();
}

class _MarqueeRunnerState extends State<_MarqueeRunner> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: _duration)..repeat();

  Duration get _duration =>
      Duration(milliseconds: (widget.cycle / widget.velocity * 1000).round().clamp(1500, 120000));

  @override
  void didUpdateWidget(covariant _MarqueeRunner old) {
    super.didUpdateWidget(old);
    if (old.cycle != widget.cycle || old.velocity != widget.velocity) {
      // Kaldığı oranı koru (metin aynıysa sıçrama olmaz), yeni süreyle devam.
      final v = _ctrl.value;
      _ctrl
        ..duration = _duration
        ..repeat()
        ..value = v;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final f = (widget.fadeWidth / w).clamp(0.0, 0.25);
    final line = Text(widget.text, style: widget.style, maxLines: 1, softWrap: false);
    return RepaintBoundary(
      child: SizedBox(
        width: w,
        height: widget.height,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => LinearGradient(
            colors: const [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            stops: [0, f, 1 - f, 1],
          ).createShader(r),
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Transform.translate(
                offset: Offset(-_ctrl.value * widget.cycle, 0),
                child: child,
              ),
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  line,
                  SizedBox(width: widget.gap),
                  line,
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
