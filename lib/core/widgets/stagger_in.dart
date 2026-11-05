// lib/core/widgets/stagger_in.dart
//
// Sırayla belirme (2026-11-06, Grok/Codex: astroloji/dert ortağı kartları hepsi birden
// düşüyordu). Öğe [index] × [step] gecikmeyle aşağıdan kayıp hafifçe büyüyerek gelir.
// Yalnız ekran açılışındaki ilk dalga canlanır: [since]'ten [window] sonra (ya da kaydırma
// ile sonradan kurulan öğelerde) animasyonsuz görünür. Reduced-motion: animasyonsuz.

import 'dart:async';

import 'package:flutter/material.dart';

class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.index,
    required this.since,
    required this.child,
    this.step = const Duration(milliseconds: 140),
    this.window = const Duration(milliseconds: 2400),
    this.maxAnimated = 8,
  });

  final int index;
  final DateTime since;
  final Widget child;
  final Duration step;
  final Duration window;
  final int maxAnimated;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.value > 0 || _timer != null) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final late = DateTime.now().difference(widget.since) > widget.window;
    if (reduce || late || widget.index >= widget.maxAnimated) {
      _c.value = 1;
      return;
    }
    final elapsed = DateTime.now().difference(widget.since);
    final delay = widget.step * widget.index - elapsed;
    if (delay <= Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_c.value);
        if (v >= 1) return child!;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - v)),
            child: Transform.scale(scale: 0.96 + 0.04 * v, child: child),
          ),
        );
      },
    );
  }
}
