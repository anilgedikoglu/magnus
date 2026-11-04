// C:/src/magnus_app/lib/presentation/kehanet/kahinler_menu_screen.dart
// Kahinlere Sor menüsü - 5 kahin seçimi

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/filmed_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ad_service.dart';
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
      backgroundColor: AppColors.ink,
      body: GrimoireBackdrop(child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.bone),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      s.askOracles,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle,
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
      )),
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
      child: _OraclePortraitCard(asset: kahin.iconPath, label: kahin.name),
    );
  }
}

class _Kahin {
  final String name, iconPath, id;
  const _Kahin(this.name, this.iconPath, this.id);
}

class _OraclePortraitCard extends StatefulWidget {
  final String asset, label;
  const _OraclePortraitCard({required this.asset, required this.label});
  @override
  State<_OraclePortraitCard> createState() => _OraclePortraitCardState();
}
class _OraclePortraitCardState extends State<_OraclePortraitCard> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => _down = true),
    onPointerUp: (_) => setState(() => _down = false),
    onPointerCancel: (_) => setState(() => _down = false),
    child: GlassPanel(selected: _down, child: Column(children: [
      Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: FilmedImage(widget.asset, active: _down, fit: BoxFit.contain))),
      Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
        child: Text(widget.label, textAlign: TextAlign.center, maxLines: 2,
          overflow: TextOverflow.ellipsis, style: AppTextStyles.cardLabel)),
    ])),
  );
}
