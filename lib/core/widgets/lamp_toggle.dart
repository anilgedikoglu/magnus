// lib/core/widgets/lamp_toggle.dart
//
// Bildirimler düğmesi (Anıl, 2026-11-08). Referans: Zsolt Kacso "Glass Light Toggle"
// (experiments.thisiswhitespace.com/glass-light-toggle) — sürgü fiziği, cam, LED şerit ve
// noktaların dağılıp yeniden toplanması birebir; yalnız ikon güneş/ay yerine yanan/sönük lamba.
// ⚠️ Kaynağın lisansı yok: mağazaya çıkmadan yazardan izin alınmalı (HANDOFF.md).
//
// Optik tümüyle shaders/lamp_toggle.frag'da. Burada: durum fiziği (yay), her nokta için ayrı
// yay, noktaların dokuya basılması, dokunma/sürükleme.
// İlerleme p: 0 = kapalı (karanlık, düğme solda), 1 = açık (aydınlık, düğme sağda).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const double _kTrackHalfW = 216;
const double _kTrackHalfH = 112;
const double _kTrackR = 72;
const double _kKnobHalf = 99;
const double _kKnobR = 58;
const double _kTravel = _kTrackHalfW - 13 - _kKnobHalf; // düğme merkezi ±104
const int _kGrid = 17;
const int _kMid = 8;
const double _kPitch = 5.7;
const double _kDot = 4.6;
const double _kSwirl = 1.62;
const double _kBurst = 0.38;
const double _kStiffness = 129;
const double _kLedPower = 1.89;
const double _kLightSpan = _kTrackHalfW + 12; // ikon dokusunun yarı eni
const double _kLightSpanY = _kTrackHalfH + 8; // ikon dokusunun yarı boyu

const Color _kOffLight = Color(0xFF6F86FF);
const Color _kOnLight = Color(0xFFFFA82E);

/// Uygulamadaki sahne (tasarım px): iz + gölge ve LED taşması için kenar payı.
const Size kLampStage = Size(520, 320);

enum _DotKind { solid, dim, star, ray }

class _Cell {
  const _Cell(this.x, this.y, this.b, this.kind, [this.ang = 0]);
  final int x, y;
  final double b;
  final _DotKind kind;
  final double ang;
  _Cell withB(double v) => _Cell(x, y, v, kind, ang);
}

/// Kapalı lamba: parlak cam çeperi, loş dama iç, duy, gece yıldızları.
List<_Cell> _lampOff() {
  final out = <_Cell>[];
  for (var y = 0; y < _kGrid; y++) {
    for (var x = 0; x < _kGrid; x++) {
      final dx = x - 8.0, dy = y - 6.4;
      final d2 = dx * dx + dy * dy;
      if (d2 <= 4.4 * 4.4) {
        if (d2 > 3.2 * 3.2) {
          out.add(_Cell(x, y, 1, _DotKind.solid));
        } else if ((x + y).isEven) {
          out.add(_Cell(x, y, 0.2, _DotKind.dim));
        }
      }
    }
  }
  out.addAll(_lampBase(_DotKind.solid));
  const stars = [[15, 1, 1.0], [14, 1, .45], [16, 1, .45], [15, 0, .45], [15, 2, .45], [12, 0, .75], [16, 5, .6]];
  for (final s in stars) {
    out.add(_Cell(s[0] as int, s[1] as int, s[2] as double, _DotKind.star));
  }
  return out;
}

/// Yanan lamba: dolu ampul, duy, çevresinde ışınlar.
List<_Cell> _lampOn() {
  final m = <String, _Cell>{};
  void add(_Cell c) => m.putIfAbsent('${c.x},${c.y}', () => c);
  for (var y = 0; y < _kGrid; y++) {
    for (var x = 0; x < _kGrid; x++) {
      final dx = x - 8.0, dy = y - 6.4;
      if (dx * dx + dy * dy <= 4.4 * 4.4) add(_Cell(x, y, 1, _DotKind.solid));
    }
  }
  _lampBase(_DotKind.solid).forEach(add);
  // Ampulün çevresinde 7 ışın (alt-orta duya denk gelir, atlanır).
  for (var a = 0; a < 8; a++) {
    if (a == 2) continue;
    final ang = a * math.pi / 4;
    final rs = a.isEven ? const [5.9, 7.0] : const [5.9, 7.1];
    for (final r in rs) {
      final x = (8 + math.cos(ang) * r).round(), y = (6.4 + math.sin(ang) * r).round();
      if (x >= 0 && x < _kGrid && y >= 0 && y < _kGrid) add(_Cell(x, y, 1, _DotKind.ray, ang));
    }
  }
  return m.values.toList();
}

List<_Cell> _lampBase(_DotKind kind) => [
      for (var x = 6; x <= 10; x++) _Cell(x, 11, 1, kind),
      for (var x = 6; x <= 10; x++) _Cell(x, 12, 0.55, kind),
      for (var x = 6; x <= 10; x++) _Cell(x, 13, 1, kind),
      for (var x = 7; x <= 9; x++) _Cell(x, 14, 0.55, kind),
      _Cell(8, 15, 1, kind),
    ];

/// Yalnız referansla kare kare karşılaştırma: kaynaktaki ay.
List<_Cell> _refMoon() {
  final out = <_Cell>[];
  for (var y = 0; y < _kGrid; y++) {
    for (var x = 0; x < _kGrid; x++) {
      final dx = x - _kMid, dy = y - _kMid;
      final main = dx * dx + dy * dy <= 6.6 * 6.6;
      final sx = x - 11.3, sy = y - 5.6;
      final shade = sx * sx + sy * sy <= 5.4 * 5.4;
      if (main && !shade) {
        final half = (x == 3 && y == 9) || (x == 6 && y == 12) || (x == 4 && y == 12);
        out.add(_Cell(x, y, half ? .5 : 1, _DotKind.solid));
      } else if (main && shade && (x + y).isEven) {
        out.add(_Cell(x, y, .2, _DotKind.dim));
      }
    }
  }
  const stars = [[15, 1, 1.0], [14, 1, .45], [16, 1, .45], [15, 0, .45], [15, 2, .45], [11, 0, .75], [16, 5, .6]];
  for (final s in stars) {
    out.add(_Cell(s[0] as int, s[1] as int, s[2] as double, _DotKind.star));
  }
  return out;
}

/// Yalnız referansla kare kare karşılaştırma: kaynaktaki güneş.
List<_Cell> _refSun() {
  final m = <String, _Cell>{};
  void add(_Cell c) => m.putIfAbsent('${c.x},${c.y}', () => c);
  for (var y = 0; y < _kGrid; y++) {
    for (var x = 0; x < _kGrid; x++) {
      final dx = x - _kMid, dy = y - _kMid;
      if (dx * dx + dy * dy <= 3.7 * 3.7) add(_Cell(x, y, 1, _DotKind.solid));
    }
  }
  for (var a = 0; a < 8; a++) {
    final ang = a * math.pi / 4;
    final rs = a.isOdd ? const [5.9, 7.2] : const [5.6, 6.6, 7.6];
    for (final r in rs) {
      add(_Cell((_kMid + math.cos(ang) * r).round(), (_kMid + math.sin(ang) * r).round(), 1, _DotKind.ray, ang));
    }
  }
  return m.values.toList();
}

class _Dot {
  _Dot(this.a, this.b, math.Random r)
      : delay = .04 + (1 - a.x / (_kGrid - 1)) * .26 + r.nextDouble() * .06,
        curl = (r.nextDouble() * 2 - 1) * 16 + (a.y - _kMid) * .9,
        lift = 2 + r.nextDouble() * 10,
        k = 260 + r.nextDouble() * 200,
        drag = .004 + r.nextDouble() * .012,
        phase = r.nextDouble() * math.pi * 2,
        twinkle = 1.5 + r.nextDouble() * 1.7;

  final _Cell a, b;
  final double delay, curl, lift, k, drag, phase, twinkle;
  double x = 0, y = 0, vx = 0, vy = 0;
  double sx = 0, sy = 0, bright = 0, size = _kDot;
  bool ready = false;
}

double _sweep(_Cell c) {
  final a = math.atan2((c.y - _kMid).toDouble(), (c.x - _kMid).toDouble());
  final dist = math.sqrt(math.pow(c.x - _kMid, 2) + math.pow(c.y - _kMid, 2));
  return ((a + math.pi * .75 + math.pi * 2) % (math.pi * 2)) + dist * 1e-3;
}

/// İki ikonun noktalarını açıya göre eşle: dönüşüm tek bir girdap gibi okunsun.
List<_Dot> _pairDots(List<_Cell> off, List<_Cell> on, math.Random r) {
  final a = [...off]..sort((p, q) => _sweep(p).compareTo(_sweep(q)));
  final b = [...on]..sort((p, q) => _sweep(p).compareTo(_sweep(q)));
  final aBigger = a.length >= b.length;
  final big = aBigger ? a : b, small = aBigger ? b : a;
  final dots = <_Dot>[];
  var last = -1;
  for (var i = 0; i < big.length; i++) {
    final j = (i * small.length / big.length).floor();
    final first = j != last;
    last = j;
    final other = first ? small[j] : small[j].withB(0);
    dots.add(aBigger ? _Dot(big[i], other, r) : _Dot(other, big[i], r));
  }
  return dots;
}

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _easeInOut(double t) =>
    t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;

/// Sürgü + nokta fiziği. Yalnız durum; çizim bilmez.
class _LampSim {
  _LampSim(bool on, List<_Cell> off, List<_Cell> lit, math.Random r)
      : p = on ? 1 : 0,
        target = on ? 1 : 0,
        strip = on ? 1 : 0,
        orbitDir = on ? -1 : 1,
        dots = _pairDots(off, lit, r);

  double p, target, strip;
  double v = 0, stripV = 0, press = 0, pressTarget = 0, kick = 0, led = 1;
  int orbitDir;
  bool dragging = false;
  final List<_Dot> dots;

  double knobX = 0, knobHalfX = _kKnobHalf, knobHalfY = _kKnobHalf;
  double theme = 0, theta = 0;

  void step(double dt, double time, {bool still = false}) {
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
    final over = math.max(math.max(-p, p - 1), 0.0);
    final stretch = math.min(v.abs() * 6.5, 16.0);
    final squeeze = 1 - press * .035;
    knobHalfX = (_kKnobHalf + stretch - over * 110) * squeeze;
    knobHalfY = math.min(_kKnobHalf - stretch * .45 + over * 30, _kKnobHalf + 5) * squeeze;
    knobX = -_kTravel + 2 * _kTravel * pc;
    if (p > 1) {
      knobX += over * 110;
    } else if (p < 0) {
      knobX -= over * 110;
    }
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
    final sp = strip.clamp(0.0, 1.0);
    if (sp < .015) {
      orbitDir = 1;
    } else if (sp > .985) {
      orbitDir = -1;
    }
    theta = orbitDir > 0 ? math.pi / 2 - math.pi * sp : -math.pi / 2 - math.pi * (1 - sp);

    final knobSpeed = v * 2 * _kTravel;
    for (final d in dots) {
      _stepDot(d, pc, still ? 0 : time, dt, knobSpeed, still);
    }
  }

  void _stepDot(_Dot d, double pc, double time, double dt, double knobSpeed, bool still) {
    final e = _easeInOut(((pc - d.delay) / .62).clamp(0.0, 1.0));
    final ox = (d.a.x - _kMid) * _kPitch, oy = (d.a.y - _kMid) * _kPitch;
    final dx = (d.b.x - _kMid) * _kPitch - ox, dy = (d.b.y - _kMid) * _kPitch - oy;
    final len = math.max(math.sqrt(dx * dx + dy * dy), 1e-9);
    final arc = math.sin(math.pi * e);
    var tx = ox + dx * e + (-dy / (dx == 0 && dy == 0 ? 1 : len)) * d.curl * _kSwirl * arc;
    var ty = oy + dy * e + (dx / (dx == 0 && dy == 0 ? 1 : len)) * d.curl * _kSwirl * arc;
    final r = math.max(math.sqrt(tx * tx + ty * ty), 1e-9);
    tx += (tx / r) * d.lift * arc * 1.4 * _kBurst;
    ty += (ty / r) * d.lift * arc * 1.4 * _kBurst;

    var ba = d.a.b, bb = d.b.b;
    if (d.a.kind == _DotKind.star) {
      ba *= .45 + .55 * math.pow(math.sin(time * d.twinkle + d.phase), 2);
    }
    if (d.b.kind == _DotKind.ray) {
      bb *= .78 + .22 * (.5 + .5 * math.sin(time * 2.2 - d.b.ang));
    }
    d.bright = (ba + (bb - ba) * e) * (1 + .3 * arc);
    d.size = _kDot * (1 - .45 * arc);

    if (!d.ready || still) {
      d.x = tx;
      d.y = ty;
      d.vx = 0;
      d.vy = 0;
      d.ready = true;
    }
    final c = 2 * math.sqrt(d.k) * .72;
    d.vx += (-d.k * (d.x - tx) - c * d.vx) * dt;
    d.vy += (-d.k * (d.y - ty) - c * d.vy) * dt;
    d.x += d.vx * dt;
    d.y += d.vy * dt;
    d.sx = knobX + d.x + (-knobSpeed * d.drag).clamp(-14.0, 14.0);
    d.sy = d.y;
  }

  bool get atRest =>
      !dragging &&
      (p - target).abs() < .0005 &&
      v.abs() < .002 &&
      (strip - p.clamp(0.0, 1.0)).abs() < .002 &&
      press < .01;
}

/// Cam sürgü: [value] true = yanan lamba, sağda, aydınlık.
class LampToggle extends StatefulWidget {
  const LampToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.debugReferenceIcons = false,
    this.debugStage,
    this.debugOriginOffset = Offset.zero,
    this.debugProgress,
    this.debugSeed,
    this.debugTime,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  /// Yalnız karşılaştırma: kaynaktaki güneş/ay ikonları.
  @visibleForTesting
  final bool debugReferenceIcons;

  /// Yalnız karşılaştırma: sahnenin tasarım boyu (varsayılan [kLampStage]).
  @visibleForTesting
  final Size? debugStage;

  /// Yalnız karşılaştırma: iz merkezinin sahne merkezine göre kayması (tasarım px).
  @visibleForTesting
  final Offset debugOriginOffset;

  /// Yalnız karşılaştırma: p'yi sabitle (sürüklenmiş gibi).
  @visibleForTesting
  final double? debugProgress;

  @visibleForTesting
  final int? debugSeed;

  /// Yalnız karşılaştırma: sabit zaman (tohumlu gren/ışıltı).
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
  bool _downOnKnob = false;

  Size get _stage => widget.debugStage ?? kLampStage;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.debugSeed ?? 7);
    _sim = _LampSim(
      widget.value,
      widget.debugReferenceIcons ? _refMoon() : _lampOff(),
      widget.debugReferenceIcons ? _refSun() : _lampOn(),
      rnd,
    );
    _applyDebugP();
    _sim.step(1 / 60, widget.debugTime ?? 0);
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
      _sim.step(1 / 60, 0, still: true);
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
    _sim.step(dt, widget.debugTime ?? _time, still: _reduce);
    if (_reduce && _sim.atRest) {
      _repaint.value++;
      _ticker.stop();
      return;
    }
    // Dururken 30 Hz yeter (yıldız ışıltısı + gren); hareket varken her kare.
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

  double get _scale => context.size == null ? 1 : context.size!.width / _stage.width;

  Offset _toDesign(Offset local) {
    final size = context.size ?? Size.zero;
    return (local - size.center(Offset.zero)) / _scale - widget.debugOriginOffset;
  }

  static bool _inRRect(Offset p, Offset c, double hw, double hh, double r) {
    final qx = (p.dx - c.dx).abs() - hw + r, qy = (p.dy - c.dy).abs() - hh + r;
    return math.sqrt(math.pow(math.max(qx, 0), 2) + math.pow(math.max(qy, 0), 2)) +
            math.min(math.max(qx, qy), 0) -
            r <=
        0;
  }

  bool _overTrack(Offset local) =>
      _inRRect(_toDesign(local), Offset.zero, _kTrackHalfW, _kTrackHalfH, _kTrackR);
  bool _overKnob(Offset local) => _inRRect(
      _toDesign(local), Offset(_sim.knobX, 0), _kKnobHalf, _kKnobHalf, _kKnobR);

  void _onDown(Offset local) {
    if (!_overTrack(local)) return;
    _sim.pressTarget = 1;
    _downOnKnob = _overKnob(local);
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
    var p = _dragStartP + (_dragDx / _scale) / (2 * _kTravel);
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

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    return Semantics(
      button: true,
      toggled: widget.value,
      label: widget.semanticLabel,
      onTap: _toggle,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: _stage.width / _stage.height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onDown(d.localPosition),
          onTapCancel: () => _sim.pressTarget = 0,
          onTapUp: (d) {
            _sim.pressTarget = 0;
            if (_overTrack(d.localPosition) || _downOnKnob) _toggle();
            _downOnKnob = false;
          },
          onHorizontalDragDown: (d) => _onDown(d.localPosition),
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: (_) => _onDragEnd(),
          onHorizontalDragCancel: _onDragEnd,
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _LampPainter(
                sim: _sim,
                shader: _shader,
                stage: _stage,
                originOffset: widget.debugOriginOffset,
                dpr: dpr,
                timeOf: () => widget.debugTime ?? _time,
                repaint: _repaint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter({
    required this.sim,
    required this.shader,
    required this.stage,
    required this.originOffset,
    required this.dpr,
    required this.timeOf,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _LampSim sim;
  final ui.FragmentShader? shader;
  final Size stage;
  final Offset originOffset;
  final double dpr;
  final double Function() timeOf;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / stage.width;
    final origin = size.center(Offset.zero) + originOffset * scale;
    final s = shader;
    if (s == null) {
      _paintFallback(canvas, size, origin, scale);
      return;
    }
    final texScale = (scale * dpr).clamp(1.0, 2.0);
    final w = (2 * _kLightSpan * texScale).ceil();
    final h = (2 * _kLightSpanY * texScale).ceil();

    final rec = ui.PictureRecorder();
    final c = Canvas(rec)
      ..scale(texScale)
      ..translate(_kLightSpan, _kLightSpanY);
    final dot = Paint();
    for (final d in sim.dots) {
      if (d.bright <= .002) continue;
      dot.color = Color.fromRGBO(255, 255, 255, math.min(1.0, d.bright));
      c.drawRect(Rect.fromCenter(center: Offset(d.sx, d.sy), width: d.size, height: d.size), dot);
    }
    final pic = rec.endRecording();
    final sharp = pic.toImageSync(w, h);
    pic.dispose();

    final rec2 = ui.PictureRecorder();
    final gw = (w / 2).ceil(), gh = (h / 2).ceil();
    final blur = 2 * texScale; // tasarımda σ = 4 px (doku yarı çözünürlükte)
    Canvas(rec2).drawImageRect(
      sharp,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Rect.fromLTWH(0, 0, gw.toDouble(), gh.toDouble()),
      Paint()
        ..filterQuality = FilterQuality.low
        ..imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
    );
    final pic2 = rec2.endRecording();
    final soft = pic2.toImageSync(gw, gh);
    pic2.dispose();

    final light = Color.lerp(_kOffLight, _kOnLight, sim.theme)!;
    final kr = math.min(_kKnobR, math.min(sim.knobHalfX - 1, sim.knobHalfY - 1));
    final uniforms = <double>[
      size.width, size.height,
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
      _kLightSpan, _kLightSpanY,
      dpr,
    ];
    for (var i = 0; i < uniforms.length; i++) {
      s.setFloat(i, uniforms[i]);
    }
    s
      ..setImageSampler(0, sharp, filterQuality: FilterQuality.low)
      ..setImageSampler(1, soft, filterQuality: FilterQuality.low);
    canvas.drawRect(Offset.zero & size, Paint()..shader = s);
    sharp.dispose();
    soft.dispose();
  }

  // Shader yüklenene / yüklenemezse: düz iz + düğme (aynı konum).
  void _paintFallback(Canvas canvas, Size size, Offset origin, double scale) {
    final th = sim.theme;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Color.lerp(const Color(0xFF0A0A0A), const Color(0xFFD3D1CF), th)!);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: origin, width: 2 * _kTrackHalfW * scale, height: 2 * _kTrackHalfH * scale),
        Radius.circular(_kTrackR * scale),
      ),
      Paint()..color = Color.lerp(const Color(0xFF080808), const Color(0xFFE6E4E2), th)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: origin + Offset(sim.knobX * scale, 0),
            width: 2 * _kKnobHalf * scale,
            height: 2 * _kKnobHalf * scale),
        Radius.circular(_kKnobR * scale),
      ),
      Paint()..color = Color.lerp(const Color(0xFF2A2A2E), const Color(0xFFF4F2EF), th)!,
    );
  }

  @override
  bool shouldRepaint(_LampPainter old) =>
      old.shader != shader || old.stage != stage || old.dpr != dpr || old.sim != sim;
}
