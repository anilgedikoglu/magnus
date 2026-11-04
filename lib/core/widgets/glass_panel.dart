// lib/core/widgets/glass_panel.dart
//
// "Gece Grimuarı" tasarım sisteminin ortak cam yüzeyi (2026-11, Codex + sanat yönetmeni).
//   • Varsayılan SAHTE cam: koyu tint + gradyan kenar ışığı + üst parlama + gölge.
//     Gerçek blur (BackdropFilter) yalnız `blur: true` ile — bütçe: ekranda 0-1 bölge
//     (alt bar zaten bir tane). Her karta/balona/satıra blur KOYMA (Codex: performans).
//   • Seçili durum: ince eski altın kenar (renk tek başına anlam taşımasın diye
//     kullanıcı tarafında ikon/metin de değişmeli).
// Ekranlar kendi rim/gölge tarifini ÜRETMEZ; hep bunu kullanır.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum GlassVariant {
  /// Uzun okuma metni arkası — daha kapalı (okunurluk), radius 20.
  reading,

  /// Seçim kartı / menü kutusu / liste satırı — radius 16.
  selection,

  /// Sohbet balonu — radius 16.
  bubble,

  /// İkincil buton — radius 14.
  button,
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final GlassVariant variant;
  final bool selected;

  /// Gerçek arka plan bulanıklığı (pahalı). Varsayılan kapalı.
  final bool blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Gölge (yüzen his). Liste satırlarında kapatılabilir.
  final bool shadow;

  const GlassPanel({
    super.key,
    required this.child,
    this.variant = GlassVariant.selection,
    this.selected = false,
    this.blur = false,
    this.padding,
    this.borderRadius,
    this.shadow = true,
  });

  double get _radius => switch (variant) {
        GlassVariant.reading => 20,
        GlassVariant.selection => 16,
        GlassVariant.bubble => 16,
        GlassVariant.button => 14,
      };

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(_radius);
    final tint = variant == GlassVariant.reading
        ? AppColors.glassTintReading
        : (selected ? AppColors.glassTintSelected : AppColors.glassTint);

    Widget body = Stack(
      children: [
        if (blur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const SizedBox.expand(),
            ),
          ),
        Positioned.fill(child: ColoredBox(color: tint)),
        // Üst yüzey parlaması: cam ışığı yakalıyor.
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5],
                  colors: [Color(0x0AFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ),
        Padding(padding: padding ?? EdgeInsets.zero, child: child),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: GlassRimPainter(radius: r, selected: selected)),
          ),
        ),
      ],
    );

    body = ClipRRect(borderRadius: r, child: body);
    if (!shadow) return body;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [
          BoxShadow(color: Color(0x47000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: body,
    );
  }
}

/// Cam kenar ışığı: üst parlak (0.22), yanlar (0.10), alt sönük (0.06).
/// Seçiliyken eski altın. 0.8-1 px.
class GlassRimPainter extends CustomPainter {
  final BorderRadius radius;
  final bool selected;
  const GlassRimPainter({required this.radius, this.selected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final rrect = radius.toRRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.0 : 0.9;
    if (selected) {
      paint.color = AppColors.gold.withValues(alpha: 0.62);
    } else {
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.5, 1.0],
        colors: [Color(0x38FFFFFF), Color(0x1AFFFFFF), Color(0x0FFFFFFF)],
      ).createShader(rect);
    }
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GlassRimPainter old) =>
      old.radius != radius || old.selected != selected;
}
