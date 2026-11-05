// lib/core/widgets/result_reveal.dart
//
// Ortak "sonuç açılışı" (2026-11-06, Grok + Codex danışması: sonuç metni bir anda tamamı
// görünüyordu). İçerik hafifçe büyüyerek belirir, sonra yukarıdan aşağı mürekkep gibi açılır
// (yumuşak kenarlı süpürme, ~1100 px/sn). Açılışta orta titreşim. Dokununca hemen tamamlanır
// (okumak isteyen beklemez). Reduced-motion: doğrudan son hâl.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResultReveal extends StatefulWidget {
  const ResultReveal({super.key, required this.child, this.haptic = true});

  final Widget child;
  final bool haptic;

  /// Yalnız test: açılışı sabitle (0..1).
  @visibleForTesting
  static double? debugValue;

  @override
  State<ResultReveal> createState() => _ResultRevealState();
}

class _ResultRevealState extends State<ResultReveal> with SingleTickerProviderStateMixin {
  static const _pxPerSec = 1100.0;
  static const _edge = 140.0; // yumuşak kenar (px)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.value = 1;
      return;
    }
    if (widget.haptic) HapticFeedback.mediumImpact();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _skip() {
    if (_c.value < 1) _c.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _skip(),
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final v = ResultReveal.debugValue ?? _c.value;
          if (v >= 1) return child!;
          final secs = v * _c.duration!.inMilliseconds / 1000;
          final appear = Curves.easeOutCubic.transform((secs / 0.35).clamp(0.0, 1.0));
          return Opacity(
            opacity: appear,
            child: Transform.scale(
              scale: 0.97 + 0.03 * appear,
              alignment: Alignment.topCenter,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (b) {
                  final h = b.height <= 0 ? 1.0 : b.height;
                  final front = (secs * _pxPerSec + _edge * 0.5) / h;
                  final tail = (front - _edge / h).clamp(0.0, 1.0);
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Colors.white, Colors.white, Colors.transparent, Colors.transparent],
                    stops: [0, tail, front.clamp(0.0, 1.0), 1],
                  ).createShader(b);
                },
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
