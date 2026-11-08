// lib/core/widgets/glass_theme.dart
//
// Liquid Glass teması (Anıl, 2026-11-08): Ayarlar > CAM'dan Flat / Candy. Tema gibi çalışır:
// alt bar, sohbet kutusu ve her LiquidGlassPanel seçimi buradan okur, saydamlık kaydırıcısı
// iki temayı da etkiler. Yeni bir LG yüzeyi eklenirse otomatik uyar.

import 'package:flutter/widgets.dart';

enum GlassStyle { flat, candy }

/// Candy optiği: arkası daha doygun ve yumuşak (disk bulanıklığı, mantıksal px).
const double kCandySaturation = 1.8;
const double kCandyDiskBlur = 7;

class GlassTheme extends InheritedWidget {
  const GlassTheme({super.key, required this.style, required super.child});

  final GlassStyle style;

  /// Sağlayıcı yoksa (testler, önizleme) Flat.
  static GlassStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassTheme>()?.style ?? GlassStyle.flat;

  static bool isCandy(BuildContext context) => of(context) == GlassStyle.candy;

  @override
  bool updateShouldNotify(GlassTheme oldWidget) => oldWidget.style != style;
}

/// Candy camın dış gölgesi: solda mavi, sağda pembe hale.
const List<BoxShadow> kCandyShadows = [
  BoxShadow(color: Color(0x1A5AA2FF), blurRadius: 24, offset: Offset(-4, 2)),
  BoxShadow(color: Color(0x1AFF55C8), blurRadius: 24, offset: Offset(4, 3)),
];

/// Candy kenar: yanardöner mavi → mor → pembe ışık, içe doğru hafif yayılır.
class CandyRimPainter extends CustomPainter {
  const CandyRimPainter(this.radius, {this.opacity = 1, this.glow = 4});

  final double radius;
  final double opacity;

  /// İçe yayılan ışığın kalınlığı (seçim kapsülünde daha ince).
  final double glow;

  static const List<Color> _colors = [
    Color(0xFFD9F1FF),
    Color(0xFF74AEFF),
    Color(0xFF8C9CFF),
    Color(0xFFC07CFF),
    Color(0xFFFF5FC4),
  ];
  static const List<double> _stops = [0.0, 0.28, 0.55, 0.78, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.8), Radius.circular(radius));
    final gradient = const LinearGradient(
      begin: Alignment(-1, -0.5),
      end: Alignment(1, 0.5),
      colors: _colors,
      stops: _stops,
    ).createShader(rect);

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow
        ..shader = gradient
        ..color = Color.fromRGBO(255, 255, 255, 0.38 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow * 0.7),
    );
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = gradient
        ..color = Color.fromRGBO(255, 255, 255, 0.9 * opacity),
    );
    // Üst kenarda ince beyaz parlama.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4],
          colors: [Color.fromRGBO(255, 255, 255, 0.8 * opacity), const Color(0x00FFFFFF)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CandyRimPainter old) =>
      old.radius != radius || old.opacity != opacity || old.glow != glow;
}
