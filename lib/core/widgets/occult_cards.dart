// lib/core/widgets/occult_cards.dart
//
// "Gece Grimuarı" ortak seçim bileşenleri (2026-11). Tüm seçim ekranları bu ikisinden
// birini kullanır (sanat yönetmeni kabul kriteri):
//   • OccultChoiceTile — 2×2 alan kartı (Kahve konusu, Dert Ortağı, Tarot türü…):
//       cam kart + tek glif (32dp, kül) + Cinzel etiket. Basınca glif + kenar mum altını.
//   • OccultListCard   — Numeroloji liste kartı şablonu (Yüz falı "kimin için", Durugörü,
//       Yana, Maganda soruları…): cam satır + 44dp cam ikon karosu + başlık + altyazı + ok.
//   • OccultSectionLabel — bölüm etiketi: önde 12px altın çizgi + Jost kül, geniş aralık.
// Glif: Widget (Icon, CustomPaint ya da maske PNG). Renk, `color` ile verilir.

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'glass_panel.dart';

/// Glif oluşturucu: verilen renkte bir ikon widget'ı döndürür.
typedef GlyphBuilder = Widget Function(Color color, double size);

class OccultChoiceTile extends StatefulWidget {
  final String label;
  final GlyphBuilder glyph;
  final VoidCallback? onTap;
  final bool selected;

  const OccultChoiceTile({
    super.key,
    required this.label,
    required this.glyph,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<OccultChoiceTile> createState() => _OccultChoiceTileState();
}

class _OccultChoiceTileState extends State<OccultChoiceTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final lit = _down || widget.selected;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: GlassPanel(
            selected: lit,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.glyph(lit ? AppColors.gold : AppColors.boneDim, 34),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: lit ? AppColors.bone : AppColors.boneDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OccultListCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final GlyphBuilder glyph;
  final VoidCallback? onTap;

  const OccultListCard({
    super.key,
    required this.title,
    required this.glyph,
    required this.onTap,
    this.subtitle,
  });

  @override
  State<OccultListCard> createState() => _OccultListCardState();
}

class _OccultListCardState extends State<OccultListCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.subtitle == null ? widget.title : '${widget.title}. ${widget.subtitle}',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: GlassPanel(
            selected: _down,
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x14E8E2D6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.rim, width: 0.8),
                  ),
                  alignment: Alignment.center,
                  child: widget.glyph(AppColors.gold, 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title,
                          style: AppTextStyles.value, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(widget.subtitle!,
                            style: AppTextStyles.meta.copyWith(fontSize: 13),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.ash, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OccultSectionLabel extends StatelessWidget {
  final String text;
  const OccultSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 1, color: AppColors.gold),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: AppTextStyles.sectionLabel)),
      ],
    );
  }
}
