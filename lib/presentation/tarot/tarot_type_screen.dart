import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
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
      backgroundColor: AppColors.ink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(s.tarot, style: AppTextStyles.screenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GrimoireBackdrop(child: Padding(padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kToolbarHeight, bottom: MediaQuery.paddingOf(context).bottom), child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
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
                      onTap: () => context.push('/tarot/klasik'),
                    ),
                    _TypeCard(
                      imagePath: 'assets/images/tarotiki.png',
                      label: s.loveTarot,
                      onTap: () => context.push('/tarot/ask'),
                    ),
                    _TypeCard(
                      imagePath: 'assets/images/tarotuc.png',
                      label: s.wishTarot,
                      onTap: () => context.push('/tarot/dilek'),
                    ),
                    _TypeCard(
                      imagePath: 'assets/images/tarotdort.png',
                      label: s.luckTarot,
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
      ))),
      ),
    );
  }
}

class _TypeCard extends StatefulWidget {
 final String imagePath; final String label; final VoidCallback onTap;
 const _TypeCard({required this.imagePath, required this.label, required this.onTap});
 @override State<_TypeCard> createState() => _TypeCardState();
}
class _TypeCardState extends State<_TypeCard> {
 bool _down = false;
 @override Widget build(BuildContext context) => Semantics(button: true, label: widget.label, child: GestureDetector(
 onTap: widget.onTap, onTapDown: (_) => setState(() => _down = true),
 onTapUp: (_) => setState(() => _down = false), onTapCancel: () => setState(() => _down = false),
 child: GlassPanel(selected: _down, child: Column(children: [
 Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12,16,12,8), child: FilmedImage(widget.imagePath, fit: BoxFit.contain, active: _down))),
 Padding(padding: const EdgeInsets.fromLTRB(8,0,8,16), child: Text(widget.label, textAlign: TextAlign.center, style: AppTextStyles.cardLabel)),
 ])),));
}
