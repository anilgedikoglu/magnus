import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "Parmağını dokun → geleceğe odaklan" basılı-tut düğmesi (Anıl, 2026-11-06; Aşk Uyumu'ndaki
/// basılı-tut gibi). Parmak basılı tutuldukça daire dolar; dolunca [onComplete] çağrılır.
/// Bırakılırsa (tamamlanmadan) geri boşalır. Azaltılmış harekette tek dokunuş tamamlar.
class HoldToReveal extends StatefulWidget {
  const HoldToReveal({
    super.key,
    required this.onComplete,
    this.color = const Color(0xFFCC66FF),
    this.icon = Icons.auto_awesome,
    this.radius = 54,
    this.duration = const Duration(milliseconds: 1500),
  });

  final VoidCallback onComplete;
  final Color color;
  final IconData icon;
  final double radius;
  final Duration duration;

  @override
  State<HoldToReveal> createState() => _HoldToRevealState();
}

class _HoldToRevealState extends State<HoldToReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        HapticFeedback.mediumImpact();
        widget.onComplete();
      }
    });
    _c.addListener(() {
      // basılı tutarken artan titreşim hissi (çeyreklerde)
      final v = _c.value;
      if (v > 0 && (v * 4).floor() != ((v - 0.01) * 4).floor()) {
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    if (_done) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _done = true;
      HapticFeedback.mediumImpact();
      widget.onComplete();
      return;
    }
    _c.forward();
  }

  void _up() {
    if (!_done) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.radius;
    return GestureDetector(
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return SizedBox(
            width: r * 2,
            height: r * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: r * 2,
                  height: r * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.25 + _c.value * 0.35),
                        blurRadius: 14 + _c.value * 18,
                        spreadRadius: _c.value * 2,
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: Size(r * 2, r * 2),
                  painter: _FillPainter(progress: _c.value, color: widget.color),
                ),
                Icon(widget.icon, color: Colors.white, size: r * 0.7),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FillPainter extends CustomPainter {
  _FillPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    // İçeriden dolan daire.
    canvas.drawCircle(
      c, maxR * progress,
      Paint()..color = color.withValues(alpha: 0.30),
    );
    // Dolum halkası (yay).
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: maxR - 2),
      -1.5708, // -90°
      6.2832 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FillPainter old) => old.progress != progress || old.color != color;
}
