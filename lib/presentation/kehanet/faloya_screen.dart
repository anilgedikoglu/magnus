// C:/src/magnus_app/lib/presentation/kehanet/faloya_screen.dart
// Faloya fal ekranı - üstte nefes alan ışık çerçeveli görsel, 5s yükleme, typewriter metin

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/occult_button.dart';
import '../../core/utils/rich_text_parser.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ad_service.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/providers.dart';

class FaloyaScreen extends ConsumerStatefulWidget {
  const FaloyaScreen({super.key});

  @override
  ConsumerState<FaloyaScreen> createState() => _FaloyaScreenState();
}

enum _FaloyaAdim { yukleniyor, icerik }

class _FaloyaScreenState extends ConsumerState<FaloyaScreen>
    with SingleTickerProviderStateMixin {
  _FaloyaAdim _adim = _FaloyaAdim.yukleniyor;
  String _metin = '';
  String _displayed = '';
  Timer? _typeTimer;
  int _charIndex = 0;

  // Nefes alan ışık çerçevesi
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // İkisi de hazır olduğunda geçiş yapılır
  bool _dataReady = false;
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();

    // Nefes çerçeve controller — 2.8s, easeInOut eğrisiyle yavaşça parlar/söner
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _loadData();

    // 3 saniyelik minimum bekleme, sonra rewarded reklam
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _timerDone = true;
      _tryTransition();
    });
  }

  Future<void> _loadData() async {
    final str = await rootBundle.loadString('assets/data/faloya.json');
    final data = jsonDecode(str);
    final List all = data['faloya'] ?? [];

    final prefs = await SharedPreferences.getInstance();
    const key = 'faloya_gosterilen';
    var shown = prefs.getStringList(key) ?? [];

    var eligible = all.where((e) {
      final kosullar = e['kosullar'] as List? ?? [];
      return kosullar.isEmpty && !shown.contains(e['id'].toString());
    }).toList();

    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown = [];
      eligible = all.where((e) {
        final kosullar = e['kosullar'] as List? ?? [];
        return kosullar.isEmpty;
      }).toList();
    }

    eligible.shuffle(Random());
    final selected = eligible.first;
    final isEn = ref.read(localeProvider) == 'en';
    _metin = (isEn && (selected['metin_en'] as String?)?.isNotEmpty == true)
        ? selected['metin_en'] as String
        : (selected['metin'] as String? ?? '');
    final profile = ref.read(userProfileProvider);
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());
    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);

    if (mounted) {
      _dataReady = true;
      _tryTransition();
    }
  }

  void _tryTransition() {
    if (_dataReady && _timerDone && _adim == _FaloyaAdim.yukleniyor) {
      // İkisi de hazır → rewarded reklam, sonra metne geç
      AdService.instance.showRewarded(
        onRewarded: _goIcerik,
        onFailed:   _goIcerik,
      );
    }
  }

  void _goIcerik() {
    if (!mounted || _adim != _FaloyaAdim.yukleniyor) return;
    setState(() => _adim = _FaloyaAdim.icerik);
    _startTypewriter();
  }

  void _startTypewriter() {
    _typeTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (_charIndex >= _metin.length) {
        t.cancel();
        return;
      }
      setState(() {
        _displayed = _metin.substring(0, ++_charIndex);
      });
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Nefes alan çerçeveli görsel ──────────────────────────────────────────────
  Widget _buildGlowImage() {
    return Center(
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          final t = _glowAnim.value; // 0.0 (sönük) → 1.0 (parlak)
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              // İnce ışık çerçevesi — nefesle parlar/söner
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.12 + t * 0.13),
                width: 0.8,
              ),
              boxShadow: [
                // İç halka — yoğun, dar
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.04 + t * 0.08),
                  blurRadius: 6 + t * 6,
                  spreadRadius: t * 3,
                ),
                // Dış halo — geniş, yumuşak
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.02 + t * 0.04),
                  blurRadius: 12 + t * 8,
                  spreadRadius: t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(height: 200, width: 200, child: FilmedImage('assets/images/kehanet/faloya.png', fit: BoxFit.contain)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: GrimoireBackdrop(child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Başlık çubuğu ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.bone),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Faloya',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Nefes alan çerçeveli görsel — her zaman görünür ───────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildGlowImage(),
            ),

            // ── Yükleniyor: orta alan ──────────────────────────────────────
            if (_adim == _FaloyaAdim.yukleniyor) ...[
              const Spacer(),
              Text(
                s.faloyaFocusing,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.boneDim,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: ElegantHourglass(size: 52, color: AppColors.gold),
              ),
              const Spacer(),

            // ── İçerik: typewriter + kapat ─────────────────────────────────
            ] else ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: GlassPanel(variant: GlassVariant.reading, padding: const EdgeInsets.all(18), child: RichTextParser.build(_displayed, style: AppTextStyles.reading)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: OccultButton(label: s.close, onTap: () => context.pop()),
              ),
            ],
          ],
        ),
      )),
    );
  }
}
