// lib/presentation/kehanet/yuz_fali_kimin_screen.dart
// Yüz Falı — kimin için olduğunu soran ekran.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class YuzFaliKiminScreen extends StatelessWidget {
  const YuzFaliKiminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: Column(
          children: [
            // ── Başlık ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    'YÜZ FALI',
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
              ]),
            ),

            // ── İçerik ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Yüz ikonu
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF6A0DAD), Color(0xFF2D0060)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF55FF).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🔮', style: TextStyle(fontSize: 40)),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Soru
                    const Text(
                      'Yüz analizini kimin için\nistiyorsun?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Bir fotoğraf çekeceğiz veya\ngalerinden seçeceğiz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 52),

                    // ── Kendim için ────────────────────────────────────
                    _KiminButon(
                      emoji: '🧍',
                      label: 'Kendim için',
                      sublabel: 'Kendi fotoğrafımı analiz et',
                      onTap: () => context.push('/yuz_fali_foto',
                          extra: 'kullanici'),
                    ),

                    const SizedBox(height: 16),

                    // ── Başkası için ───────────────────────────────────
                    _KiminButon(
                      emoji: '👤',
                      label: 'Başkası için',
                      sublabel: 'Başka birinin fotoğrafını analiz et',
                      onTap: () => context.push('/yuz_fali_foto',
                          extra: 'baskasi'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seçim butonu ──────────────────────────────────────────────────────────────
class _KiminButon extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _KiminButon({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0640), Color(0xFF2A0860)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B00D3).withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
