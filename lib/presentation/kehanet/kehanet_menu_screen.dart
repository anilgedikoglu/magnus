// C:/src/magnus_app/lib/presentation/kehanet/kehanet_menu_screen.dart
// Kehanet ana menüsü - Faloya, Maganda, Tamua, Yana, Kahinlere Sor

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/filmed_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/swipe_back.dart';
import '../../data/providers.dart';

class KehanetMenuScreen extends ConsumerWidget {
  const KehanetMenuScreen({super.key});

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
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _buildItem(ctx, items[i]),
              ),
            ),
          ],
        ),
      )),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _KehanetItem item) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: _OraclePortraitCard(asset: item.iconPath, label: item.label),
    );
  }
}

class _KehanetItem {
  final String label, iconPath, route;
  const _KehanetItem(this.label, this.iconPath, this.route);
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
