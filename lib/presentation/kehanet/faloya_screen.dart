// C:/src/magnus_app/lib/presentation/kehanet/faloya_screen.dart
// Faloya fal ekranı - üstte nefes alan ışık çerçeveli görsel, 5s yükleme, typewriter metin

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/sonuc_reklami.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/utils/no_repeat_picker.dart';
import '../../core/widgets/focus_ripple.dart';
import '../../core/widgets/floating_bar_spacer.dart';
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
    final shown = prefs.getStringList(key) ?? [];

    // Yalnız koşulsuz metinler (Faloya herkese aynı havuzdan okur).
    final pool =
        all.where((e) => (e['kosullar'] as List? ?? []).isEmpty).toList();
    final pick =
        pickNoRepeat(pool: pool, shown: shown, idOf: (e) => e['id'].toString());
    if (pick == null) return;
    final selected = pick.selected;
    await prefs.setStringList(key, pick.shown);

    final isEn = ref.read(localeProvider) == 'en';
    _metin = (isEn && (selected['metin_en'] as String?)?.isNotEmpty == true)
        ? selected['metin_en'] as String
        : (selected['metin'] as String? ?? '');
    final profile = ref.read(userProfileProvider);
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());

    if (mounted) {
      _dataReady = true;
      _tryTransition();
    }
  }

  void _tryTransition() {
    if (_dataReady && _timerDone && _adim == _FaloyaAdim.yukleniyor) {
      // İkisi de hazır → metne geç
      _goIcerik();
    }
  }

  bool _gecis = false;

  Future<void> _goIcerik() async {
    if (!mounted || _adim != _FaloyaAdim.yukleniyor || _gecis) return;
    _gecis = true;
    await sonucOncesiReklam();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
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
                color: const Color(0xFFFF55FF).withValues(alpha: 0.25 + t * 0.55),
                width: 1.5,
              ),
              boxShadow: [
                // İç halka — yoğun, dar
                BoxShadow(
                  color: const Color(0xFFFF55FF).withValues(alpha: 0.20 + t * 0.45),
                  blurRadius: 6 + t * 14,
                  spreadRadius: t * 3,
                ),
                // Dış halo — geniş, yumuşak
                BoxShadow(
                  color: const Color(0xFF9B00D3).withValues(alpha: 0.10 + t * 0.30),
                  blurRadius: 18 + t * 28,
                  spreadRadius: t * 6,
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/kehanet/faloya.png',
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Başlık çubuğu ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'FALOYA',
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
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: FocusRipple(color: Color(0xFFFF55FF)),
              ),
              const Spacer(),

            // ── İçerik: typewriter (Kapat butonu kaldırıldı — Anıl, 2026-11-06; kenardan
            //    kaydırarak geri dönülür) ──────────────────────────────────────────
            ] else ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Text(
                    _displayed,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ],
            const FloatingBarSpacer(),
          ],
        ),
      ),
    );
  }
}
