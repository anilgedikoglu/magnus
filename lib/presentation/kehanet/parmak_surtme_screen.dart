// C:/src/magnus_app/lib/presentation/kehanet/parmak_surtme_screen.dart
// Parmak sürtme ekranı - kahin seçimi sonrası etkileşim

import 'dart:async';
import 'dart:math';
import '../../core/widgets/edge_swipe_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../core/widgets/floating_bar_spacer.dart';

class ParmakSurtmeScreen extends StatefulWidget {
  final String kahinId;
  const ParmakSurtmeScreen({super.key, required this.kahinId});

  @override
  State<ParmakSurtmeScreen> createState() => _ParmakSurtmeScreenState();
}

class _ParmakSurtmeScreenState extends State<ParmakSurtmeScreen> {
  final List<_TailPoint> _tail = [];
  double _progress = 0.0;
  bool _done = false;
  Offset? _lastPos;
  static const double _threshold = 900.0;

  Timer? _decayTimer;
  // %100 patlaması (2026-11-06, Grok): pembe/camgöbeği parçacıklar parmaktan dışa saçılır.
  Offset? _burstOrigin;
  DateTime? _burstStart;
  double get _burstAge => _burstStart == null
      ? -1
      : DateTime.now().difference(_burstStart!).inMilliseconds / 1000;

  @override
  void initState() {
    super.initState();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final burstAlive = _burstStart != null && _burstAge < 0.9;
      if ((_tail.isEmpty && !burstAlive) || !mounted) return;
      setState(() {
        for (final p in _tail) {
          p.life -= 0.016;
        }
        _tail.removeWhere((p) => p.life <= 0);
      });
    });
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_done) return;
    final pos = details.localPosition;
    if (_lastPos != null) {
      final dist = (pos - _lastPos!).distance;
      final once = (_progress * 10).floor();
      setState(() {
        _progress = (_progress + dist / _threshold).clamp(0.0, 1.0);
        _tail.add(_TailPoint(pos: pos, life: 1.0));
        if (_tail.length > 500) _tail.removeRange(0, _tail.length - 500);
      });
      // Her %10'da hafif tık: sürtmenin "işlediği" hissedilsin (2026-11-06).
      if ((_progress * 10).floor() > once && _progress < 1.0) HapticFeedback.selectionClick();
      if (_progress >= 1.0 && !_done) {
        _done = true;
        _burstOrigin = pos;
        _burstStart = DateTime.now();
        // %100: güçlü vuruş + yankı.
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 140), HapticFeedback.mediumImpact);
        // 3 saniye sonra geçiş (eski 5 sn ölü bekleme kısaldı)
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.pushReplacement('/kahin_metin', extra: widget.kahinId);
        });
      }
    }
    _lastPos = pos;
  }

  void _onPanEnd(DragEndDetails _) {
    _lastPos = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: Column(
          children: [
            // ── Başlık ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.kahinId.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // ── Yazı ────────────────────────────────────────────
            Consumer(builder: (ctx, ref, _) {
              final s = ref.watch(l10nProvider);
              return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _done ? s.done : s.touchFinger,
                key: ValueKey(_done),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _done ? const Color(0xFFFF55FF) : Colors.white60,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            );
            }),

            const SizedBox(height: 18),

            // ── İkon: parmak izi veya kum saati ─────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _done
                  ? const ElegantHourglass(
                      key: ValueKey('hourglass'),
                      size: 36,
                      color: Color(0xFFFF55FF),
                    )
                  : const Icon(
                      Icons.fingerprint,
                      key: ValueKey('fingerprint'),
                      color: Color(0xFFFF55FF),
                      size: 36,
                    ),
            ),

            const SizedBox(height: 18),

            // ── Etkileşim kutusu ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: NoEdgeSwipeBack(child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF55FF).withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                    color: const Color(0xFFFF55FF).withValues(alpha: 0.03),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      painter: _TailPainter(_tail),
                      foregroundPainter: _burstOrigin == null
                          ? null
                          : _BurstPainter(_burstOrigin!, _burstAge),
                      size: Size.infinite,
                    ),
                  ),
                ),
              )),
            ),

            const SizedBox(height: 16),

            // ── Yüzde ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF55FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFFFF55FF),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const FloatingBarSpacer(),
          ],
        ),
      ),
    );
  }
}

// ── Veri ─────────────────────────────────────────────────────────────────────

class _TailPoint {
  final Offset pos;
  double life;
  _TailPoint({required this.pos, required this.life});
}

// ── %100 patlaması ───────────────────────────────────────────────────────────

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.origin, this.age);
  final Offset origin;
  final double age; // sn

  @override
  void paint(Canvas canvas, Size size) {
    if (age < 0 || age > 0.9) return;
    final rnd = Random(3);
    final u = age / 0.9;
    // Halka dalgası
    canvas.drawCircle(
      origin,
      20 + 160 * Curves.easeOutCubic.transform(u),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - u)
        ..color = const Color(0xFFFF55FF).withValues(alpha: 0.7 * (1 - u)),
    );
    for (var i = 0; i < 24; i++) {
      final a = rnd.nextDouble() * 2 * pi;
      final sp = 120 + rnd.nextDouble() * 220;
      final d = sp * age - 60 * age * age;
      final p = origin + Offset(cos(a), sin(a)) * d;
      final r = (2 + rnd.nextDouble() * 3.5) * (1 - u * 0.7);
      final c = i.isEven ? const Color(0xFFFF55FF) : const Color(0xFF00CCFF);
      canvas.drawCircle(p, r * 2.2,
          Paint()
            ..color = c.withValues(alpha: 0.35 * (1 - u))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(p, r, Paint()..color = Colors.white.withValues(alpha: 0.9 * (1 - u)));
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.age != age || old.origin != origin;
}

// ── Kuyruk painter ───────────────────────────────────────────────────────────

class _TailPainter extends CustomPainter {
  final List<_TailPoint> tail;
  _TailPainter(this.tail);

  @override
  void paint(Canvas canvas, Size size) {
    if (tail.length < 2) return;

    for (int i = 1; i < tail.length; i++) {
      final a = tail[i - 1];
      final b = tail[i];
      final t = (a.life + b.life) / 2;

      // Dış parıltı
      canvas.drawLine(
        a.pos, b.pos,
        Paint()
          ..color = const Color(0xFFFF55FF).withValues(alpha: t * 0.20)
          ..strokeWidth = t * 20
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Orta halka
      canvas.drawLine(
        a.pos, b.pos,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFCC00CC),
            const Color(0xFFFFAAFF),
            t,
          )!.withValues(alpha: t * 0.60)
          ..strokeWidth = t * 7
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );

      // Parlak çekirdek
      canvas.drawLine(
        a.pos, b.pos,
        Paint()
          ..color = Colors.white.withValues(alpha: t * 0.85)
          ..strokeWidth = t * 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_TailPainter old) => true;
}
