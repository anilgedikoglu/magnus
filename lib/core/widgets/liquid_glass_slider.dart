// lib/core/widgets/liquid_glass_slider.dart
//
// iOS 26 Liquid Glass kaydırıcısı (Anıl'ın "Şeffaf ↔ Renkli" ayar kaydından ÖLÇÜLDÜ, 3x):
//   • Ray 5.5 pt, #2C2B2D; dolgu #0085FF (soldan topuz merkezine). Ray, 0'daki topuzun sol
//     kenarından 1'deki topuzun sağ kenarına uzanır.
//   • Durağan topuz: beyaz kapsül 37×24 pt.
//   • Parmak değince topuz 58×37 pt'lik CAM MERCEĞE dönüşür (Impeller'da altındaki rayı
//     büyüterek gösterir, kenarı kırar), bırakınca yayla beyaz kapsüle döner.
//   • 0 / 0.5 / 1'de rayın 7.7 pt altında küçük noktalar; bu noktalardan geçerken hafif titreşim.
//   • Solda "şeffaf" (iki çizgi kare), sağda "renkli" (dolu kare) simgesi, gri #818082.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'glass_lens.dart';

const Color _kTrack = Color(0xFF2C2B2D);
const Color _kFill = Color(0xFF0085FF);
const Color _kIcon = Color(0xFF818082);
const Color _kTick = Color(0xFF3A393B);
const Size _kKnobRest = Size(37, 24);
const Size _kKnobPressed = Size(58, 37);
const double _kTrackH = 5.5;
const double _kTickGap = 7.7;

class LiquidGlassSlider extends StatefulWidget {
  const LiquidGlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    required this.semanticLabel,
  });

  /// 0 … 1.
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// Ekran okuyucu etiketi (TR/EN).
  final String semanticLabel;

  @override
  State<LiquidGlassSlider> createState() => _LiquidGlassSliderState();
}

class _LiquidGlassSliderState extends State<LiquidGlassSlider>
    with SingleTickerProviderStateMixin {
  /// Basılı hâl: 0 beyaz kapsül … 1 cam mercek.
  late final AnimationController _press = AnimationController.unbounded(vsync: this);
  static const _releaseSpring = SpringDescription(mass: 1, stiffness: 380, damping: 26);
  ui.FragmentProgram? _lens = glassLensLoaded;
  double _width = 1;
  double? _lastTick;

  /// Bu jestte verilen son değer (widget.value yeniden çizimden önce eskidir).
  double? _latest;

  @override
  void initState() {
    super.initState();
    if (_lens == null) {
      loadGlassLens().then((p) {
        if (mounted && p != null) setState(() => _lens = p);
      });
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _down() {
    _latest = widget.value;
    if (_reduce) {
      _press.value = 1;
    } else {
      _press.animateTo(1, duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic);
    }
  }

  void _up() {
    widget.onChangeEnd?.call(_latest ?? widget.value);
    _latest = null;
    if (_reduce) {
      _press.value = 0;
    } else {
      _press.animateWith(SpringSimulation(_releaseSpring, _press.value, 0, _press.velocity));
    }
  }

  /// Topuz merkezinin hareket aralığı (ray alanında).
  double get _span => (_width - _kKnobRest.width).clamp(1.0, double.infinity);

  void _set(double v) {
    final c = v.clamp(0.0, 1.0);
    final prevValue = _latest ?? widget.value;
    _latest = c;
    // 0 / 0.5 / 1 noktalarından geçerken hafif titreşim.
    for (final t in const [0.0, 0.5, 1.0]) {
      final prev = prevValue;
      if ((prev - t) * (c - t) <= 0 && prev != c && _lastTick != t) {
        HapticFeedback.selectionClick();
        _lastTick = t;
      }
    }
    if ((c - (_lastTick ?? -1)).abs() > 0.04) _lastTick = null;
    if (c != prevValue) widget.onChanged(c);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.value * 100).round();
    return Semantics(
      label: widget.semanticLabel,
      value: '%$pct',
      slider: true,
      increasedValue: '%${(pct + 10).clamp(0, 100)}',
      decreasedValue: '%${(pct - 10).clamp(0, 100)}',
      onIncrease: () => _set(widget.value + 0.1),
      onDecrease: () => _set(widget.value - 0.1),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 14),
            const CustomPaint(size: Size(22, 22), painter: _ClearGlyph()),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                _width = c.maxWidth;
                // Basılı hâl ham işaretçiyle (parmak değdiği an cam olur, kalkınca döner);
                // değer: dokunuş = o noktaya atla, yatay sürükleme = farkla kaydır.
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => _down(),
                  onPointerUp: (_) => _up(),
                  onPointerCancel: (_) => _up(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _set((d.localPosition.dx - _kKnobRest.width / 2) / _span),
                    onHorizontalDragUpdate: (d) => _set((_latest ?? widget.value) + d.delta.dx / _span),
                    child: AnimatedBuilder(
                      animation: _press,
                      builder: (context, _) => _buildTrack(c.maxWidth),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            const CustomPaint(size: Size(22, 22), painter: _TintedGlyph()),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildTrack(double w) {
    final p = _press.value;
    final pc = p.clamp(0.0, 1.0);
    final cx = _kKnobRest.width / 2 + widget.value * _span;
    final knobW = ui.lerpDouble(_kKnobRest.width, _kKnobPressed.width, p)!;
    final knobH = ui.lerpDouble(_kKnobRest.height, _kKnobPressed.height, p)!;
    const cy = 26.0;
    final lens = debugDisableGlassLens ? null : _lens;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ray + dolgu + noktalar.
        Positioned.fill(
          child: CustomPaint(
            painter: _TrackPainter(fillTo: cx, span: _span, cy: cy),
          ),
        ),
        // Topuz.
        Positioned(
          key: const ValueKey('liquidGlassSliderKnob'),
          left: cx - knobW / 2,
          top: cy - knobH / 2,
          width: knobW,
          height: knobH,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(knobH / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18 + 0.22 * pc),
                    blurRadius: 6 + 8 * pc,
                    offset: Offset(0, 1 + 2 * pc),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(knobH / 2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cam mercek (basılıyken): altındaki rayı büyütür.
                    if (pc > 0.01)
                      Opacity(
                        opacity: pc,
                        child: lens != null
                            ? GlassLensBackdrop(
                                program: lens,
                                zoom: 1 + 0.35 * pc,
                                child: const ColoredBox(color: Color(0x14FFFFFF)),
                              )
                            : const ColoredBox(color: Color(0x26FFFFFF)),
                      ),
                    // Beyaz kapsül (durağan): basınca solar.
                    if (pc < 0.99) ColoredBox(color: Colors.white.withValues(alpha: 1 - pc)),
                    if (pc > 0.01)
                      CustomPaint(painter: _KnobRimPainter(pc)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.fillTo, required this.span, required this.cy});

  final double fillTo;
  final double span;
  final double cy;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cy - _kTrackH / 2, size.width, _kTrackH),
      const Radius.circular(_kTrackH / 2),
    );
    canvas.drawRRect(track, Paint()..color = _kTrack);
    final fill = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cy - _kTrackH / 2, fillTo.clamp(0.0, size.width), _kTrackH),
      const Radius.circular(_kTrackH / 2),
    );
    canvas.drawRRect(fill, Paint()..color = _kFill);
    final dot = Paint()..color = _kTick;
    for (final t in const [0.0, 0.5, 1.0]) {
      canvas.drawCircle(Offset(_kKnobRest.width / 2 + t * span, cy + _kTickGap), 1.4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) =>
      old.fillTo != fillTo || old.span != span || old.cy != cy;
}

/// Cam topuzun kenarı: koyu dış çizgi + altta yakalanan ışık + üstte ince parlama.
class _KnobRimPainter extends CustomPainter {
  _KnobRimPainter(this.a);
  final double a;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.6), Radius.circular(size.height / 2));
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.30 * a),
            Colors.white.withValues(alpha: 0.05 * a),
            Colors.white.withValues(alpha: 0.38 * a),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _KnobRimPainter old) => old.a != a;
}

/// "Şeffaf": iki üst üste yuvarlak köşeli çizgi kare.
class _ClearGlyph extends CustomPainter {
  const _ClearGlyph();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = _kIcon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * k;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(3 * k, 4 * k, 13 * k, 11 * k), Radius.circular(3.2 * k)), p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(8 * k, 9 * k, 13 * k, 11 * k), Radius.circular(3.2 * k)), p);
  }

  @override
  bool shouldRepaint(covariant _ClearGlyph old) => false;
}

/// "Renkli": arkada çizgi, önde dolu yuvarlak köşeli kare.
class _TintedGlyph extends CustomPainter {
  const _TintedGlyph();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3 * k, 4 * k, 13 * k, 11 * k), Radius.circular(3.2 * k)),
      Paint()
        ..color = _kIcon
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * k,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8 * k, 9 * k, 13 * k, 11 * k), Radius.circular(3.2 * k)),
      Paint()..color = _kIcon,
    );
  }

  @override
  bool shouldRepaint(covariant _TintedGlyph old) => false;
}
