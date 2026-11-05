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
//     (doygunluk 1.25). Impeller yoksa (Skia) eski buzlu cam (σ20).
//   • Saydamlık [tint] (Ayarlar'daki cam kaydırıcısı; iOS 26 "Şeffaf ↔ Renkli" ölçümü,
//     glass_tint.dart). Varsayılan orta. Seçili ikon iOS mavisi; seçimde kapsül damla gibi havalanır.
//   • [minimize] 0 → tam boy, 1 → küçük (0.837): kaydırmayla küçülme (bkz. bar_minimize.dart).
// Tasarım Codex ile (2026-11-04/05).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'bar_minimize.dart';
import 'glass_lens.dart';
import 'glass_tint.dart';

export 'glass_lens.dart' show debugDisableGlassLens;

/// Barın yüksekliği ve SafeArea altından boşluğu — 3 ekranda AYNI yer.
const double kGlassBarHeight = 56;
const double kGlassBarGap = 10;
const double kGlassBarSide = 12;

/// Barın ekranın ALT KENARINDAN uzaklığı (Anıl, 2026-11-05: "görseldeki ile dikeyde aynı
/// yer"). Instagram iOS 26 ölçümü (iPhone Pro Max, 3x): bar alt kenarı ekran altından 24 pt
/// → alt güvenli alanın (34) 10 pt İÇİNDE; küçük hâl aynı merkezde. Güvenli alan yoksa 12.
double glassBarBottom(double safeBottom) => safeBottom - 10 < 12 ? 12 : safeBottom - 10;

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


/// Seçimde kapsülün "havalanması" (iOS 26 Liquid Glass sekme seçimi): dokununca kapsül
/// camdan bir damla gibi BÜYÜYEREK bardan taşar, alttaki ikonları mercek gibi büyütür,
/// hedefe kayar, varınca yaylı (hafif ezilerek) bara geri oturur.
const double _kLiftHeight = 0.40; // tam havada yükseklik ×1.40 (46 → 64 dp; 56'lık bardan taşar)
const double _kLiftWidth = 0.08; // tam havada genişlik ×1.08
const double _kLandSquash = 0.6; // iniş taşmasında (L<0) yassılaşma: genişlik +0.6·|L|
const double _kLiftZoom = 0.22; // damla merceği büyütmesi (1.22×)
const Duration _kLiftUp = Duration(milliseconds: 130);

class GlassTabBar extends StatefulWidget {
  /// 0 = Ana Menü, 1 = Gelen Kutusu, 2 = Kullanıcı Bilgileri.
  /// null = SEÇİMSİZ (bar bir fal ekranının üstünde yüzüyor; Anıl 2026-11-05): kapsül yok,
  /// tüm ikonlar beyaz. Dokununca seçili faza geçiş: kapsül o slotta cam damla olarak
  /// belirip yaylı inişle bara oturur (iOS 26 Liquid Glass temsili).
  final int? selected;
  final ValueChanged<int> onTap;

  /// Zarftaki nokta durumu.
  final InboxBadge badge;

  /// Erişilebilirlik etiketleri (TR/EN), slot sırasıyla (3 adet).
  final List<String> labels;

  /// Küçülme ilerlemesi: 0 = tam boy, 1 = küçük ([kBarCompactScale]). Yayda 1'i biraz
  /// aşabilir (taşma). null → hep tam boy.
  final Animation<double>? minimize;

  /// Cam saydamlığı (Ayarlar kaydırıcısı): 0 şeffaf … 1 renkli; bkz. glass_tint.dart.
  final double tint;

  const GlassTabBar({
    super.key,
    required this.selected,
    required this.onTap,
    required this.labels,
    this.badge = InboxBadge.none,
    this.minimize,
    this.tint = kGlassTintDefault,
  }) : assert(labels.length == kGlassBarSlots);

  /// Kırılma shader'ını önceden yükle (main'de çağrılır; ilk karede buzlu cam görünmesin).
  static Future<ui.FragmentProgram?> preloadLens() => loadGlassLens();

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar>
    with TickerProviderStateMixin {
  // Konum indeks uzayında (0..2). Codex önerisi: kütle 1, sertlik 420, sönüm 36
  // → sönüm oranı ~0.88: hafif esnek, çabuk oturur (~280 ms).
  static const _spring = SpringDescription(mass: 1, stiffness: 420, damping: 36);

  late final AnimationController _pos =
      AnimationController.unbounded(vsync: this, value: (widget.selected ?? 0).toDouble());

  /// Kapsülün var olma oranı: 1 = seçili sekme var, 0 = seçimsiz (fal ekranında).
  late final AnimationController _presence = AnimationController.unbounded(
      vsync: this, value: widget.selected == null ? 0 : 1);

  /// Havalanma: 0 = bara oturmuş düz kapsül, 1 = tam havada damla (inişte biraz <0 = ezilme).
  late final AnimationController _lift = AnimationController.unbounded(vsync: this);
  static const _landSpring = SpringDescription(mass: 1, stiffness: 320, damping: 22);
  bool _airborne = false;
  int _target = 0;

  int? _pressed;
  ui.FragmentProgram? _lens = glassLensLoaded;

  @override
  void initState() {
    super.initState();
    _target = widget.selected ?? 0;
    _pos.addListener(_checkLanding);
    if (_lens == null) {
      loadGlassLens().then((p) {
        if (mounted && p != null) setState(() => _lens = p);
      });
    }
  }

  @override
  void didUpdateWidget(covariant GlassTabBar old) {
    super.didUpdateWidget(old);
    final n = widget.selected;
    if (old.selected == n) return;
    if (n == null) {
      _vanish();
    } else if (old.selected == null) {
      _appear(n);
    } else {
      _moveTo(n);
    }
  }

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Seçimsiz faza: kapsül hafifçe havalanıp solarak kaybolur.
  void _vanish() {
    _airborne = false;
    if (_reduce) {
      _presence.value = 0;
      _lift.value = 0;
      return;
    }
    _presence.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOutCubic);
    _lift.animateTo(0.6, duration: const Duration(milliseconds: 200), curve: Curves.easeOutCubic);
  }

  /// Seçimsizden seçiliye (Anıl: "seçisiz fazdan seçili faza geçiş için bir animasyon,
  /// liquid glass'ı temsilen"): kapsül dokunulan slotta HAVADA bir cam damla olarak belirir
  /// (alttaki ikonu büyütür), yaylı inişle hafif ezilerek bara oturur; ikon maviye döner.
  void _appear(int index) {
    _target = index;
    _airborne = false;
    _pos.value = index.toDouble();
    if (_reduce) {
      _presence.value = 1;
      _lift.value = 0;
      return;
    }
    _presence.animateTo(1, duration: const Duration(milliseconds: 150), curve: Curves.easeOutCubic);
    _lift.value = 1;
    _lift.animateWith(SpringSimulation(_landSpring, 1, 0, 0));
  }

  void _moveTo(int index) {
    _target = index;
    if (_reduce) {
      _airborne = false;
      _lift.value = 0;
      _pos.value = index.toDouble();
      return;
    }
    // Mevcut hızdan devam → hızlı art arda dokunuşta kopma/sıçrama olmaz.
    _pos.animateWith(
        SpringSimulation(_spring, _pos.value, index.toDouble(), _pos.velocity));
    // Havalan (iOS 26): damla büyüyerek kalkar; iniş _checkLanding'de.
    _airborne = true;
    _lift.animateTo(1, duration: _kLiftUp, curve: Curves.easeOutCubic);
  }

  /// Kapsül hedefe yaklaşınca (0.15 slot) damla yaylı bir inişle bara oturur.
  void _checkLanding() {
    if (!_airborne || (_pos.value - _target).abs() > 0.15) return;
    _airborne = false;
    _lift.animateWith(SpringSimulation(_landSpring, _lift.value, 0, _lift.velocity));
  }

  @override
  void dispose() {
    _pos.removeListener(_checkLanding);
    _pos.dispose();
    _lift.dispose();
    _presence.dispose();
    super.dispose();
  }

  /// Kapsülün dikdörtgeni (bar koordinatı): konum + yönlü esneme + havalanma ölçeği.
  Rect _pillRect(double slot, double inset) {
    final x = _pos.value.clamp(-0.15, kGlassBarSlots - 1 + 0.15);
    final v = _pos.velocity;
    // Hareket yönündeki kenar önden koşar: sağa gidiyorsa sağ kenar uzar, sola gidiyorsa
    // sol kenar. Hız düştükçe (varınca) kısalır.
    final s = (v.abs() * _kStretchPerVelocity).clamp(0.0, _kMaxStretch);
    final leftEdge = x - (v < 0 ? s : 0.0);
    final rightEdge = x + 1 + (v > 0 ? s : 0.0);
    // Uzarken çok hafif incelir (yüzey gerilimi).
    final baseH = (kGlassBarHeight - 2 * inset) * (1 - 0.05 * (s / _kMaxStretch));
    final l = _lift.value;
    // Belirirken/kaybolurken küçükten büyür (0.7 → 1).
    final pr = 0.7 + 0.3 * _presence.value.clamp(0.0, 1.0);
    final hf = (1 + _kLiftHeight * l) * pr;
    final wf = (1 + (l >= 0 ? _kLiftWidth * l : -_kLandSquash * l)) * pr;
    return Rect.fromCenter(
      center: Offset(inset + slot * (leftEdge + rightEdge) / 2, kGlassBarHeight / 2),
      width: slot * (rightEdge - leftEdge) * wf,
      height: baseH * hf,
    );
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
      child: LayoutBuilder(builder: (context, c) {
        const inset = 5.0;
        final slot = (c.maxWidth - 2 * inset) / kGlassBarSlots;
        return Stack(
          clipBehavior: Clip.none, // havalanan damla bardan taşar
          fit: StackFit.expand,
          children: [
            DecoratedBox(
        // Dış yumuşak gölge — cam "yüzüyor" hissi.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
              fit: StackFit.expand,
              children: [
                // 1) Cam: Impeller'da sıvı cam kırılması (shader), değilse buzlu cam;
                //    üstüne aynı koyu gri tint (geçirgenlik değişmedi).
                if (lens != null)
                  GlassLensBackdrop(
                    program: lens,
                    child: ColoredBox(color: glassTintColor(widget.tint)),
                  )
                else
                  BackdropFilter(
                    filter: _glass,
                    child: ColoredBox(color: glassTintColor(widget.tint)),
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
                // 3) Kayan seçim kapsülü (bara oturmuş hâli) — havalandıkça solar.
                AnimatedBuilder(
                  animation: Listenable.merge([_pos, _lift, _presence]),
                  builder: (context, _) => Positioned.fromRect(
                    rect: _pillRect(slot, inset),
                    child: IgnorePointer(
                      key: const ValueKey('glassTabBarPill'),
                      child: _SelectionPill(
                          fade: (1 - _lift.value.clamp(0.0, 1.0)) *
                              _presence.value.clamp(0.0, 1.0)),
                    ),
                  ),
                ),
                // 4) Sekmeler.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: inset),
                  child: Row(children: List.generate(kGlassBarSlots, _slot)),
                ),
                // 5) Kenar ışığı (specular rim).
                const IgnorePointer(child: CustomPaint(painter: _RimPainter(radius))),
              ],
            ),
        ),
      ),
            // 6) Havalanan cam damla (bar kırpmasının DIŞINDA): alttaki ikonları büyütür.
            AnimatedBuilder(
              animation: Listenable.merge([_pos, _lift, _presence]),
              builder: (context, _) {
                final l = _lift.value.clamp(0.0, 1.0) * _presence.value.clamp(0.0, 1.0);
                if (l <= 0.01) return const SizedBox.shrink();
                return Positioned.fromRect(
                  rect: _pillRect(slot, inset),
                  child: IgnorePointer(
                    key: const ValueKey('glassTabBarDroplet'),
                    child: _LiftedDroplet(lift: l, lens: lens),
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }

  /// Slotun ikon rengi: kapsülün o slota yakınlığına göre beyaz → seçili mavisi.
  Color _iconColor(int i) {
    // Yay hedefe ~1e-3 yakınlıkta durur → uçlarda tam renge oturt.
    final t = (1 - (_pos.value - i).abs()).clamp(0.0, 1.0) * _presence.value.clamp(0.0, 1.0);
    if (t > 0.99) return kGlassBarSelectedColor;
    if (t < 0.01) return Colors.white;
    return Color.lerp(Colors.white, kGlassBarSelectedColor, t)!;
  }

  Widget _slot(int i) {
    final selected = widget.selected == i;
    final Widget icon = AnimatedBuilder(
      animation: Listenable.merge([_pos, _presence]),
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

/// Açık gri cam mini kapsül (ikinci blur YOK — sadece yarı saydam dolgu + ince kenar).
class _SelectionPill extends StatelessWidget {
  const _SelectionPill({this.fade = 1});

  /// 1 = tam görünür (bara oturmuş), 0 = görünmez (damla havada).
  final double fade;

  @override
  Widget build(BuildContext context) {
    if (fade <= 0) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kGlassBarHeight),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.20 * fade),
            Colors.white.withValues(alpha: 0.12 * fade),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12 * fade), width: 0.8),
      ),
    );
  }
}

/// Seçimde havalanan cam damla: Impeller'da büyüten mercek (alttaki ikonlar büyür + kenar
/// kırılması), değilse yarı saydam cam; parlak kenar + yumuşak gölge. [lift] 0..1.
class _LiftedDroplet extends StatelessWidget {
  const _LiftedDroplet({required this.lift, required this.lens});

  final double lift;
  final ui.FragmentProgram? lens;

  @override
  Widget build(BuildContext context) {
    final a = (lift * 1.6).clamp(0.0, 1.0);
    final glass = ColoredBox(color: Colors.white.withValues(alpha: 0.06 + 0.06 * a));
    final l = lens;
    return Opacity(
      opacity: a,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kGlassBarHeight * 2),
          boxShadow: const [
            BoxShadow(color: Color(0x47000000), blurRadius: 16, offset: Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kGlassBarHeight * 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (l != null)
                GlassLensBackdrop(program: l, zoom: 1 + _kLiftZoom * lift, child: glass)
              else
                glass,
              const CustomPaint(painter: _DropletRimPainter()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Damlanın parlak cam kenarı: üstte güçlü, altta yakalanan ışık.
class _DropletRimPainter extends CustomPainter {
  const _DropletRimPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.6);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.5, 1.0],
        colors: [Color(0x99FFFFFF), Color(0x1AFFFFFF), Color(0x4DFFFFFF)],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _DropletRimPainter old) => false;
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
