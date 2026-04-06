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
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      // Unity: deleteSwipeRatio = 0.75 (75% swipe to delete)
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
        onTap: onTap,
        splashColor: AppColors.bubble1.first.withValues(alpha: 0.1),
        highlightColor: AppColors.bubble1.first.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            item.title,
                            style: AppTextStyles.inboxTitle.copyWith(
                              color: item.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isRead)
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
                      item.previewText,
                      style: AppTextStyles.inboxDescription.copyWith(
                        color: item.isRead
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          item.fortuneTypeLabel,
                          style: AppTextStyles.inboxMeta.copyWith(
                            color: AppColors.navBarActive,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _formatDate(item.date),
                          style: AppTextStyles.inboxMeta,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
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

class _FortuneIcon extends StatelessWidget {
  final InboxItem item;

  const _FortuneIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    final emoji = _emoji(item.fortuneType);
    final gradient = _gradient(item.fortuneType);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  String _emoji(FortuneType type) {
    switch (type) {
      case FortuneType.coffee:
        return '☕';
      case FortuneType.tarot:
        return '🃏';
      case FortuneType.astrology:
        return '✨';
      case FortuneType.dream:
        return '🌙';
      case FortuneType.motivation:
        return '💫';
      case FortuneType.general:
        return '🔮';
    }
  }

  List<Color> _gradient(FortuneType type) {
    switch (type) {
      case FortuneType.coffee:
        return AppColors.bubble2;
      case FortuneType.tarot:
        return AppColors.bubble1;
      case FortuneType.astrology:
        return AppColors.bubble5;
      case FortuneType.dream:
        return AppColors.bubble3;
      default:
        return AppColors.bubble1;
    }
  }
}
