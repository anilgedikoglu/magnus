// lib/core/widgets/grimoire_backdrop.dart
//
// "Gece Grimuarı" ortak ekran zemini (2026-11). Düz siyah ekranlar yerine okuma odası
// atmosferi: mürekkep zemin + üstten çok hafif mum ışığı + soğuk gümüş dip ışığı +
// kenar vinyeti + STATİK film greni. İsteğe bağlı arka plan görseli filmlenerek
// (doygunluk/parlaklık bastırılmış) en alta konur.
//
// Kullanım (full-screen şablonunun yerine):
//   Scaffold(backgroundColor: AppColors.ink, extendBody: true,
//     body: GrimoireBackdrop(asset: 'assets/images/xxx_bg.jpg', child: SafeArea(...)))
//
// Kurallar: hareket YOK (grain statik; mum titremesi ekranda en fazla 1 öğe kuralı —
// o öğe bu zemin değildir). Grain bir kez çizilir (RepaintBoundary + saf painter).

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class GrimoireBackdrop extends StatelessWidget {
  final Widget child;

  /// İsteğe bağlı arka plan görseli (filmlenir). null → yalnız mürekkep zemin.
  final String? asset;

  /// Görsel filmi: doygunluk / parlaklık. Varsayılan okuma ekranı için koyu.
  final double imageSaturation;
  final double imageBrightness;
  final Alignment imageAlignment;

  /// Üstten mum ışığının gücü (0 = yok).
  final double candle;

  /// Kenar vinyeti (0 = yok).
  final double vignette;

  /// Film greni (0 = yok).
  final double grain;

  const GrimoireBackdrop({
    super.key,
    required this.child,
    this.asset,
    this.imageSaturation = 1.0,
    this.imageBrightness = 1.0,
    this.imageAlignment = Alignment.center,
    this.candle = 0,
    this.vignette = 0,
    this.grain = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.ink),
        // 2026-11-05 eski renkler: görsel filmsiz, üstünde eski "Full-Screen" karartması
        // (üst/alt %60, orta %27). imageSaturation/imageBrightness artık yok sayılır.
        if (asset != null) ...[
          Image.asset(
            asset!,
            fit: BoxFit.cover,
            alignment: imageAlignment,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x44000000), Color(0x99000000)],
                ),
              ),
            ),
          ),
        ],
        if (candle > 0 || vignette > 0 || grain > 0)
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _AtmospherePainter(
                candle: candle,
                vignette: vignette,
                grain: grain,
                hasImage: asset != null,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final double candle;
  final double vignette;
  final double grain;
  final bool hasImage;

  const _AtmospherePainter({
    required this.candle,
    required this.vignette,
    required this.grain,
    required this.hasImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shortest = size.shortestSide;
    // Vinyet dairesi (r×1.6) kutunun çok dışına taşar: kırpılmazsa sekme/rota geçişinde
    // sayfanın ÖNÜNDE yarı saydam koyu bir perde gibi kayar (Anıl, 2026-11-05 cihazda gördü).
    canvas.clipRect(rect);

    // 1) Mum ışığı — üst ortadan, sıcak altın, çok hafif.
    if (candle > 0) {
      final c = Offset(size.width * 0.5, -shortest * 0.10);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0.075 * candle),
              AppColors.gold.withValues(alpha: 0.020 * candle),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: shortest * 1.05)),
      );
      // Soğuk gümüş dip ışığı — sol alttan, daha da hafif (ay ışığı).
      final m = Offset(size.width * 0.10, size.height * 1.02);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.silver.withValues(alpha: 0.045 * candle),
              const Color(0x00000000),
            ],
          ).createShader(Rect.fromCircle(center: m, radius: shortest * 0.9)),
      );
    }

    // 2) Vinyet — eliptik, ekran oranına uyar.
    if (vignette > 0) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(1.0, size.height / size.width);
      final r = size.width * 0.80;
      canvas.drawCircle(
        Offset.zero,
        r * 1.6,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0x00000000),
              Colors.black.withValues(alpha: (hasImage ? 0.55 : 0.45) * vignette),
            ],
            stops: const [0.62, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
      );
      canvas.restore();
    }

    // 3) Statik film greni — seed'li, deterministik (her açılışta aynı desen).
    // İki drawRawPoints çağrısı (açık + koyu tane) — binlerce drawRect yerine tek geçiş.
    if (grain > 0) {
      final rnd = math.Random(7);
      // n NOKTA → 2n koordinat (x,y). (Tek uzunluklu dizi RangeError veriyordu.)
      final n = (size.width * size.height / 280).clamp(400, 4500).toInt();
      final light = Float32List(n * 2);
      final dark = Float32List(n * 2);
      for (var i = 0; i < n * 2; i += 2) {
        light[i] = rnd.nextDouble() * size.width;
        light[i + 1] = rnd.nextDouble() * size.height;
        dark[i] = rnd.nextDouble() * size.width;
        dark[i + 1] = rnd.nextDouble() * size.height;
      }
      canvas.drawRawPoints(
        PointMode.points,
        light,
        Paint()
          ..color = AppColors.bone.withValues(alpha: 0.040 * grain)
          ..strokeWidth = 1.1,
      );
      canvas.drawRawPoints(
        PointMode.points,
        dark,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12 * grain)
          ..strokeWidth = 1.3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.candle != candle ||
      old.vignette != vignette ||
      old.grain != grain ||
      old.hasImage != hasImage;
}
