import 'package:flutter/material.dart';

/// Soldan sağa swipe ile "geri/ana menü" dönüşü sağlar.
///
/// `Listener` (raw pointer) kullanır — jest arenasına girmez, bu yüzden
/// içindeki ScrollView / PageView / GestureDetector ile çakışmaz. Ana menüdeki
/// (home_screen) swipe mantığıyla aynı yaklaşım.
///
/// Kullanım:
/// ```dart
/// SwipeBack(
///   onSwipeBack: () => context.pop(), // veya context.go('/home')
///   child: Scaffold(...),
/// )
/// ```
class SwipeBack extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeBack;

  /// Tetikleme için gereken minimum yatay (sağ yön) hareket — px.
  final double threshold;

  const SwipeBack({
    super.key,
    required this.child,
    required this.onSwipeBack,
    this.threshold = 60,
  });

  @override
  State<SwipeBack> createState() => _SwipeBackState();
}

class _SwipeBackState extends State<SwipeBack> {
  double? _startX;
  double? _startY;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _startX = e.position.dx;
        _startY = e.position.dy;
      },
      onPointerUp: (e) {
        final sx = _startX;
        final sy = _startY;
        _startX = null;
        _startY = null;
        if (sx == null || sy == null) return;
        final dx = e.position.dx - sx;
        final dy = e.position.dy - sy;
        // Soldan sağa, yatay baskın hareket (dikey kaydırmayı yanlış tetiklememek için)
        if (dx > widget.threshold && dx.abs() > dy.abs() * 1.5) {
          widget.onSwipeBack();
        }
      },
      onPointerCancel: (_) {
        _startX = null;
        _startY = null;
      },
      child: widget.child,
    );
  }
}
