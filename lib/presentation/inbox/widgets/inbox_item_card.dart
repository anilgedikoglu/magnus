import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/inbox_item.dart';

class InboxItemCard extends StatelessWidget {
  final InboxItem item;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const InboxItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final locked = item.isLocked;
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.75},
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.inboxDeleteBackground,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Sil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'ChixaDemiBold',
                )),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: InkWell(
        onTap: locked ? null : onTap, // kilitliyse dokunma engeli
        splashColor: locked
            ? Colors.transparent
            : AppColors.bubble1.first.withValues(alpha: 0.1),
        highlightColor: locked
            ? Colors.transparent
            : AppColors.bubble1.first.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          ? 'Falın yorumlanıyor…'
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
                        _formatDate(item.date),
                        style: AppTextStyles.inboxMeta,
                      ),
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
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Bugün';
      if (diff.inDays == 1) return 'Dün';
      if (diff.inDays < 7) return '${diff.inDays} gün önce';
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return '';
    }
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
              // PNG ikon — kilitliyse "2" (siyah-beyaz) versiyonu
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: assetPath != null
                    ? Image.asset(
                        assetPath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : _FallbackIcon(type: widget.item.fortuneType),
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
    }
  }
}

// ─── PNG bulunamazsa emoji fallback ───────────────────────────────────────────

class _FallbackIcon extends StatelessWidget {
  final FortuneType type;
  const _FallbackIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final emoji = switch (type) {
      FortuneType.coffee     => '☕',
      FortuneType.tarot      => '🃏',
      FortuneType.astrology  => '✨',
      FortuneType.dream      => '🌙',
      FortuneType.motivation => '💫',
      FortuneType.general    => '🔮',
      FortuneType.birthChart  => '🌟',
      FortuneType.numeroloji  => '🔢',
      FortuneType.durugoru    => '👁️',
      FortuneType.elfali      => '🖐️',
      FortuneType.iching      => '☯',
    };
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
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
