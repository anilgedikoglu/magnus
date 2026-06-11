// lib/presentation/kehanet/yuz_fali_kimin_screen.dart
// Yüz Falı — kimin için olduğunu soran ekran.
// Günde 1 hak — SharedPreferences ile kontrol edilir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/swipe_back.dart';
import '../../data/providers.dart';

class YuzFaliKiminScreen extends StatefulWidget {
  const YuzFaliKiminScreen({super.key});

  @override
  State<YuzFaliKiminScreen> createState() => _YuzFaliKiminScreenState();
}

class _YuzFaliKiminScreenState extends State<YuzFaliKiminScreen> {
  bool _yukleniyor  = true;
  bool _gunlukDoldu = false;

  @override
  void initState() {
    super.initState();
    _kontrolEt();
  }

  Future<void> _kontrolEt() async {
    final prefs    = await SharedPreferences.getInstance();
    final today    = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final saved    = prefs.getString('yuzfali_bugun_tarih') ?? '';
    if (mounted) {
      setState(() {
        _gunlukDoldu = saved == todayStr;
        _yukleniyor  = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwipeBack(
      onSwipeBack: () => context.pop(),
      child: Scaffold(
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
                Expanded(
                  child: Consumer(
                    builder: (ctx, ref, _) => Text(
                      ref.watch(l10nProvider).faceFortuneTilte,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ]),
            ),

            // ── İçerik ────────────────────────────────────────────────────
            Expanded(
              child: _yukleniyor
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF55FF)))
                  : _gunlukDoldu
                      ? _buildKilitli()
                      : _buildSecim(),
            ),

            // ── Geri Git butonu ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GestureDetector(
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
                  child: Consumer(
                    builder: (ctx, ref, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 2),
                        Text(
                          ref.watch(l10nProvider).backButton,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ── Kilitli (günlük hak doldu) ────────────────────────────────────────────
  Widget _buildKilitli() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(color: const Color(0xFFFF55FF).withValues(alpha: 0.30), width: 1.5),
            ),
            child: const Center(
              child: Text('🔒', style: TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Günlük hakkın doldu',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Yüz falı günde 1 kez bakılabilir.\nYarın tekrar gel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Normal seçim ─────────────────────────────────────────────────────────
  Widget _buildSecim() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Göz bebeği ikonu
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF55FF).withValues(alpha: 0.30),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF9B00D3).withValues(alpha: 0.20),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/gozbebegi.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('👁', style: TextStyle(fontSize: 44)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 36),

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

          _KiminButon(
            emoji: '🧍',
            label: 'Kendim için',
            sublabel: 'Kendi fotoğrafımı analiz et',
            onTap: () => context.push('/yuz_fali_foto', extra: 'kullanici'),
          ),

          const SizedBox(height: 16),

          _KiminButon(
            emoji: '👤',
            label: 'Başkası için',
            sublabel: 'Başka birinin fotoğrafını analiz et',
            onTap: () => context.push('/yuz_fali_foto', extra: 'baskasi'),
          ),
        ],
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
