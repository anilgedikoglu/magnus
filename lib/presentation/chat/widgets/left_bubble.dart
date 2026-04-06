import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/chat_node.dart';

/// Magnus'un konuşma balonunu gösterir (sol taraf).
/// Unity'deki SpeechBubbleLeft.cs karşılığı.
class LeftBubble extends StatefulWidget {
  final String text;
  final BubbleColorTheme colorTheme;

  const LeftBubble({
    super.key,
    required this.text,
    this.colorTheme = BubbleColorTheme.color1,
  });

  @override
  State<LeftBubble> createState() => _LeftBubbleState();
}

class _LeftBubbleState extends State<LeftBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.70; // Unity: 70% of canvas width

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 48,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Magnus avatar circle
              _MagnusAvatar(),
              const SizedBox(width: 8),
              // Bubble
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minHeight: 35,
                ),
                child: _BubbleBody(
                  text: widget.text,
                  colorTheme: widget.colorTheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MagnusAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Unity: profile photo circle 35×35
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: AppColors.bubble1,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.bubbleFrame1.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/magnusicon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text(
              'M',
              style: TextStyle(
                fontFamily: 'AngillaTattoo',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  final String text;
  final BubbleColorTheme colorTheme;

  const _BubbleBody({required this.text, required this.colorTheme});

  @override
  Widget build(BuildContext context) {
    final colors = _gradientColors(colorTheme);
    final frameColor = _frameColor(colorTheme);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: frameColor.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30), // Unity: 30% black shadow
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12), // Unity: bubbleFrameBlank = 5, +padding
      child: Text(
        text,
        style: AppTextStyles.bubbleTextForLength(text.length),
      ),
    );
  }

  List<Color> _gradientColors(BubbleColorTheme theme) {
    switch (theme) {
      case BubbleColorTheme.color1:
        return AppColors.bubble1;
      case BubbleColorTheme.color2:
        return AppColors.bubble2;
      case BubbleColorTheme.color3:
        return AppColors.bubble3;
      case BubbleColorTheme.color4:
        return AppColors.bubble4;
      case BubbleColorTheme.color5:
        return AppColors.bubble5;
    }
  }

  Color _frameColor(BubbleColorTheme theme) {
    switch (theme) {
      case BubbleColorTheme.color1:
        return AppColors.bubbleFrame1;
      case BubbleColorTheme.color2:
        return AppColors.bubbleFrame2;
      case BubbleColorTheme.color3:
        return AppColors.bubbleFrame3;
      case BubbleColorTheme.color4:
        return AppColors.bubbleFrame4;
      case BubbleColorTheme.color5:
        return AppColors.bubbleFrame5;
    }
  }
}
