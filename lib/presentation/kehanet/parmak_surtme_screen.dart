// C:/src/magnus_app/lib/presentation/kehanet/parmak_surtme_screen.dart
// Parmak sürtme ekranı - kahin seçimi sonrası etkileşim

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers.dart';
import '../../core/widgets/elegant_hourglass.dart';

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

  @override
  void initState() {
    super.initState();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_tail.isEmpty || !mounted) return;
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
      setState(() {
        _progress = (_progress + dist / _threshold).clamp(0.0, 1.0);
        _tail.add(_TailPoint(pos: pos, life: 1.0));
        if (_tail.length > 500) _tail.removeRange(0, _tail.length - 500);
      });
      if (_progress >= 1.0 && !_done) {
        _done = true;
        // 5 saniye sonra geçiş
        Future.delayed(const Duration(seconds: 5), () {
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
              child: GestureDetector(
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
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
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

            const SizedBox(height: 28),
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
