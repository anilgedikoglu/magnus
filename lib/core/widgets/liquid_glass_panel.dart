// lib/core/widgets/liquid_glass_panel.dart
//
// "LG" paneli (Anıl, 2026-11-08: "ne zaman LG yap desem alttaki buton kompartmanı gibi anla, ama
// o kadar saydam olmasın"). Alt barın camıyla aynı tarif: kenar kırılması, koyu tint, iç parıltı,
// kenar ışığı. Tek fark tint daha kapalı. Impeller yoksa buzlu cama düşer.
// Bütçe: ekranda en çok bir panel (bar + panel = iki arka plan süzgeci).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'glass_lens.dart';
import 'glass_tab_bar.dart' show GlassBarRimPainter;
import 'glass_tint.dart';

/// Panel saydamlığı: alt barın kaydırıcı ölçeğinde (bar varsayılanı 0.55; büyüdükçe kapanır).
const double kLiquidGlassPanelTint = 0.66;

class LiquidGlassPanel extends StatefulWidget {
  const LiquidGlassPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 24,
    this.tint = kLiquidGlassPanelTint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double tint;

  @override
  State<LiquidGlassPanel> createState() => _LiquidGlassPanelState();
}

class _LiquidGlassPanelState extends State<LiquidGlassPanel> {
  // Alt barın ölçülerinin mutlak hâli (bar yüksekliği 56 pt): boy büyüse de pah aynı kalır.
  static const double _bevelPt = 13.1;
  static const double _refractPt = 13.3;
  static const double _blurPt = 2;

  ui.FragmentProgram? _lens = glassLensLoaded;

  @override
  void initState() {
    super.initState();
    if (_lens == null) {
      loadGlassLens().then((p) {
        if (mounted && p != null) setState(() => _lens = p);
      });
    }
  }

  Widget _glass() {
    final tint = ColoredBox(color: glassTintColor(widget.tint));
    final lens = debugDisableGlassLens ? null : _lens;
    if (lens == null) {
      return BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: tint);
    }
    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight <= 0 ? 1.0 : c.maxHeight;
      return GlassLensBackdrop(
        program: lens,
        cornerRadius: widget.radius,
        bevel: _bevelPt / h,
        refract: _refractPt / h,
        blur: _blurPt / h,
        child: tint,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Positioned.fill(child: _glass()),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.02, 0.98, 1.0],
                      colors: [Color(0x10FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x12FFFFFF)],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: widget.padding, child: widget.child),
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: GlassBarRimPainter(widget.radius))),
            ),
          ],
        ),
      ),
    );
  }
}
