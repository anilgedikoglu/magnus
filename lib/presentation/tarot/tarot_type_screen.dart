import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/swipe_back.dart';
import '../../data/providers.dart';

// ─── Tarot türü seçim ekranı ──────────────────────────────────────────────────

class TarotTypeScreen extends ConsumerWidget {
  const TarotTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    return SwipeBack(
      onSwipeBack: () => context.pop(),
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: Text(s.tarot),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                s.tarotType,
                style: AppTextStyles.title.copyWith(fontSize: 20, letterSpacing: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.78,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _TypeCard(
                      imagePath: 'assets/images/tarotbir.png',
                      label: s.classicTarot,
                      gradient: AppColors.bubble1,
                      onTap: () => context.push('/tarot/klasik'),
                    ),
                    _TypeCard(
                      imagePath: 'assets/images/tarotiki.png',
                      label: s.loveTarot,
                      gradient: const [Color(0xFFCC1177), Color(0xFFFF44AA)],
                      onTap: () => context.push('/tarot/ask'),
                    ),
                    _TypeCard(
                      imagePath: 'assets/images/tarotuc.png',
                      label: s.wishTarot,
                      gradient: AppColors.bubble5,
                      onTap: () => context.push('/tarot/dilek'),
                    ),
                    _TypeCard(
                      imagePath: 'assets/images/tarotdort.png',
                      label: s.luckTarot,
                      gradient: AppColors.bubble2,
                      onTap: () => context.push('/tarot/sans'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 2),
                      Text(s.backButton,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _TypeCard({
    required this.imagePath,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: gradient.first.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient.first.withValues(alpha: 0.15),
                gradient.last.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient.first.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.style_rounded,
                      size: 48,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.inboxTitle.copyWith(
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
