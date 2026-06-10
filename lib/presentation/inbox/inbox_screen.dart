import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/services/ad_service.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';
import 'widgets/inbox_item_card.dart';
import 'inbox_detail_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxProvider);
    final s = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: Text(s.inboxTitle),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, ref),
              child: Text(
                s.clearAll,
                style: AppTextStyles.inboxMeta.copyWith(
                  color: AppColors.glowRed.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        // Soldan sağa swipe → geri (ana menüye dön)
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? _buildEmpty(s)
                  : _buildList(context, ref, items),
            ),
            _buildBackButton(context, s),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, AppStrings s) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chevron_left_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 2),
                Text(
                  s.backButton,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppStrings s) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/welcomscreenbackground.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        Container(color: const Color(0xFF100B35).withValues(alpha: 0.50)),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: AppColors.bubble1,
                ).createShader(bounds),
                child: const Text(
                  '✦',
                  style: TextStyle(fontSize: 64, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.inboxEmpty,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 8),
              Text(
                s.inboxEmptyDesc,
                style: AppTextStyles.inboxDescription,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<InboxItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: AppColors.divider,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InboxItemCard(
          item: item,
          onTap: () => _openDetail(context, ref, item),
          onDismissed: () => ref.read(inboxProvider.notifier).deleteItem(item.id),
        );
      },
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, InboxItem item) {
    // Rewarded reklam yalnızca yeni (okunmamış) fallarda gösterilir.
    if (!item.isRead) {
      AdService.instance.showRewarded(
        onRewarded: () => _navigateToDetail(context, ref, item),
        onFailed:   () => _navigateToDetail(context, ref, item),
      );
    } else {
      _navigateToDetail(context, ref, item);
    }
  }

  void _navigateToDetail(BuildContext context, WidgetRef ref, InboxItem item) {
    if (!item.isRead) {
      ref.read(inboxProvider.notifier).markRead(item.id);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InboxDetailScreen(item: item)),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final s = ref.read(l10nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: Text(s.deleteAllConfirm, style: AppTextStyles.inboxTitle),
        content: Text(
          s.deleteAllSubtitle,
          style: AppTextStyles.inboxDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel,
                style: AppTextStyles.answerText.copyWith(
                  color: AppColors.textMuted,
                )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete,
                style: AppTextStyles.answerText.copyWith(
                  color: AppColors.glowRed,
                )),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Hazırlanmakta olan (kilitli) falları silme, gerisini sil
      final items = ref.read(inboxProvider);
      for (final item in items) {
        if (!item.isLocked) {
          await ref.read(inboxProvider.notifier).deleteItem(item.id);
        }
      }
    }
  }
}
