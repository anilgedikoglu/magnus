import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/providers.dart';

class AstrologyScreen extends ConsumerStatefulWidget {
  const AstrologyScreen({super.key});

  @override
  ConsumerState<AstrologyScreen> createState() => _AstrologyScreenState();
}

class _AstrologyScreenState extends ConsumerState<AstrologyScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final zodiac = profile.zodiacSign ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: const Text('Astroloji'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.bubble5,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bubble5.first.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    zodiac.isNotEmpty && zodiac != '—' ? zodiac : 'Burç Yorumu',
                    style: AppTextStyles.title.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Günlük Astroloji Yorumu',
                    style: AppTextStyles.inboxMeta.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Info about zodiac
            if (zodiac == '—' || zodiac.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.navBarActive, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Burç yorumu için profilinde doğum tarihin olmalı.',
                        style: AppTextStyles.inboxDescription,
                      ),
                    ),
                  ],
                ),
              ),
            if (zodiac != '—' && zodiac.isNotEmpty) ...[
              Text(
                'NASIL ÇALIŞIR?',
                style: AppTextStyles.inboxMeta.copyWith(
                  color: AppColors.navBarActive,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: '🌟',
                      text:
                          'Burç enerjine göre kişiselleştirilmiş günlük yorum alırsın.',
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: '📬',
                      text:
                          'Yorum gelen kutuna düşer, istediğin zaman okuyabilirsin.',
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: '🔄',
                      text:
                          'Her yorumun farklı: aşk, kariyer, enerji ve daha fazlası.',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),
            // CTA button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: (zodiac == '—' || zodiac.isEmpty) || _isGenerating
                    ? null
                    : _generateReading,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity:
                      (zodiac == '—' || zodiac.isEmpty) ? 0.4 : 1.0,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.bubble5,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bubble5.first.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isGenerating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Yorumumu Al ✨',
                              style: AppTextStyles.answerText.copyWith(
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReading() async {
    setState(() => _isGenerating = true);
    try {
      final profile = ref.read(userProfileProvider);
      final service = ref.read(fortuneServiceProvider);
      final item = await service.generateDailyAstrology(profile: profile);
      await ref.read(inboxProvider.notifier).addItem(item);
      if (!mounted) return;
      context.go('/inbox');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: AppTextStyles.inboxDescription),
        ),
      ],
    );
  }
}
