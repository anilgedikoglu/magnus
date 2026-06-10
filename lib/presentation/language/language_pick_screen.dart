import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers.dart';

class LanguagePickScreen extends ConsumerWidget {
  const LanguagePickScreen({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref, String locale) async {
    await ref.read(localeProvider.notifier).setLocale(locale);
    await ref.read(languagePickedProvider.notifier).markPicked();
    if (context.mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Magnus logo
                ClipOval(
                  child: Image.asset(
                    'assets/images/magnusappicon_splash.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 40),

                // Bilingual prompt — no fancy quotes
                const Text(
                  'Lütfen dil seçiniz:\nPlease select language:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 36),

                // Buttons row
                Row(
                  children: [
                    Expanded(
                      child: _LangButton(
                        label: 'Türkçe',
                        onTap: () => _pick(context, ref, 'tr'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LangButton(
                        label: 'English',
                        onTap: () => _pick(context, ref, 'en'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LangButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
