import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/chat_node.dart';
import 'legal_disclosure_screen.dart';

/// Kullanıcıya sunulan cevap seçeneklerini gösterir.
/// Unity'deki AnswerBubble.cs karşılığı.
/// Layout: vertical (altAlta) veya horizontal (yanYana).
class AnswerBubbleRow extends ConsumerStatefulWidget {
  final List<String> answers;
  final AnswerLayout layout;
  final void Function(int index) onSelected;
  final bool showLegalButton;

  const AnswerBubbleRow({
    super.key,
    required this.answers,
    required this.layout,
    required this.onSelected,
    this.showLegalButton = false,
  });

  @override
  ConsumerState<AnswerBubbleRow> createState() => _AnswerBubbleRowState();
}

class _AnswerBubbleRowState extends ConsumerState<AnswerBubbleRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  int? _selectedIndex;
  bool _legalApproved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slight delay so Magnus bubble appears first
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (_selectedIndex != null) return; // already selected
    setState(() => _selectedIndex = index);
    Future.delayed(const Duration(milliseconds: 150), () {
      widget.onSelected(index);
    });
  }

  Future<void> _openLegal() async {
    final approved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LegalDisclosureScreen(),
      ),
    );
    if (approved == true) {
      setState(() => _legalApproved = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showLegalButton) ...[
                _LegalButton(onTap: _openLegal),
                const SizedBox(height: 10),
              ],
              widget.layout == AnswerLayout.horizontal
                  ? _buildHorizontal()
                  : _buildVertical(),
            ],
          ),
        ),
      ),
    );
  }

  bool _isButtonDisabled(int i) {
    if (widget.showLegalButton && !_legalApproved) return true;
    return _selectedIndex != null && _selectedIndex != i;
  }

  Widget _buildVertical() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < widget.answers.length; i++) ...[
          _AnswerButton(
            label: widget.answers[i],
            isSelected: _selectedIndex == i,
            isDisabled: _isButtonDisabled(i),
            onTap: () => _handleTap(i),
          ),
          if (i < widget.answers.length - 1)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildHorizontal() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < widget.answers.length; i++)
          _AnswerButton(
            label: widget.answers[i],
            isSelected: _selectedIndex == i,
            isDisabled: _isButtonDisabled(i),
            onTap: () => _handleTap(i),
          ),
      ],
    );
  }
}

class _AnswerButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = !widget.isDisabled;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.isDisabled ? 0.35 : 1.0,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTapDown: isActive ? (_) => _pressController.reverse() : null,
          onTapUp: isActive ? (_) => _pressController.forward() : null,
          onTapCancel: isActive ? () => _pressController.forward() : null,
          onTap: isActive ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? const LinearGradient(
                      colors: AppColors.bubble1,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isSelected
                  ? null
                  : AppColors.answerBubbleFill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.bubbleFrame1
                    : AppColors.answerBubbleBorder,
                width: widget.isSelected ? 1.5 : 1,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.bubble1.first.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: AppTextStyles.answerText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _LegalButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: AppColors.answerBubbleFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.answerBubbleBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: AppColors.navBarActive.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              ref.watch(l10nProvider).legalDisclosure,
              style: AppTextStyles.answerText.copyWith(
                color: AppColors.navBarActive.withValues(alpha: 0.8),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
