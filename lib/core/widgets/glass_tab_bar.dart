// lib/core/widgets/glass_tab_bar.dart
//
// iOS 26 "Liquid Glass" tarzı koyu gri cam alt bar (WhatsApp/Instagram örneği):
//   • Tek cam kapsül, 3 eşit slot (Anıl, 2026-11-05): Ana Menü (ev) · Gelen Kutusu (zarf)
//     · Kullanıcı Bilgileri (insan büstü — profil simgesi).
//   • İkonlar tek renk beyaz ÇİZGİ glifler (vektör, her DPR'de keskin). Anıl: "fazla
//     beyazlı (dolu) modeller kaba, çizgili modelleri kullan" → aktif sekme dolu ikonla değil,
//     arkadaki kapsül + ikonun iOS seçili mavisi (#5FBBF9) ile gösterilir (2026-11-05).
//     Zarf glifi ChatGPT'ye çizdirildi (SVG, 24'lük ızgara, stroke 2.1); ev ve büst aynı dilde.
//   • Zarf rozeti: hazırlanan fal varsa TURUNCU, hepsi hazır + okunmamış varsa YEŞİL,
//     okunmamış yoksa nokta yok.
//   • Cam: TEK blur + doygunluk (yalnız arka plan zincirinde) + koyu gri tint +
//     gradyan kenar ışığı (specular rim) + üst parlama + dış gölge.
//   • Seçim kapsülü yay (spring) fiziğiyle kayar; giderken HAREKET YÖNÜNE doğru uzar
//     (sağa gidiyorsa sağ kenarı önden koşar), varınca geri kısalır — sıvı damla hissi.
//   • SIVI CAM KIRILMASI (2026-11-05, Anıl: "bizde buzlu cam gibi; onlarda iki cam arası
//     sıvı var gibi kırıyor ışığı"): Impeller'da `shaders/glass_lens.frag` — kenarlarda
//     içeriği büken mercek + hafif yönlü bulanıklık (Instagram'dan ölçüldü). Geçirgenlik
//     (tint %55 + doygunluk 1.25) AYNI. Impeller yoksa (Skia) eski buzlu cam (σ20).
//   • [minimize] 0 → tam boy, 1 → küçük (0.837): kaydırmayla küçülme (bkz. bar_minimize.dart).
// Tasarım Codex ile (2026-11-04/05).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import 'bar_minimize.dart';

/// Barın yüksekliği ve SafeArea altından boşluğu — 3 ekranda AYNI yer.
const double kGlassBarHeight = 56;
const double kGlassBarGap = 10;
const double kGlassBarSide = 12;

/// Bar + boşluk: içerik bu kadar alttan pay bırakmalı (SafeArea içinde).
const double kGlassBarReserve = kGlassBarHeight + kGlassBarGap;

/// Slot sayısı: Ev · Zarf · Profil.
const int kGlassBarSlots = 3;

/// Seçili sekmenin ikon rengi (Anıl, 2026-11-05: iOS Fotoğraflar'daki seçili "Koleksiyonlar"
/// mavisi, örnek görselden ölçüldü rgb 95,187,249). Kapsül hangi slota kayarsa o ikon bu
/// renge döner; geçiş kapsülün yayıyla eş zamanlı (yaklaştıkça maviye boyanır).
const Color kGlassBarSelectedColor = Color(0xFF5FBBF9);

/// Zarfın sağ üst rozeti.
enum InboxBadge {
  /// Okunmamış fal yok → nokta yok.
  none,

  /// En az bir fal hâlâ hazırlanıyor → turuncu nokta.
  preparing,

  /// Hazırlanan kalmadı, okunmamış hazır fal var → yeşil nokta.
  ready,
}

/// Kapsül uzaması: hız (slot/sn) × bu katsayı, en fazla [_kMaxStretch] slot.
/// 1 slotluk geçişte tepe ~0.25 slot, 2 slotlukta 0.32 (sınır) — "azıcık uzayıp kısalır".
const double _kStretchPerVelocity = 0.03;
const double _kMaxStretch = 0.32;

class GlassTabBar extends StatefulWidget {
  /// 0 = Ana Menü, 1 = Gelen Kutusu, 2 = Kullanıcı Bilgileri.
  final int selected;
  final ValueChanged<int> onTap;

  /// Zarftaki nokta durumu.
  final InboxBadge badge;

  /// Erişilebilirlik etiketleri (TR/EN), slot sırasıyla (3 adet).
  final List<String> labels;

  /// Küçülme ilerlemesi: 0 = tam boy, 1 = küçük ([kBarCompactScale]). Yayda 1'i biraz
  /// aşabilir (taşma). null → hep tam boy.
  final Animation<double>? minimize;

  const GlassTabBar({
    super.key,
    required this.selected,
    required this.onTap,
    required this.labels,
    this.badge = InboxBadge.none,
    this.minimize,
  }) : assert(labels.length == kGlassBarSlots);

  /// Kırılma shader'ını önceden yükle (main'de çağrılır; ilk karede buzlu cam görünmesin).
  static Future<ui.FragmentProgram?> preloadLens() => _lensProgram();

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

const String _kLensAsset = 'shaders/glass_lens.frag';
Future<ui.FragmentProgram?>? _lensLoad;
ui.FragmentProgram? _lensLoaded;

/// Yalnız görsel karşılaştırma: true → kırılma kapalı, eski buzlu cam.
@visibleForTesting
bool debugDisableGlassLens = false;

/// Yalnız Impeller'da (ImageFilter.shader) yüklenir; hata/destek yok → null (buzlu cam).
Future<ui.FragmentProgram?> _lensProgram() {
  if (!ui.ImageFilter.isShaderFilterSupported) return Future.value();
  return _lensLoad ??= ui.FragmentProgram.fromAsset(_kLensAsset).then<ui.FragmentProgram?>(
    (p) => _lensLoaded = p,
    onError: (Object _) => null,
  );
}

class _GlassTabBarState extends State<GlassTabBar>
    with SingleTickerProviderStateMixin {
  // Konum indeks uzayında (0..2). Codex önerisi: kütle 1, sertlik 420, sönüm 36
  // → sönüm oranı ~0.88: hafif esnek, çabuk oturur (~280 ms).
  static const _spring = SpringDescription(mass: 1, stiffness: 420, damping: 36);

  late final AnimationController _pos =
      AnimationController.unbounded(vsync: this, value: widget.selected.toDouble());
  int? _pressed;
  ui.FragmentProgram? _lens = _lensLoaded;

  @override
  void initState() {
    super.initState();
    if (_lens == null) {
      _lensProgram().then((p) {
        if (mounted && p != null) setState(() => _lens = p);
      });
    }
  }

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
    final bar = _buildBar();
    final m = widget.minimize;
    if (m == null) return bar;
    // Merkezden ölçek (ölçüm: küçülürken barın merkezi sabit). Transform dokunuşu da
    // ölçekler → küçük barda ikonlar doğru yerde çalışır; dışı alttaki sayfaya geçer.
    return AnimatedBuilder(
      animation: m,
      child: bar,
      builder: (context, child) => Transform.scale(
        key: const ValueKey('glassTabBarScale'),
        scale: 1 - (1 - kBarCompactScale) * m.value,
        child: child,
      ),
    );
  }

  Widget _buildBar() {
    const radius = kGlassBarHeight / 2;
    final lens = debugDisableGlassLens ? null : _lens;
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
            final slot = (c.maxWidth - 2 * inset) / kGlassBarSlots;
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1) Cam: Impeller'da sıvı cam kırılması (shader), değilse buzlu cam;
                //    üstüne aynı koyu gri tint (geçirgenlik değişmedi).
                if (lens != null)
                  _LensBackdrop(
                    program: lens,
                    child: const ColoredBox(color: Color(0x8C1C1C1E)),
                  )
                else
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
                    final x = _pos.value.clamp(-0.15, kGlassBarSlots - 1 + 0.15);
                    final v = _pos.velocity;
                    // Hareket yönündeki kenar önden koşar: sağa gidiyorsa sağ kenar
                    // uzar, sola gidiyorsa sol kenar. Hız düştükçe (varınca) kısalır.
                    final s = (v.abs() * _kStretchPerVelocity).clamp(0.0, _kMaxStretch);
                    final leftEdge = x - (v < 0 ? s : 0.0);
                    final rightEdge = x + 1 + (v > 0 ? s : 0.0);
                    // Uzarken çok hafif incelir (yüzey gerilimi).
                    final h = (kGlassBarHeight - 2 * inset) * (1 - 0.05 * (s / _kMaxStretch));
                    return Positioned(
                      left: inset + slot * leftEdge,
                      top: (kGlassBarHeight - h) / 2,
                      width: slot * (rightEdge - leftEdge),
                      height: h,
                      child: const IgnorePointer(
                          key: ValueKey('glassTabBarPill'), child: _SelectionPill()),
                    );
                  },
                ),
                // 4) Sekmeler.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: inset),
                  child: Row(children: List.generate(kGlassBarSlots, _slot)),
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

  /// Slotun ikon rengi: kapsülün o slota yakınlığına göre beyaz → seçili mavisi.
  Color _iconColor(int i) {
    // Yay hedefe ~1e-3 yakınlıkta durur → uçlarda tam renge oturt.
    final t = (1 - (_pos.value - i).abs()).clamp(0.0, 1.0);
    if (t > 0.99) return kGlassBarSelectedColor;
    if (t < 0.01) return Colors.white;
    return Color.lerp(Colors.white, kGlassBarSelectedColor, t)!;
  }

  Widget _slot(int i) {
    final selected = widget.selected == i;
    final Widget icon = AnimatedBuilder(
      animation: _pos,
      builder: (context, _) {
        final c = _iconColor(i);
        return switch (i) {
          0 => CustomPaint(
              key: const ValueKey('glassTabBarIcon0'),
              size: const Size(27, 27),
              painter: _HousePainter(c)),
          1 => _InboxIcon(badge: widget.badge, color: c),
          _ => CustomPaint(
              key: const ValueKey('glassTabBarIcon2'),
              size: const Size(27, 27),
              painter: _PersonPainter(c)),
        };
      },
    );
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

/// Sıvı cam kırılması (Impeller): arka planı `glass_lens.frag` ile büker.
/// Shader barın GLOBAL fiziksel dikdörtgenini ister → her boyamada dönüşümden hesaplanır
/// (küçülme ölçeği dahil; Transform değişince bu nesne de yeniden boyanır).
class _LensBackdrop extends SingleChildRenderObjectWidget {
  const _LensBackdrop({required this.program, super.child});

  final ui.FragmentProgram program;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLensBackdrop(program, MediaQuery.devicePixelRatioOf(context));

  @override
  void updateRenderObject(BuildContext context, _RenderLensBackdrop renderObject) {
    renderObject
      ..program = program
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  }
}

class _RenderLensBackdrop extends RenderProxyBox {
  _RenderLensBackdrop(this._program, this._dpr);

  // Ölçülen model (bkz. shaders/glass_lens.frag başlığı). Doygunluk = bizim buzlu camla aynı.
  static const double _refract = 0.238;
  static const double _bevel = 0.234;
  static const double _blur = 0.028;
  static const double _saturation = 1.25;

  ui.FragmentProgram _program;
  ui.FragmentShader? _shader;
  double _dpr;

  set devicePixelRatio(double value) {
    if (value == _dpr) return;
    _dpr = value;
    markNeedsPaint();
  }

  set program(ui.FragmentProgram value) {
    if (identical(value, _program)) return;
    _program = value;
    _shader?.dispose();
    _shader = null;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    // getTransformTo(null) MANTIKSAL global verir (ölçüldü: DPR'yi içermiyor) →
    // shader'ın FlutterFragCoord'u fiziksel piksel olduğundan DPR ile çarp.
    final r = MatrixUtils.transformRect(getTransformTo(null), Offset.zero & size);
    final shader = _shader ??= _program.fragmentShader();
    shader
      ..setFloat(0, 0) // uSize: motor doldurur
      ..setFloat(1, 0)
      ..setFloat(2, r.left * _dpr)
      ..setFloat(3, r.top * _dpr)
      ..setFloat(4, r.width * _dpr)
      ..setFloat(5, r.height * _dpr)
      ..setFloat(6, _refract)
      ..setFloat(7, _bevel)
      ..setFloat(8, _blur)
      ..setFloat(9, _saturation);
    final l = layer ??= BackdropFilterLayer();
    l.filter = ui.ImageFilter.shader(shader);
    context.pushLayer(l, super.paint, offset);
  }

  @override
  void dispose() {
    _shader?.dispose();
    _shader = null;
    super.dispose();
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

/// Zarf + sağ üst rozet: hazırlanıyor → turuncu, hepsi hazır → yeşil, yoksa nokta yok.
class _InboxIcon extends StatelessWidget {
  final InboxBadge badge;
  final Color color;
  const _InboxIcon({required this.badge, required this.color});

  static const _green = Color(0xFF44FF88);
  static const _orange = Color(0xFFFFA62B);

  @override
  Widget build(BuildContext context) {
    final Color? dot = switch (badge) {
      InboxBadge.none => null,
      InboxBadge.preparing => _orange,
      InboxBadge.ready => _green,
    };
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
              key: const ValueKey('glassTabBarIcon1'),
              size: const Size(27, 27),
              painter: _EnvelopePainter(color)),
          if (dot != null)
            Positioned(
              top: 6,
              right: 4,
              child: Container(
                key: const ValueKey('glassTabBarInboxDot'),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dot,
                  border: Border.all(color: const Color(0xFF1C1C1E), width: 1.4),
                  boxShadow: [BoxShadow(color: dot.withValues(alpha: 0.6), blurRadius: 6)],
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

/// Ortak glif çizgisi: 24'lük ızgarada 2.1 birim, yuvarlak uç/birleşim.
Paint _glyphStroke(double k, Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2.1 * k
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// Zarf — ChatGPT SVG'si (viewBox 24) birebir: yuvarlak gövde + V kapak.
class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final body = Path()
      ..moveTo(4.5 * k, 5 * k)
      ..lineTo(19.5 * k, 5 * k)
      ..quadraticBezierTo(21 * k, 5 * k, 21 * k, 6.5 * k)
      ..lineTo(21 * k, 17.5 * k)
      ..quadraticBezierTo(21 * k, 19 * k, 19.5 * k, 19 * k)
      ..lineTo(4.5 * k, 19 * k)
      ..quadraticBezierTo(3 * k, 19 * k, 3 * k, 17.5 * k)
      ..lineTo(3 * k, 6.5 * k)
      ..quadraticBezierTo(3 * k, 5 * k, 4.5 * k, 5 * k)
      ..close();
    final flap = Path()
      ..moveTo(4.5 * k, 7.5 * k)
      ..lineTo(11.35 * k, 12.6 * k)
      ..quadraticBezierTo(12 * k, 13.1 * k, 12.65 * k, 12.6 * k)
      ..lineTo(19.5 * k, 7.5 * k);
    final p = _glyphStroke(k, color);
    canvas.drawPath(body, p);
    canvas.drawPath(flap, p);
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter old) => old.color != color;
}

/// WhatsApp/Instagram tarzı yuvarlak köşeli ev (çizgi) + kemerli kapı.
class _HousePainter extends CustomPainter {
  const _HousePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final house = Path()
      ..moveTo(4.6 * k, 19.0 * k)
      ..lineTo(4.6 * k, 10.6 * k)
      ..quadraticBezierTo(4.6 * k, 9.7 * k, 5.3 * k, 9.1 * k)
      ..lineTo(10.7 * k, 4.4 * k)
      ..quadraticBezierTo(12.0 * k, 3.3 * k, 13.3 * k, 4.4 * k)
      ..lineTo(18.7 * k, 9.1 * k)
      ..quadraticBezierTo(19.4 * k, 9.7 * k, 19.4 * k, 10.6 * k)
      ..lineTo(19.4 * k, 19.0 * k)
      ..quadraticBezierTo(19.4 * k, 20.4 * k, 18.0 * k, 20.4 * k)
      ..lineTo(6.0 * k, 20.4 * k)
      ..quadraticBezierTo(4.6 * k, 20.4 * k, 4.6 * k, 19.0 * k)
      ..close();
    // Kapı: zemine oturan yuvarlak üstlü kemer (gövdenin optik ortası).
    final door = Path()
      ..moveTo(10.0 * k, 20.4 * k)
      ..lineTo(10.0 * k, 16.0 * k)
      ..quadraticBezierTo(10.0 * k, 14.3 * k, 12.0 * k, 14.3 * k)
      ..quadraticBezierTo(14.0 * k, 14.3 * k, 14.0 * k, 16.0 * k)
      ..lineTo(14.0 * k, 20.4 * k);
    final p = _glyphStroke(k, color);
    canvas.drawPath(house, p);
    canvas.drawPath(door, p);
  }

  @override
  bool shouldRepaint(covariant _HousePainter old) => old.color != color;
}

/// Profil simgesi: insan büstü (yuvarlak baş + omuzlar), çizgi.
class _PersonPainter extends CustomPainter {
  const _PersonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = _glyphStroke(k, color);
    // Baş.
    canvas.drawCircle(Offset(12.0 * k, 8.0 * k), 3.8 * k, p);
    // Omuzlar: yumuşak kubbe, altı düz ve köşeleri yuvarlak (ev/zarf ile aynı dil).
    final shoulders = Path()
      ..moveTo(4.6 * k, 19.2 * k)
      ..cubicTo(4.6 * k, 15.6 * k, 7.9 * k, 13.6 * k, 12.0 * k, 13.6 * k)
      ..cubicTo(16.1 * k, 13.6 * k, 19.4 * k, 15.6 * k, 19.4 * k, 19.2 * k)
      ..quadraticBezierTo(19.4 * k, 20.4 * k, 18.2 * k, 20.4 * k)
      ..lineTo(5.8 * k, 20.4 * k)
      ..quadraticBezierTo(4.6 * k, 20.4 * k, 4.6 * k, 19.2 * k)
      ..close();
    canvas.drawPath(shoulders, p);
  }

  @override
  bool shouldRepaint(covariant _PersonPainter old) => old.color != color;
}
