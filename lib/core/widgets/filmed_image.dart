// lib/core/widgets/filmed_image.dart
//
// Renkli AI görsellerine "film": doygunluk + parlaklık bastırılır, çok hafif soğuk ton,
// kenar vinyeti. Görsel tamamen griye dönmez (kartlar tanınmaya devam eder) — Anıl:
// "menü ikonlarının üzerine bir film örtersin gri gibi". Basılınca renk hafifçe sızar.
// Matris YALNIZ görsele uygulanır; metin/durum ikonlarına uygulanmaz.
// Değerler: aşağıdaki sabitler (Codex + sanat yönetmeni sentezi, 2026-11).
// Sepya KULLANILMAZ (orman/yüz/uzay görsellerini aynı kahverengiye boğar).

import 'package:flutter/material.dart';

class FilmedImage extends StatelessWidget {
  final String asset;
  final BoxFit fit;

  /// Basılı / odakta: renk biraz geri gelir.
  final bool active;

  /// Kenar vinyeti gücü (0 = yok).
  final double vignette;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const FilmedImage(
    this.asset, {
    super.key,
    this.fit = BoxFit.cover,
    this.active = false,
    this.vignette = 0.32,
    this.errorBuilder,
  });

  // Sentez (2026-11): sanat yönetmeni doygunluk %20, parlaklık ×0.80, kontrast ×1.10,
  // soğuk gümüş ton; Codex basılı 0.35 / sanat yön. 0.55 → 0.45 / 0.90. Tam renk HİÇ gelmez.
  static const double restSaturation = 0.20;
  static const double restBrightness = 0.80;
  static const double activeSaturation = 0.45;
  static const double activeBrightness = 0.90;
  static const double contrast = 1.10;

  /// Rec.709 doygunluk × parlaklık × kontrast (128 pivot) × soğuk gümüş ton
  /// (R×0.97, G×0.99, B×1.05). Ofsetler 0-255 ölçeğinde.
  static List<double> matrix(double s, double b, {double c = contrast}) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    const tint = [0.97, 0.99, 1.05];
    final k = 1 - s;
    final off = 128 * (1 - c);
    List<double> row(int ch, double a0, double a1, double a2) {
      final m = tint[ch] * b * c;
      return [m * a0, m * a1, m * a2, 0, off * tint[ch]];
    }

    return <double>[
      ...row(0, k * lr + s, k * lg, k * lb),
      ...row(1, k * lr, k * lg + s, k * lb),
      ...row(2, k * lr, k * lg, k * lb + s),
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: active ? 1 : 0),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        final s = restSaturation + (activeSaturation - restSaturation) * t;
        final b = restBrightness + (activeBrightness - restBrightness) * t;
        return ColorFiltered(colorFilter: ColorFilter.matrix(matrix(s, b)), child: child);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: fit,
            filterQuality: FilterQuality.high,
            errorBuilder: errorBuilder ??
                (_, __, ___) => const ColoredBox(color: Color(0xFF171A20)),
          ),
          if (vignette > 0)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.95,
                    stops: const [0.55, 1.0],
                    colors: [
                      const Color(0x00000000),
                      Colors.black.withValues(alpha: vignette),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
