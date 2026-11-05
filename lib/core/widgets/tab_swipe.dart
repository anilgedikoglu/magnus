// lib/core/widgets/tab_swipe.dart
//
// Ana sekmeler arasında yatay kaydırma (ana menü ↔ gelen kutusu ↔ kullanıcı bilgileri).
//
// Raw `Listener` → jest arenasına girmez; GridView/ScrollView kaydırmasıyla yarışmaz.
// Ama "yarışmaz" demek her hareketi dinler demek: dikey kaydırmanın sonunda parmak sola
// çekilince sekme değişmesin diye YÖN KİLİDİ var (Codex incelemesi, 2026-11-05):
//   • Yalnız İLK parmak izlenir; ikinci parmak inerse hareket iptal (çimdik/çok parmak).
//   • İlk belirgin harekette (> [_slop] px) yön kilitlenir: yatay sayılması için
//     |dx| > |dy| × 1.5. Dikey kilitlenen hareket bir daha sekme değiştiremez.
//   • Bırakınca yatay mesafe ≥ [threshold] ise ilgili geri çağrı.
//   • [enabled] false dönerse (ör. açık düzenleyicide metin seçimi) hiçbir şey yapılmaz.

import 'package:flutter/widgets.dart';

class TabSwipe extends StatefulWidget {
  const TabSwipe({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.enabled,
    this.threshold = 50,
  });

  final Widget child;

  /// Parmak sağdan sola (dx < 0).
  final VoidCallback? onSwipeLeft;

  /// Parmak soldan sağa (dx > 0).
  final VoidCallback? onSwipeRight;

  /// Her hareketin başında sorulur; false → hareket yok sayılır.
  final bool Function()? enabled;

  final double threshold;

  @override
  State<TabSwipe> createState() => _TabSwipeState();
}

enum _Axis { undecided, horizontal, vertical }

class _TabSwipeState extends State<TabSwipe> {
  static const double _slop = 12;

  int? _pointer;
  Offset? _start;
  _Axis _axis = _Axis.undecided;

  void _reset() {
    _pointer = null;
    _start = null;
    _axis = _Axis.undecided;
  }

  void _down(PointerDownEvent e) {
    if (_pointer != null) {
      // İkinci parmak: çok parmaklı hareket sekme değiştirmez.
      _axis = _Axis.vertical;
      return;
    }
    if (widget.enabled?.call() == false) return;
    _pointer = e.pointer;
    _start = e.position;
    _axis = _Axis.undecided;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer || _axis != _Axis.undecided) return;
    final d = e.position - _start!;
    if (d.distance < _slop) return;
    _axis = d.dx.abs() > d.dy.abs() * 1.5 ? _Axis.horizontal : _Axis.vertical;
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    final start = _start!;
    final axis = _axis;
    _reset();
    if (axis != _Axis.horizontal) return;
    final dx = e.position.dx - start.dx;
    if (dx <= -widget.threshold) {
      widget.onSwipeLeft?.call();
    } else if (dx >= widget.threshold) {
      widget.onSwipeRight?.call();
    }
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) _reset();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: widget.child,
    );
  }
}
