// C:/src/magnus_app/lib/presentation/kehanet/kahinler_menu_screen.dart
// Kahinlere Sor menüsü - 5 kahin seçimi

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ad_service.dart';

class KahinlerMenuScreen extends StatelessWidget {
  const KahinlerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text(
                      'KAHİNLERE SOR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: kahinler.length,
                itemBuilder: (ctx, i) => _buildKahin(ctx, kahinler[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKahin(BuildContext context, _Kahin kahin) {
    return GestureDetector(
      onTap: () {
        AdService.instance.showRewarded(
          onRewarded: () {
            if (context.mounted) context.push('/parmak_surtme', extra: kahin.id);
          },
          onFailed: () {
            if (context.mounted) context.push('/parmak_surtme', extra: kahin.id);
          },
        );
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
