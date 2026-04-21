import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Soldan sağa dolarak otomatik tamamlanan buton.
/// [duration] 3–6 saniye arası rastgele seçilir.
/// Dolum tamamlanınca [onComplete] çağrılır.
class AutoProgressButton extends StatefulWidget {
  final VoidCallback onComplete;

  const AutoProgressButton({super.key, required this.onComplete});

  @override
  State<AutoProgressButton> createState() => _AutoProgressButtonState();
}

class _AutoProgressButtonState extends State<AutoProgressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final durationMs = 3000 + Random().nextInt(3001); // 3000–6000 ms
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    // Küçük gecikmeyle başlat (buton görününce)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.bubbleFrame1.withValues(alpha: 0.4),
              width: 1,
            ),
            color: AppColors.answerBubbleFill,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dolan kısım
              Positioned.fill(
                child: FractionallySizedBox(
                  widthFactor: _progress.value,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.bubble1,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
              // Ortadaki yazı
              const Text(
                'Magnus canlanıyor...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
