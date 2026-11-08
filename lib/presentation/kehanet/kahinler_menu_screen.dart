// C:/src/magnus_app/lib/presentation/kehanet/kahinler_menu_screen.dart
// Kahinlere Sor menüsü - 5 kahin seçimi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../data/providers.dart';

class KahinlerMenuScreen extends ConsumerWidget {
  const KahinlerMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final kahinler = [
      _Kahin('Derun', 'assets/images/kahinler/derun.png', 'derun'),
      _Kahin('Uraz', 'assets/images/kahinler/uraz.png', 'uraz'),
      _Kahin('Khaleesi', 'assets/images/kahinler/khaleesi.png', 'khaleesi'),
      _Kahin('Likia', 'assets/images/kahinler/likia.png', 'likia'),
      _Kahin('Yousuf', 'assets/images/kahinler/yousuf.png', 'yousuf'),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      s.askOracles, // toUpperCase YOK (Türkçe İ); başlık Cinzel
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              // Kartlar mevcut yüksekliğe TAM sığsın → scroll kalmasın (Anıl, 2026-11-07):
              // oran kullanılabilir yükseklikten hesaplanır, grid kaydırılmaz.
              child: LayoutBuilder(
                builder: (ctx, c) {
                  const cols = 2;
                  const pad = 20.0, gap = 16.0;
                  final rows = (kahinler.length + cols - 1) ~/ cols;
                  final tileW = (c.maxWidth - pad * 2 - gap * (cols - 1)) / cols;
                  final tileH = (c.maxHeight - pad * 2 - gap * (rows - 1)) / rows;
                  final ratio =
                      (tileH > 0 ? tileW / tileH : 0.85).clamp(0.5, 1.4);
                  return GridView.builder(
                    padding: const EdgeInsets.all(pad),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: gap,
                      childAspectRatio: ratio,
                    ),
                    itemCount: kahinler.length,
                    itemBuilder: (ctx, i) => _buildKahin(ctx, kahinler[i]),
                  );
                },
              ),
            ),
            const FloatingBarSpacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildKahin(BuildContext context, _Kahin kahin) {
    return GestureDetector(
      onTap: () {
        if (context.mounted) context.push('/parmak_surtme', extra: kahin.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.40),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  kahin.iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    color: Color(0xFFFF55FF),
                    size: 60,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                kahin.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kahin {
  final String name, iconPath, id;
  const _Kahin(this.name, this.iconPath, this.id);
}
