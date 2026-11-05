import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Son tetiklenen dokunuş — global kenar jesti (EdgeSwipeBack) aynı dokunuşta ikinci kez
  /// geri yapmasın diye. İç Listener hit-test sırasında önce çalışır.
  static int? _claimedPointer;

  /// Bu dokunuşu bir ekranın kendi SwipeBack'i işledi mi?
  static bool wasClaimed(int pointer) => _claimedPointer == pointer;

  @override
  State<SwipeBack> createState() => _SwipeBackState();
}

class _SwipeBackState extends State<SwipeBack> {
  final _down = <int>{};
  int? _pointer;
  double? _startX;
  double? _startY;

  void _clear() {
    _pointer = null;
    _startX = null;
    _startY = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _down.add(e.pointer);
        if (_down.length > 1) {
          _clear(); // çok parmak: geri değil
          return;
        }
        _pointer = e.pointer;
        _startX = e.position.dx;
        _startY = e.position.dy;
      },
      onPointerUp: (e) {
        _down.remove(e.pointer);
        final sx = _startX;
        final sy = _startY;
        final mine = e.pointer == _pointer;
        _clear();
        if (!mine || sx == null || sy == null) return;
        final dx = e.position.dx - sx;
        final dy = e.position.dy - sy;
        // Soldan sağa, yatay baskın hareket (dikey kaydırmayı yanlış tetiklememek için)
        if (dx > widget.threshold && dx.abs() > dy.abs() * 1.5) {
          SwipeBack._claimedPointer = e.pointer; // önce sahiplen, sonra aksiyon
          HapticFeedback.heavyImpact(); // her kaydırma hareketinde güçlü titreşim (Anıl)
          widget.onSwipeBack();
        }
      },
      onPointerCancel: (e) {
        _down.remove(e.pointer);
        if (e.pointer == _pointer) _clear();
      },
      child: widget.child,
    );
  }
}
