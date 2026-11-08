// lib/core/widgets/lamp_toggle.dart
//
// Bildirimler düğmesi (Anıl, 2026-11-08): sürgü fiziği, cam, LED şerit. Sürgünün ortasında AÇIK / KAPALI.
// Optik tümüyle shaders/lamp_toggle.frag'da. Burada: durum fiziği (yay), yazı, dokunma/sürükleme.
// İlerleme p: 0 = kapalı (koyu sürgü sağ yarıda), 1 = açık (aydınlık sürgü sol yarıda).
// Dış biçim CAM önizlemesiyle aynı: tam en, kGlassBarHeight boy, tam kapsül (Anıl, 2026-11-08).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../constants/app_text_styles.dart';
import 'glass_tab_bar.dart' show kGlassBarHeight;

const double _kOuterHalfH = 112; // dış çerçeve (= kGlassBarHeight)
const double _kFrame = 22; // çerçeve kalınlığı (~6 pt)
const double _kTrackHalfH = _kOuterHalfH - _kFrame; // sürgünün oturduğu oyuk iz
const double _kBarScale = kGlassBarHeight / (2 * _kOuterHalfH); // mantıksal px / tasarım px
const double _kInset = 13; // sürgünün izden payı
const double _kCenterGap = 7; // sürgü ortadan bu kadar önce biter
const double _kKnobHalfY = _kTrackHalfH - _kInset;
const double _kStiffness = 129;
const double _kLedPower = 1.89;

const Color _kOffLight = Color(0xFF6F86FF);
const Color _kOnLight = Color(0xFFFFA82E);

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _easeInOut(double t) =>
    t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;

/// Sürgü + nokta fiziği. Yalnız durum; çizim bilmez.
class _LampSim {
  _LampSim(bool on)
      : p = on ? 1 : 0,
        target = on ? 1 : 0,
        strip = on ? 1 : 0,
        orbitDir = on ? -1 : 1;

  double p, target, strip;
  double v = 0, stripV = 0, press = 0, pressTarget = 0, kick = 0, led = 1;
  int orbitDir;
  bool dragging = false;

  double trackHalfW = 400;
  double knobX = 0, knobHalfX = 0, knobHalfY = _kKnobHalfY;
  double theme = 0, theta = 0;

  double get knobBaseX => (trackHalfW - _kInset - _kCenterGap) / 2;
  double get travel => trackHalfW - _kInset - knobBaseX;

  /// İz eni bilinince sürgüyü yerleştir.
  void layout(double halfW) {
    trackHalfW = halfW;
    _placeKnob();
  }

  void _placeKnob() {
    final pc = p.clamp(0.0, 1.0);
    final over = math.max(math.max(-p, p - 1), 0.0);
    final stretch = math.min(v.abs() * 6.5, 16.0);
    final squeeze = 1 - press * .035;
    knobHalfX = (knobBaseX + stretch - over * 110) * squeeze;
    knobHalfY = math.min(_kKnobHalfY - stretch * .45 + over * 30, _kKnobHalfY + 5) * squeeze;
    knobX = travel - 2 * travel * pc; // açıkken sol yarı, kapalıyken sağ yarı
    if (p > 1) {
      knobX -= over * 110;
    } else if (p < 0) {
      knobX += over * 110;
    }
  }

  void step(double dt, {bool still = false}) {
    if (!dragging) {
      final c = 2 * math.sqrt(_kStiffness) * .6;
      final h = dt / 4;
      for (var i = 0; i < 4; i++) {
        v += (-_kStiffness * (p - target) - c * v) * h;
        p += v * h;
      }
    }
    if (still) {
      p = target;
      v = 0;
    }
    press += (pressTarget - press) * math.min(1, dt * 18);
    kick *= math.exp(-dt * 3.5);
    led = 1 + math.min(v.abs() * .05, .18) + kick * .12;

    final pc = p.clamp(0.0, 1.0);
    _placeKnob();
    theme = _smooth(.18, .82, pc);

    // Şerit düğmenin çevresinde tek yönde döner; yön yalnız dururken kilitlenir.
    final goal = _easeInOut(pc);
    const sk = 70.0;
    stripV += (-sk * (strip - goal) - 2 * math.sqrt(sk) * stripV) * dt;
    strip += stripV * dt;
    if (still) {
      strip = goal;
      stripV = 0;
    }
    // Yön yalnız şerit hedefe tam oturunca değişir; erken değişirse hedefin öbür yanına atlar.
    var sp = strip.clamp(0.0, 1.0);
    if (sp < .0005) {
      strip = sp = 0;
      stripV = 0;
      orbitDir = 1;
    } else if (sp > .9995) {
      strip = sp = 1;
      stripV = 0;
      orbitDir = -1;
    }
    theta = orbitDir > 0 ? math.pi / 2 - math.pi * sp : -math.pi / 2 - math.pi * (1 - sp);
  }

  bool get atRest =>
      !dragging &&
      (p - target).abs() < .0005 &&
      v.abs() < .002 &&
      (strip - p.clamp(0.0, 1.0)).abs() < .002 &&
      press < .01;
}

/// Cam sürgü: [value] true = açık, sol yarıda, amber.
class LampToggle extends StatefulWidget {
  const LampToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.onLabel = '',
    this.offLabel = '',
    this.debugProgress,
    this.debugTime,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  /// Sürgünün ortasındaki yazılar.
  final String onLabel;
  final String offLabel;

  /// Yalnız görsel doğrulama: p'yi sabitle (sürüklenmiş gibi).
  @visibleForTesting
  final double? debugProgress;

  /// Yalnız görsel doğrulama: sabit zaman (tohumlu gren/ışıltı).
  @visibleForTesting
  final double? debugTime;

  /// Shader'ı önceden yükle (ilk gösterimde boş kare olmasın).
  static Future<void> preload() => _LampToggleState._loadProgram();

  @override
  State<LampToggle> createState() => _LampToggleState();
}

class _LampToggleState extends State<LampToggle> with SingleTickerProviderStateMixin {
  static ui.FragmentProgram? _program;
  static Future<void>? _loading;

  static Future<void> _loadProgram() => _loading ??= () async {
        try {
          _program = await ui.FragmentProgram.fromAsset('shaders/lamp_toggle.frag');
        } catch (e) {
          debugPrint('LampToggle shader yüklenemedi: $e');
        }
      }();

  late _LampSim _sim;
  late Ticker _ticker;
  final _repaint = ValueNotifier<int>(0);
  ui.FragmentShader? _shader;
  Duration _last = Duration.zero;
  double _time = 0;
  bool _reduce = false;
  int _idleFrames = 0;

  // Sürükleme
  double _dragStartP = 0, _moved = 0, _dragV = 0;
  double _dragDx = 0;
  Duration _dragT = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sim = _LampSim(widget.value);
    _applyDebugP();
    _sim.step(1 / 60);
    _ticker = createTicker(_onTick);
    _loadProgram().then((_) {
      if (!mounted || _program == null) return;
      setState(() => _shader = _program!.fragmentShader());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _ensureTicking();
  }

  @override
  void didUpdateWidget(covariant LampToggle old) {
    super.didUpdateWidget(old);
    final t = widget.value ? 1.0 : 0.0;
    if (t != _sim.target && !_sim.dragging) {
      _sim.target = t;
      _sim.kick = 1;
      _ensureTicking();
    }
  }

  void _applyDebugP() {
    final dp = widget.debugProgress;
    if (dp != null) {
      _sim.p = dp;
      _sim.v = 0;
      _sim.dragging = true;
    }
  }

  void _ensureTicking() {
    final needs = !_reduce || !_sim.atRest;
    if (needs && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (_reduce && _sim.atRest && _ticker.isActive) {
      _sim.step(1 / 60, still: true);
      _repaint.value++;
      _ticker.stop();
    }
  }

  void _onTick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : math.min(1 / 30, (now - _last).inMicroseconds / 1e6);
    _last = now;
    _dragT = now;
    _time += dt;
    _applyDebugP();
    _sim.step(dt, still: _reduce);
    if (_reduce && _sim.atRest) {
      _repaint.value++;
      _ticker.stop();
      return;
    }
    // Dururken 30 Hz yeter (gren); hareket varken her kare.
    if (_sim.atRest) {
      _idleFrames++;
      if (_idleFrames.isOdd) return;
    } else {
      _idleFrames = 0;
    }
    _repaint.value++;
  }

  void _commit(bool on) {
    HapticFeedback.mediumImpact();
    widget.onChanged(on);
  }

  void _toggle() {
    final on = _sim.target <= .5;
    _sim.target = on ? 1 : 0;
    _sim.kick = 1;
    _ensureTicking();
    _commit(on);
  }

  Offset _toDesign(Offset local) {
    final size = context.size ?? Size.zero;
    return (local - size.center(Offset.zero)) / _kBarScale;
  }

  static bool _inRRect(Offset p, Offset c, double hw, double hh, double r) {
    final qx = (p.dx - c.dx).abs() - hw + r, qy = (p.dy - c.dy).abs() - hh + r;
    return math.sqrt(math.pow(math.max(qx, 0), 2) + math.pow(math.max(qy, 0), 2)) +
            math.min(math.max(qx, qy), 0) -
            r <=
        0;
  }

  bool _overKnob(Offset local) => _inRRect(_toDesign(local), Offset(_sim.knobX, 0),
      _sim.knobBaseX, _kKnobHalfY, _kKnobHalfY);

  void _onDown() {
    _sim.pressTarget = 1;
    _ensureTicking();
  }

  void _onDragStart(DragStartDetails d) {
    if (!_overKnob(d.localPosition)) return;
    _sim
      ..dragging = true
      ..pressTarget = 1;
    _dragStartP = _sim.p;
    _dragDx = 0;
    _moved = 0;
    _dragV = 0;
    _ensureTicking();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_sim.dragging) return;
    _dragDx += d.delta.dx;
    _moved = math.max(_moved, _dragDx.abs());
    var p = _dragStartP - (_dragDx / _kBarScale) / (2 * _sim.travel); // sola çekmek açar
    if (p > 1) p = 1 + (p - 1) * .22;
    if (p < 0) p *= .22;
    final ts = d.sourceTimeStamp ?? _dragT;
    final ddt = math.max(1, (ts - _lastDragStamp).inMilliseconds) / 1000;
    _lastDragStamp = ts;
    _dragV = _dragV * .6 + ((p - _sim.p) / ddt) * .4;
    _sim
      ..v = _dragV
      ..p = p;
  }

  Duration _lastDragStamp = Duration.zero;

  void _onDragEnd() {
    _sim.pressTarget = 0;
    if (!_sim.dragging) return;
    _sim.dragging = false;
    if (_moved < 4) {
      _toggle();
      return;
    }
    final on = (_sim.p + _dragV * .15) > .5;
    _sim
      ..target = on ? 1 : 0
      ..kick = .6;
    _ensureTicking();
    if (on != widget.value) _commit(on);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    _repaint.dispose();
    super.dispose();
  }

  static final TextStyle _labelStyle = AppTextStyles.uiLabel.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    color: Colors.white,
    decoration: TextDecoration.none,
    shadows: const [Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1))],
  );

  /// Sürgüyle birlikte kayan, ortalı AÇIK / KAPALI; geçişin ortasında biri söner, öteki belirir.
  Widget _knobLabel() => IgnorePointer(
        child: AnimatedBuilder(
          animation: _repaint,
          builder: (context, _) {
            final t = _sim.theme;
            return Center(
              child: Transform.translate(
                offset: Offset(_sim.knobX * _kBarScale, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: (1 - t * 2).clamp(0.0, 1.0),
                      child: Text(widget.offLabel, maxLines: 1, style: _labelStyle),
                    ),
                    Opacity(
                      opacity: (t * 2 - 1).clamp(0.0, 1.0),
                      child: Text(widget.onLabel, maxLines: 1, style: _labelStyle),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    return Semantics(
      button: true,
      toggled: widget.value,
      label: widget.semanticLabel,
      onTap: _toggle,
      excludeSemantics: true,
      child: SizedBox(
        height: kGlassBarHeight,
        child: LayoutBuilder(builder: (context, box) {
          _sim.layout(box.maxWidth / (2 * _kBarScale) - _kFrame);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _onDown(),
            onTapCancel: () => _sim.pressTarget = 0,
            onTapUp: (_) {
              _sim.pressTarget = 0;
              _toggle();
            },
            onHorizontalDragDown: (_) => _onDown(),
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: (_) => _onDragEnd(),
            onHorizontalDragCancel: _onDragEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _LampPainter(
                      sim: _sim,
                      shader: _shader,
                      dpr: dpr,
                      timeOf: () => widget.debugTime ?? _time,
                      repaint: _repaint,
                    ),
                  ),
                ),
                _knobLabel(),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter({
    required this.sim,
    required this.shader,
    required this.dpr,
    required this.timeOf,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _LampSim sim;
  final ui.FragmentShader? shader;
  final double dpr;
  final double Function() timeOf;

  @override
  void paint(Canvas canvas, Size size) {
    const scale = _kBarScale;
    final origin = size.center(Offset.zero);
    final s = shader;
    if (s == null) {
      _paintFallback(canvas, origin, scale);
      return;
    }
    final light = Color.lerp(_kOffLight, _kOnLight, sim.theme)!;
    final kr = math.min(sim.knobHalfX - 1, sim.knobHalfY - 1); // tam kapsül
    final uniforms = <double>[
      origin.dx, origin.dy,
      scale,
      sim.knobX,
      sim.knobHalfX, sim.knobHalfY,
      kr,
      sim.theme,
      (timeOf() % 1) * 91.7,
      sim.led * _kLedPower,
      0, // kalkış yalnız fare üzerindeyken; dokunmatikte yok
      light.r, light.g, light.b,
      sim.theta,
      dpr,
      sim.trackHalfW,
    ];
    for (var i = 0; i < uniforms.length; i++) {
      s.setFloat(i, uniforms[i]);
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = s);
  }

  // Shader yüklenene / yüklenemezse: düz iz + düğme (aynı konum).
  void _paintFallback(Canvas canvas, Offset origin, double scale) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: origin, width: 2 * (sim.trackHalfW + _kFrame) * scale, height: 2 * _kOuterHalfH * scale),
        Radius.circular(_kOuterHalfH * scale),
      ),
      Paint()..color = const Color(0xFF1A1A1E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: origin, width: 2 * sim.trackHalfW * scale, height: 2 * _kTrackHalfH * scale),
        Radius.circular(_kTrackHalfH * scale),
      ),
      Paint()..color = const Color(0xFF080808),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: origin + Offset(sim.knobX * scale, 0),
            width: 2 * sim.knobHalfX * scale,
            height: 2 * sim.knobHalfY * scale),
        Radius.circular(sim.knobHalfY * scale),
      ),
      Paint()..color = Color.lerp(const Color(0xFF2A2A2E), const Color(0xFF6B4A1E), sim.theme)!,
    );
  }

  @override
  bool shouldRepaint(_LampPainter old) =>
      old.shader != shader || old.dpr != dpr || old.sim != sim;
}
