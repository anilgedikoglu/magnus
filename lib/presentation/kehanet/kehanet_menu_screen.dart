// C:/src/magnus_app/lib/presentation/kehanet/kehanet_menu_screen.dart
// Kehanet ana menüsü - Faloya, Maganda, Tamua, Yana, Kahinlere Sor

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ad_pacing.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/kehanet_hak.dart';
import '../../core/widgets/odul_teklifi.dart';
import '../../core/widgets/swipe_back.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../data/providers.dart';
import '../../core/constants/app_text_styles.dart';

class KehanetMenuScreen extends ConsumerWidget {
  const KehanetMenuScreen({super.key});

  static bool _mesgul = false; // teklif sürerken ikinci dokunuş yok

  /// Günde 3 ücretsiz giriş; sınır reklamdan bağımsızdır. Bitince isteğe bağlı ödüllü +3;
  /// reklam yoksa ya da reddedilirse diğer günlük haklar gibi "yarın gel".
  Future<void> _gir(BuildContext context, WidgetRef ref, _KehanetItem item) async {
    if (_mesgul) return;
    _mesgul = true;
    try {
      final hak = KehanetHak(ref.read(sharedPrefsProvider));
      final s = ref.read(l10nProvider);
      final now = DateTime.now();
      if (!hak.girebilir(now)) {
        final ads = AdService.instance;
        await ads.odulluBekle();
        if (!context.mounted) return;
        var kazandi = false;
        if (ads.odulMumkun(OdulTuru.hakBitti, falTuru: 'kehanet')) {
          kazandi = await odulTeklifiGoster(
            context,
            tur: OdulTuru.hakBitti,
            falTuru: 'kehanet',
            baslik: s.adOracleTitle,
            aciklama: s.adOracleBody,
            izleEtiketi: s.adWatch,
            vazgecEtiketi: s.adDecline,
          );
        }
        if (!kazandi) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(s.oracleDailyLimit),
                behavior: SnackBarBehavior.floating, // yüzen cam barın üstünde kalsın
                margin: EdgeInsets.fromLTRB(16, 0, 16, floatingBarInset(context) + 8),
              ));
          }
          return;
        }
        await hak.odulEkle(now);
      }
      await hak.kullan(now);
      if (context.mounted) context.push(item.route);
    } finally {
      _mesgul = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final items = [
      _KehanetItem('Faloya', 'assets/images/kehanet/faloya.png', '/faloya'),
      _KehanetItem('Maganda', 'assets/images/kehanet/maganda.png', '/maganda'),
      _KehanetItem('Tamua', 'assets/images/kehanet/tamua.png', '/tamua'),
      _KehanetItem('Yana', 'assets/images/kehanet/yana.png', '/yana'),
      _KehanetItem(s.askOracles, 'assets/images/menu/digerfalcilar.png', '/kahinler'),
    ];
    return SwipeBack(
      onSwipeBack: () => context.pop(),
      child: Scaffold(
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
                      s.prophecyTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              // Kartlar ekrana sığacak şekilde boyutlanır, kaydırma yok (5 öğe: 2 sütun × 3 satır).
              child: LayoutBuilder(
                builder: (ctx, c) {
                  const columns = 2, rows = 3;
                  const gap = 16.0, padH = 20.0, padV = 8.0;
                  final cellW = (c.maxWidth - 2 * padH - (columns - 1) * gap) / columns;
                  final cellH = (c.maxHeight - 2 * padV - (rows - 1) * gap) / rows;
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: gap,
                      childAspectRatio: cellW / math.max(cellH, 1),
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _buildItem(ctx, ref, items[i]),
                  );
                },
              ),
            ),
            const FloatingBarSpacer(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, _KehanetItem item) {
    return GestureDetector(
      onTap: () => _gir(context, ref, item),
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
                  item.iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFF55FF),
                    size: 60,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                item.label,
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

class _KehanetItem {
  final String label, iconPath, route;
  const _KehanetItem(this.label, this.iconPath, this.route);
}
