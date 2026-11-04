// lib/core/widgets/occult_button.dart
//
// "Gece Grimuarı" butonları (2026-11, sanat yönetmeni + Codex sentezi):
//   • primary   — cam yüzey + 1px mum altını kenar + kemik metin, 52dp; basınca altın %14
//                 dolgu. Neon gölge YOK. EKRANDA TEK birincil buton.
//   • secondary — cam yüzey + nötr kemik kenar (Geri Git ile aynı aile).
// Dokunma alanı ≥ 48 px. Basınca 0.98 ölçek (0.95 "oyuncak" hissi veriyordu — Codex).
// Not: "Geri Git" butonu proje standardıyla (CLAUDE.md) aynen kalır; bu bileşen ona dokunmaz.

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class OccultButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  final bool expand;

  const OccultButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.icon,
    this.expand = true,
  });

  const OccultButton.secondary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expand = true,
  }) : primary = false;

  @override
  State<OccultButton> createState() => _OccultButtonState();
}

class _OccultButtonState extends State<OccultButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final fg = enabled ? AppColors.bone : AppColors.ash;
    final edge = widget.primary
        ? AppColors.gold.withValues(alpha: enabled ? 0.85 : 0.35)
        : AppColors.rim;
    final fill = Color.alphaBlend(
      widget.primary && _down
          ? AppColors.gold.withValues(alpha: 0.14)
          : const Color(0x00000000),
      AppColors.glassTint,
    );

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: widget.primary ? AppColors.gold : fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.uiLabel.copyWith(color: fg),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: edge, width: widget.primary ? 1.0 : 0.9),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
