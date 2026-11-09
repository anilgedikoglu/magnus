import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/ad_pacing.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/widgets/filmed_image.dart';
import '../../../data/models/inbox_item.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/providers.dart';

class InboxItemCard extends ConsumerWidget {
  final InboxItem item;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  /// Kilitli (hazırlanan) karta dokunuş: ödüllü "hemen aç" teklifi. null ise kilitli kart tepkisiz.
  final VoidCallback? onLockedTap;

  const InboxItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDismissed,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final locked = item.isLocked;
    // Silme KİLİDİ (Anıl, 2026-11-07): sol-swipe DİREKT silmez → sağdan KARE düğme belirir.
    // Fal "okundu" olana kadar silinemez: okunmuş → koyu vişne "Sil"; okunmamış/hazırlanan →
    // turuncu kilit (basınca silmez). Swipe en fazla düğme kadar → yazı ekrandan çıkmaz.
    final deletable = item.isRead;
    return _SwipeActionRow(
      deletable: deletable,
      deleteLabel: s.deleteSwipe,
      onDelete: onDismissed,
      onTapWhenClosed: locked ? onLockedTap : onTap,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İkon — kilitliyse saat yönünde açılım animasyonu
              _FortuneIcon(item: item),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            locked ? item.fortuneTypeLabel : item.displayTitle,
                            style: AppTextStyles.inboxTitle.copyWith(
                              fontWeight: (!locked && !item.isRead)
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontFeatures: AppTextStyles.tabular,
                              color: locked
                                  ? AppColors.textMuted
                                  : item.isRead
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isRead && !locked)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.inboxUnread,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locked
                          ? s.beingInterpreted
                          : item.previewText,
                      style: AppTextStyles.inboxDescription.copyWith(
                        color: locked
                            ? AppColors.textMuted
                            : item.isRead
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Hazırlanırken altta kısa "X dakika önce" bilgisi göster
                    if (locked) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(item.date, s),
                        style: AppTextStyles.inboxMeta,
                      ),
                      if (onLockedTap != null && item.hemenAcmayaDeger)
                        _HemenAcIsareti(etiket: s.adOpenNowHint),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                locked
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                color: locked
                    ? AppColors.textMuted.withValues(alpha: 0.5)
                    : AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
    );
  }

  String _formatDate(String isoDate, AppStrings s) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return s.todayLabel;
      if (diff.inDays == 1) return s.yesterdayLabel;
      if (diff.inDays < 7) return '${diff.inDays} ${s.daysAgo}';
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─── "Reklam izle, hemen aç" işareti: yalnız teklif yapılabiliyorsa görünür ──

class _HemenAcIsareti extends StatelessWidget {
  final String etiket;
  const _HemenAcIsareti({required this.etiket});

  @override
  Widget build(BuildContext context) {
    final ads = AdService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: ads.odulluHazir,
      builder: (_, __, ___) {
        if (!ads.odulTeklifiHazir(OdulTuru.hemenAc)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, color: AppColors.gold, size: 14),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    etiket,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.inboxMeta.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── İkon widget'ı (saat yönünde açılım animasyonlu) ─────────────────────────

class _FortuneIcon extends StatefulWidget {
  final InboxItem item;
  const _FortuneIcon({required this.item});

  @override
  State<_FortuneIcon> createState() => _FortuneIconState();
}

class _FortuneIconState extends State<_FortuneIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    final item = widget.item;
    if (!item.isLocked) {
      _ctrl = AnimationController(vsync: this, value: 1.0, duration: const Duration(seconds: 1));
      return;
    }
    try {
      final created = DateTime.parse(item.date);
      final unlock = DateTime.parse(item.unlockAt!);
      final totalMs = unlock.difference(created).inMilliseconds;
      final elapsedMs = DateTime.now().difference(created).inMilliseconds;
      final progress = (elapsedMs / totalMs).clamp(0.0, 1.0);
      final remainingMs = (totalMs - elapsedMs).clamp(0, totalMs);

      _ctrl = AnimationController(
        vsync: this,
        value: progress,
        duration: Duration(milliseconds: remainingMs),
      );
      if (remainingMs > 0) _ctrl.forward();
    } catch (_) {
      _ctrl = AnimationController(vsync: this, value: 1.0, duration: const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final progress = _ctrl.value; // 0.0 = tam kilitli, 1.0 = açık
        final locked = progress < 1.0;
        final assetPath = _iconAsset(widget.item.fortuneType, locked: locked);

        return SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: [
              // PNG ikon — kilitliyse "2" (siyah-beyaz) versiyonu. Gece Grimuarı filmi:
              // neon çizgi ikonlar kısılır (hazır: hafif renk, okunmuş: daha da soluk).
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.inkCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: assetPath != null
                      ? ColorFiltered(
                          colorFilter: ColorFilter.matrix(locked
                              ? FilmedImage.matrix(0.0, 1.0)
                              : widget.item.isRead
                                  ? FilmedImage.matrix(1.0, 1.0)
                                  : FilmedImage.matrix(1.0, 1.0)),
                          child: Image.asset(
                            assetPath,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _FallbackIcon(type: widget.item.fortuneType),
                          ),
                        )
                      : _FallbackIcon(type: widget.item.fortuneType),
                ),
              ),
              // Cam kenar
              IgnorePointer(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.rim, width: 0.8),
                  ),
                ),
              ),
              // Saat yönünde açılım örtüsü (kilitliyse)
              if (locked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomPaint(
                    size: const Size(50, 50),
                    painter: _SweepOverlayPainter(progress: progress),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Hazır → renkli ikon, kilitli/hazırlanıyor → "2" (siyah-beyaz) ikon.
  /// Eşleşme yoksa null döner, fallback emoji kullanılır.
  static String? _iconAsset(FortuneType type, {required bool locked}) {
    const base = 'assets/images/inbox_icons/';
    switch (type) {
      case FortuneType.coffee:
        return locked ? '${base}kahve2.png' : '${base}kahve.png';
      case FortuneType.tarot:
        return locked ? '${base}tarot2.png' : '${base}tarot.png';
      case FortuneType.astrology:
        return locked ? '${base}astroloji2.png' : '${base}astroloji.png';
      case FortuneType.motivation:
        return locked ? '${base}motivasyon2.png' : '${base}motivasyon.png';
      case FortuneType.dream:
        return locked ? '${base}ruya2.png' : '${base}ruya.png';
      case FortuneType.general:
        return locked ? '${base}cark2.png' : '${base}cark.png';
      case FortuneType.birthChart:
        return locked ? '${base}dogum2.png' : '${base}dogum.png';
      case FortuneType.numeroloji:
        return locked ? '${base}numeroloji2.png' : '${base}numeroloji.png';
      case FortuneType.durugoru:
        return locked ? '${base}durugoru2.png' : '${base}durugoru.png';
      case FortuneType.elfali:
        return locked ? '${base}elfali2.png' : '${base}elfali.png';
      case FortuneType.iching:
        return locked ? '${base}iching2.png' : '${base}iching.png';
      case FortuneType.japonfali:
        return locked ? '${base}japonfali2.png' : '${base}japonfali.png';
      case FortuneType.yuzfali:
        return locked ? '${base}elfali2.png' : '${base}elfali.png';
    }
  }
}

// ─── PNG bulunamazsa çizgi ikon (Gece Grimuarı: emoji YOK) ─────────────────────

class _FallbackIcon extends StatelessWidget {
  final FortuneType type;
  const _FallbackIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      FortuneType.coffee     => Icons.coffee_outlined,
      FortuneType.tarot      => Icons.style_outlined,
      FortuneType.astrology  => Icons.auto_awesome_outlined,
      FortuneType.dream      => Icons.nightlight_outlined,
      FortuneType.motivation => Icons.local_fire_department_outlined,
      FortuneType.general    => Icons.blur_circular_outlined,
      FortuneType.birthChart  => Icons.brightness_7_outlined,
      FortuneType.numeroloji  => Icons.tag_rounded,
      FortuneType.durugoru    => Icons.visibility_outlined,
      FortuneType.elfali      => Icons.back_hand_outlined,
      FortuneType.iching      => Icons.contrast_rounded,
      FortuneType.japonfali   => Icons.temple_buddhist_outlined,
      FortuneType.yuzfali     => Icons.face_retouching_natural_outlined,
    };
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.inkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Icon(icon, color: AppColors.ash, size: 22)),
    );
  }
}

// ─── Saat yönünde kapatan/açan CustomPainter ──────────────────────────────────

class _SweepOverlayPainter extends CustomPainter {
  final double progress; // 0.0 = tam kaplı, 1.0 = tamamen açık

  const _SweepOverlayPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = max(size.width, size.height) * 0.8;

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    // Karanlık kısım: saat yönünde, progress kadar açılmış
    // progress=0 → tam karanlık (2π), progress=1 → hiç karanlık yok (0)
    final darkSweep = 2 * pi * (1.0 - progress);
    // Karanlık başlangıcı: 12'den clockwise ilerlemiş yer
    final darkStart = -pi / 2 + (2 * pi * progress);

    if (darkSweep <= 0) return;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        darkStart,
        darkSweep,
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SweepOverlayPainter old) => old.progress != progress;
}

// ─── Sol-swipe ile sağdan KARE aksiyon düğmesi (Anıl, 2026-11-07) ─────────────
// Direkt silmez: swipe satırı sola kaydırır, arkadan kare düğme belirir. Okunmuş →
// koyu vişne "Sil" (basınca siler); okunmamış/hazırlanan → turuncu kilit (silmez).
// Kaydırma en fazla düğme kadar → preview yazısının solu ekrandan çıkmaz.
const Color _kCherry = Color(0xFF8A1E2D); // koyu vişne
const double _kMaxButton = 76; // kare kenar üst sınırı (yazı ekranda kalsın)

class _SwipeActionRow extends StatefulWidget {
  final Widget child;
  final bool deletable;
  final String deleteLabel;
  final VoidCallback onDelete;
  final VoidCallback? onTapWhenClosed;

  const _SwipeActionRow({
    required this.child,
    required this.deletable,
    required this.deleteLabel,
    required this.onDelete,
    this.onTapWhenClosed,
  });

  @override
  State<_SwipeActionRow> createState() => _SwipeActionRowState();
}

class _SwipeActionRowState extends State<_SwipeActionRow>
    with SingleTickerProviderStateMixin {
  final GlobalKey _contentKey = GlobalKey();
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  double _buttonW = 72; // kare: satır yüksekliği (ölçülünce güncellenir, ≤ _kMaxButton)
  double _dragX = 0; // sürükleme sırasında anlık ofset
  bool _dragging = false;

  double get _x => _dragging ? _dragX : -_ctrl.value * _buttonW;
  bool get _isOpen => !_dragging && _ctrl.value > 0.5;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final h = _contentKey.currentContext?.size?.height;
    if (h == null) return;
    final w = h.clamp(52.0, _kMaxButton);
    if ((w - _buttonW).abs() > 0.5 && mounted) setState(() => _buttonW = w);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragging = true;
      _dragX = (_dragX + d.delta.dx).clamp(-_buttonW, 0.0);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final open = _dragX < -_buttonW / 2 || v < -400;
    _ctrl.value = (-_dragX / _buttonW).clamp(0.0, 1.0);
    setState(() {
      _dragging = false;
      _dragX = 0;
    });
    if (open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _close() => _ctrl.reverse();

  void _onButtonTap() {
    if (widget.deletable) {
      widget.onDelete();
    } else {
      _close(); // kilitli → silinemez, düğmeyi kapat
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final x = _x;
    return ClipRect(
      child: Stack(
        children: [
          // Arkadaki KARE aksiyon düğmesi (sağda, satır yüksekliğince)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: _buttonW,
            child: _ActionButton(
              deletable: widget.deletable,
              label: widget.deleteLabel,
              onTap: _onButtonTap,
            ),
          ),
          // İçerik — opak zemin (kapalıyken düğmeyi örter), swipe + dokunuş burada.
          Transform.translate(
            offset: Offset(x, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTap: () {
                if (_isOpen) {
                  _close();
                } else {
                  widget.onTapWhenClosed?.call();
                }
              },
              child: ColoredBox(
                color: AppColors.ink,
                child: KeyedSubtree(key: _contentKey, child: widget.child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool deletable;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.deletable,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: deletable ? _kCherry : AppColors.warning,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                deletable ? Icons.delete_outline_rounded : Icons.lock_rounded,
                color: Colors.white, // TAM beyaz (gri gözükmüyordu — Anıl)
                size: 24,
              ),
              if (deletable) ...[
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
