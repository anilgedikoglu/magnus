// lib/core/widgets/glass_tab_bar.dart
//
// iOS 26 "Liquid Glass" tarzı koyu gri cam alt bar (WhatsApp/Instagram örneği):
//   • Tek cam kapsül, 3 eşit slot: Kullanıcı Bilgileri (bilgisayar) · Ana Menü (ev) · Gelen Kutusu (zarf).
//   • Cam: TEK blur + doygunluk (yalnız arka plan zincirinde; ikonlar etkilenmez)
//     + koyu gri tint + gradyan kenar ışığı (specular rim) + üst parlama + dış gölge.
//   • Seçili sekmenin arkasındaki açık "mini kapsül" yay (spring) fiziğiyle kayar,
//     hızına göre en fazla %10 uzar / %3 incelir ("liquid" his), sonra oturur.
// Tasarım Codex ile (2026-11-04). Apple'ın gerçek lens/kırılma shader'ı birebir
// taklit edilmez (Skia'da ImageFilter.shader yok; risk) — blur+tint+rim+kapsül.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Barın yüksekliği ve SafeArea altından boşluğu — 3 ekranda AYNI yer.
const double kGlassBarHeight = 56;
const double kGlassBarGap = 10;
const double kGlassBarSide = 12;

/// Bar + boşluk: içerik bu kadar alttan pay bırakmalı (SafeArea içinde).
const double kGlassBarReserve = kGlassBarHeight + kGlassBarGap;

class GlassTabBar extends StatefulWidget {
  /// 0 = Kullanıcı Bilgileri, 1 = Ana Menü, 2 = Gelen Kutusu.
  final int selected;
  final ValueChanged<int> onTap;

  /// Hazır + okunmamış fal var → zarfta küçük sıcak nokta.
  final bool hasUnread;

  /// Hazırlanan fal kalmadı + okunmamış var → zarfın çevresinde yeşil halka.
  final bool greenRing;

  /// Erişilebilirlik etiketleri (TR/EN), slot sırasıyla.
  final List<String> labels;

  const GlassTabBar({
    super.key,
    required this.selected,
    required this.onTap,
    required this.labels,
    this.hasUnread = false,
    this.greenRing = false,
  }) : assert(labels.length == 3);

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar>
    with SingleTickerProviderStateMixin {
  // Konum indeks uzayında (0..2). Codex önerisi: kütle 1, sertlik 420, sönüm 36
  // → sönüm oranı ~0.88: hafif esnek, çabuk oturur.
  static const _spring = SpringDescription(mass: 1, stiffness: 420, damping: 36);

  late final AnimationController _pos =
      AnimationController.unbounded(vsync: this, value: widget.selected.toDouble());
  int? _pressed;

  @override
  void didUpdateWidget(covariant GlassTabBar old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _moveTo(widget.selected);
  }

  void _moveTo(int index) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _pos.value = index.toDouble();
      return;
    }
    // Mevcut hızdan devam → hızlı art arda dokunuşta kopma/sıçrama olmaz.
    _pos.animateWith(
        SpringSimulation(_spring, _pos.value, index.toDouble(), _pos.velocity));
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  // Doygunluk 1.25 (Rec.709 ağırlıkları) — arka planın renklerini cam içinde canlı tutar.
  static const ColorFilter _saturate = ColorFilter.matrix(<double>[
    1.19685, -0.17880, -0.01805, 0, 0, //
    -0.05315, 1.07120, -0.01805, 0, 0, //
    -0.05315, -0.17880, 1.23195, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
  static final ui.ImageFilter _glass = ui.ImageFilter.compose(
    outer: _saturate,
    inner: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
  );

  @override
  Widget build(BuildContext context) {
    const radius = kGlassBarHeight / 2;
    return SizedBox(
      height: kGlassBarHeight,
      child: DecoratedBox(
        // Dış yumuşak gölge — cam "yüzüyor" hissi.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: LayoutBuilder(builder: (context, c) {
            const inset = 5.0;
            final slot = (c.maxWidth - 2 * inset) / 3;
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1) Cam: arka plan bulanıklaşır + doygunlaşır, üstüne koyu gri tint.
                BackdropFilter(
                  filter: _glass,
                  child: const ColoredBox(color: Color(0x8C1C1C1E)),
                ),
                // 2) Üst parlama (cam yüzeyinin ışığı yakalaması).
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.45],
                        colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
                // 3) Kayan seçim kapsülü — yalnız bu küçük parça her karede yeniden çizilir.
                AnimatedBuilder(
                  animation: _pos,
                  builder: (context, _) {
                    final x = _pos.value.clamp(-0.15, 2.15);
                    final stretch = (_pos.velocity.abs() / 8).clamp(0.0, 1.0);
                    final w = slot * (1 + 0.10 * stretch);
                    final h = (kGlassBarHeight - 2 * inset) * (1 - 0.03 * stretch);
                    return Positioned(
                      left: inset + slot * x + (slot - w) / 2,
                      top: (kGlassBarHeight - h) / 2,
                      width: w,
                      height: h,
                      child: const IgnorePointer(
                          key: ValueKey('glassTabBarPill'), child: _SelectionPill()),
                    );
                  },
                ),
                // 4) Sekmeler.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: inset),
                  child: Row(children: List.generate(3, _slot)),
                ),
                // 5) Kenar ışığı (specular rim).
                const IgnorePointer(child: CustomPaint(painter: _RimPainter(radius))),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _slot(int i) {
    final selected = widget.selected == i;
    final Widget icon = switch (i) {
      0 => Image.asset('assets/images/bilgiekranilogo.png',
          width: 30, height: 30, filterQuality: FilterQuality.high),
      1 => CustomPaint(size: const Size(27, 27), painter: _HousePainter(filled: selected)),
      _ => _InboxIcon(hasUnread: widget.hasUnread, greenRing: widget.greenRing),
    };
    return Expanded(
      child: Semantics(
        label: widget.labels[i],
        selected: selected,
        button: true,
        inMutuallyExclusiveGroup: true,
        onTap: () => widget.onTap(i),
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = i),
          onTapCancel: () => setState(() => _pressed = null),
          onTapUp: (_) => setState(() => _pressed = null),
          onTap: () => widget.onTap(i),
          child: Center(
            child: AnimatedScale(
              scale: _pressed == i ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: ExcludeSemantics(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}

/// Açık gri cam mini kapsül (ikinci blur YOK — sadece yarı saydam dolgu + ince kenar).
class _SelectionPill extends StatelessWidget {
  const _SelectionPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kGlassBarHeight / 2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33FFFFFF), Color(0x1FFFFFFF)],
        ),
        border: Border.all(color: const Color(0x1FFFFFFF), width: 0.8),
      ),
    );
  }
}

/// Zarf + inbox durumu: okunmamış → sıcak nokta; greenRing → yeşil halka (nokta da yeşil).
class _InboxIcon extends StatelessWidget {
  final bool hasUnread;
  final bool greenRing;
  const _InboxIcon({required this.hasUnread, required this.greenRing});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF44FF88);
    const warm = Color(0xFFFFA62B);
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (greenRing)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: green.withValues(alpha: 0.85), width: 1.3), // ince (görsel doğrulama: 1.8 neon gibiydi)
                boxShadow: [
                  BoxShadow(color: green.withValues(alpha: 0.28), blurRadius: 8),
                ],
              ),
            ),
          Image.asset('assets/images/inbox_icon.png',
              width: 32, height: 32, filterQuality: FilterQuality.high),
          if (hasUnread)
            Positioned(
              top: 3,
              right: 2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: greenRing ? green : warm,
                  border: Border.all(color: const Color(0xFF1C1C1E), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                        color: (greenRing ? green : warm).withValues(alpha: 0.6),
                        blurRadius: 6),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cam kenarı: üstte parlak, altta sönük, en altta hafif "yakalanan ışık".
class _RimPainter extends CustomPainter {
  final double radius;
  const _RimPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.5, 1.0],
        colors: [Color(0x52FFFFFF), Color(0x0DFFFFFF), Color(0x1FFFFFFF)],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RimPainter old) => old.radius != radius;
}

/// WhatsApp/Instagram tarzı yuvarlak köşeli ev: pasif = çizgi, aktif = dolu.
/// Kapı boşluğu çizginin içinde (dolu hâlde kapı oyuk kalır).
class _HousePainter extends CustomPainter {
  final bool filled;
  const _HousePainter({required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Path()
      ..moveTo(4.6 * k, 19.0 * k)
      ..lineTo(4.6 * k, 10.6 * k)
      ..quadraticBezierTo(4.6 * k, 9.7 * k, 5.3 * k, 9.1 * k)
      ..lineTo(10.7 * k, 4.4 * k)
      ..quadraticBezierTo(12.0 * k, 3.3 * k, 13.3 * k, 4.4 * k)
      ..lineTo(18.7 * k, 9.1 * k)
      ..quadraticBezierTo(19.4 * k, 9.7 * k, 19.4 * k, 10.6 * k)
      ..lineTo(19.4 * k, 19.0 * k)
      ..quadraticBezierTo(19.4 * k, 20.4 * k, 18.0 * k, 20.4 * k)
      ..lineTo(14.6 * k, 20.4 * k)
      ..lineTo(14.6 * k, 15.6 * k)
      ..quadraticBezierTo(14.6 * k, 14.6 * k, 13.6 * k, 14.6 * k)
      ..lineTo(10.4 * k, 14.6 * k)
      ..quadraticBezierTo(9.4 * k, 14.6 * k, 9.4 * k, 15.6 * k)
      ..lineTo(9.4 * k, 20.4 * k)
      ..lineTo(6.0 * k, 20.4 * k)
      ..quadraticBezierTo(4.6 * k, 20.4 * k, 4.6 * k, 19.0 * k)
      ..close();
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * k
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (filled) {
      canvas.drawPath(p, Paint()..color = Colors.white);
    }
    canvas.drawPath(p, stroke);
  }

  @override
  bool shouldRepaint(covariant _HousePainter old) => old.filled != filled;
}
