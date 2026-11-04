// lib/presentation/kehanet/yuz_fali_kimin_screen.dart
// Yüz Falı — kimin için olduğunu soran ekran.
// Günde 1 hak — SharedPreferences ile kontrol edilir.

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/occult_cards.dart';
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
      backgroundColor: AppColors.ink,
      body: GrimoireBackdrop(child: SafeArea(
        child: Column(
          children: [
            // ── Başlık ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.bone),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Consumer(
                    builder: (ctx, ref, _) => Text(
                      ref.watch(l10nProvider).faceFortuneTilte,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ]),
            ),

            // ── İçerik ────────────────────────────────────────────────────
            Expanded(
              child: _yukleniyor
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
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
      )),
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
              color: AppColors.bone.withValues(alpha: 0.07),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.30), width: 0.8),
            ),
            child: const Center(
              child: Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 38),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Günlük hakkın doldu',
            style: TextStyle(color: AppColors.bone, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Yüz falı günde 1 kez bakılabilir.\nYarın tekrar gel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.bone.withValues(alpha: 0.55), fontSize: 15, height: 1.6),
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
              border: Border.all(color: AppColors.rim, width: 0.8),
            ),
            child: ClipOval(
              child: SizedBox(child: FilmedImage('assets/images/gozbebegi.png', fit: BoxFit.cover)),
            ),
          ),

          const SizedBox(height: 36),

          const Text(
            'Yüz analizini kimin için\nistiyorsun?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.bone,
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
              color: AppColors.bone.withValues(alpha: 0.55),
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 52),

          _KiminButon(
            icon: Icons.person_outline_rounded,
            label: 'Kendim için',
            sublabel: 'Kendi fotoğrafımı analiz et',
            onTap: () => context.push('/yuz_fali_foto', extra: 'kullanici'),
          ),

          const SizedBox(height: 16),

          _KiminButon(
            icon: Icons.people_outline_rounded,
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
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _KiminButon({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OccultListCard(title: label, subtitle: sublabel,
      glyph: (color, size) => Icon(icon, color: color, size: size), onTap: onTap);
  }
}
