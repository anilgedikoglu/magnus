import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/providers.dart';

class TarotResultScreen extends ConsumerWidget {
  final String inboxItemId;

  const TarotResultScreen({super.key, required this.inboxItemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxProvider);
    final item = items.where((i) => i.id == inboxItemId).firstOrNull;

    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Fal bulunamadı.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: const Text('Tarot Yorumun'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/inbox'),
            child: Text(
              'Gelen Kutusu',
              style: AppTextStyles.inboxMeta.copyWith(
                color: AppColors.navBarActive,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.bubble1,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bubble1.first.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🃏', style: TextStyle(fontSize: 42)),
                  const SizedBox(height: 10),
                  Text(item.title, style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.date),
                    style: AppTextStyles.inboxMeta.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Fortune text
            SelectableText(
              item.text,
              style: AppTextStyles.bubbleText.copyWith(height: 1.85),
            ),
            const SizedBox(height: 36),
            // Footer
            Center(
              child: Text('✦ Magnus ✦', style: AppTextStyles.magnusLabel),
            ),
            const SizedBox(height: 12),
            // CTA
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Center(
                    child: Text(
                      'Ana Menüye Dön',
                      style: AppTextStyles.answerText.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
