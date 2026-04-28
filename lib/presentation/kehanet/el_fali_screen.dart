// lib/presentation/kehanet/el_fali_screen.dart
// El Falı — fotoğraf çekme/seçme, el analizi ve fal ekranı.
// Kaynak metinler: assets/data/elfali.json

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/providers.dart';
import '../../data/services/claude_vision_service.dart';

enum _EFAdim { secim, analiz, hatali, sonuc }

class ElFaliScreen extends ConsumerStatefulWidget {
  const ElFaliScreen({super.key});

  @override
  ConsumerState<ElFaliScreen> createState() => _ElFaliScreenState();
}

class _ElFaliScreenState extends ConsumerState<ElFaliScreen>
    with SingleTickerProviderStateMixin {
  _EFAdim _adim = _EFAdim.secim;
  File?   _foto;
  String  _hataMetni = '';

  // Parsed result
  String _genelMetin = '';
  List<Map<String, dynamic>> _hatlar = [];

  // Kum saati animasyonu
  late AnimationController _hourCtrl;
  late Animation<double>   _hourAnim;

  @override
  void initState() {
    super.initState();
    _hourCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _hourAnim = CurvedAnimation(parent: _hourCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    super.dispose();
  }

  // ── Fotoğraf seç / çek ────────────────────────────────────────────────────
  Future<void> _secimiYap(ImageSource source) async {
    try {
      final xFile = await ImagePicker().pickImage(
        source:       source,
        maxWidth:     512,
        maxHeight:    512,
        imageQuality: 75,
      );
      if (xFile == null || !mounted) return;

      setState(() {
        _foto = File(xFile.path);
        _adim = _EFAdim.analiz;
      });

      await _analizEt();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hataMetni = 'Fotoğraf alınamadı. Lütfen tekrar dene.';
          _adim      = _EFAdim.hatali;
        });
      }
    }
  }

  // ── Analiz + fal üretimi ──────────────────────────────────────────────────
  Future<void> _analizEt() async {
    try {
      final sonuclar = await Future.wait<dynamic>([
        ClaudeVisionServiceElFali.elFaliAnaliz(_foto!.path),
        Future.delayed(const Duration(seconds: 5)),
      ]);

      if (!mounted) return;

      final analiz = sonuclar[0] as ElAnalizi;

      if (!analiz.isHand) {
        setState(() {
          _hataMetni = 'Lütfen avucunu kameraya göster ve tekrar dene.';
          _adim      = _EFAdim.hatali;
        });
        return;
      }

      // Fal üret
      final fortuneService = ref.read(fortuneServiceProvider);
      final profile        = ref.read(userProfileProvider);
      final item           = await fortuneService.generateElFali(profile: profile);

      // Inbox'a kaydet
      await ref.read(inboxProvider.notifier).addItem(item);

      // Sonucu parse et (gösterim için)
      final data    = jsonDecode(item.text) as Map<String, dynamic>;
      _genelMetin   = data['genel'] as String? ?? '';
      _hatlar       = (data['hatlar'] as List)
          .map((h) => h as Map<String, dynamic>)
          .toList();

      if (mounted) setState(() => _adim = _EFAdim.sonuc);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hataMetni = 'Analiz sırasında bir hata oluştu. İnternet bağlantını kontrol et.';
          _adim      = _EFAdim.hatali;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060812),
      body: SafeArea(
        child: Column(
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    'EL FALI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ]),
            ),

            Expanded(
              child: switch (_adim) {
                _EFAdim.secim  => _buildSecim(),
                _EFAdim.analiz => _buildAnaliz(),
                _EFAdim.hatali => _buildHatali(),
                _EFAdim.sonuc  => _buildSonuc(),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Ortak fotoğraf alanı ──────────────────────────────────────────────────
  Widget _buildFotoAlan({double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.40),
          width: 1.5,
        ),
        color: const Color(0xFF0D0A1E),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: _foto != null
            ? Image.file(_foto!, fit: BoxFit.cover)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.back_hand_rounded,
                      color: Colors.white.withValues(alpha: 0.18),
                      size: 80,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Avucunu göster',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.28),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Durum: secim ─────────────────────────────────────────────────────────
  Widget _buildSecim() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Avucunu kameraya aç, çizgiler net görünsün.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB8A8D8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _buildFotoAlan(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Expanded(
                child: _FotoButon(
                  icon: Icons.camera_alt_rounded,
                  label: 'Fotoğraf Çek',
                  onTap: () => _secimiYap(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FotoButon(
                  icon: Icons.photo_library_rounded,
                  label: 'Telefondan Seç',
                  onTap: () => _secimiYap(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Durum: analiz ─────────────────────────────────────────────────────────
  Widget _buildAnaliz() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: _buildFotoAlan(),
          ),
        ),
        const Spacer(),
        const Text(
          'El çizgilerin okunuyor...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _hourAnim,
          builder: (ctx, _) => Transform.scale(
            scale: 0.88 + 0.12 * _hourAnim.value,
            child: Opacity(
              opacity: 0.65 + 0.35 * _hourAnim.value,
              child: const Text('🔮', style: TextStyle(fontSize: 52)),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ── Durum: hatali ─────────────────────────────────────────────────────────
  Widget _buildHatali() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 24),
          Text(
            _hataMetni,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          _buildGradientButton(
            label: 'Tekrar Dene',
            onTap: () => setState(() {
              _foto      = null;
              _hataMetni = '';
              _adim      = _EFAdim.secim;
            }),
          ),
        ],
      ),
    );
  }

  // ── Durum: sonuc ─────────────────────────────────────────────────────────
  Widget _buildSonuc() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genel değerlendirme
                if (_genelMetin.isNotEmpty) ...[
                  const Text(
                    'Genel Değerlendirme',
                    style: TextStyle(
                      color: Color(0xFFD8B4FE),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _genelMetin,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.75,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                ],
                // Hatlar
                ..._hatlar.map((hat) => _buildHatRow(hat)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              const Text(
                'El falın gelen kutuna kaydedildi.',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildGradientButton(
                label: 'Kapat',
                onTap: () => context.pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHatRow(Map<String, dynamic> hat) {
    final ad    = hat['ad'] as String;
    final renk  = hat['renk'] as String;
    final yuzde = hat['yuzde'] as int;
    final metin = hat['metin'] as String;
    final color = _hatRengi(renk);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hat adı + yüzde
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ad,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '%$yuzde',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: yuzde / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          // Açıklama metni
          Text(
            metin,
            style: const TextStyle(
              color: Color(0xFFE2D9F3),
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  static Color _hatRengi(String renk) {
    switch (renk.toLowerCase()) {
      case 'red':        return const Color(0xFFEF4444);
      case 'darkgreen':  return const Color(0xFF22C55E);
      case 'green':      return const Color(0xFF4ADE80);
      case 'blue':       return const Color(0xFF60A5FA);
      case 'orange':     return const Color(0xFFFB923C);
      case 'brown':      return const Color(0xFFD97706);
      case 'yellow':     return const Color(0xFFFBBF24);
      case 'pink':       return const Color(0xFFF472B6);
      case 'magenta':    return const Color(0xFFA855F7);
      case 'cyan':       return const Color(0xFF22D3EE);
      default:           return const Color(0xFF818CF8);
    }
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.80),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fotoğraf seçim butonu ─────────────────────────────────────────────────────
class _FotoButon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FotoButon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1035), Color(0xFF2A1A55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
