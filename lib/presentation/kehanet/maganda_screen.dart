// C:/src/magnus_app/lib/presentation/kehanet/maganda_screen.dart
// Maganda - soru seç → 5s odaklanıyor animasyonu → cevap typewriter

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/occult_button.dart';
import '../../core/widgets/occult_cards.dart';
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

class MagandaScreen extends ConsumerStatefulWidget {
  const MagandaScreen({super.key});

  @override
  ConsumerState<MagandaScreen> createState() => _MagandaScreenState();
}

enum _MagandaAdim { sorular, odaklaniyor, cevap }

class _MagandaScreenState extends ConsumerState<MagandaScreen>
    with TickerProviderStateMixin {
  _MagandaAdim _adim = _MagandaAdim.sorular;
  List<Map<String, dynamic>> _sorular = [];
  String _cevap = '';
  String _displayed = '';
  Timer? _typeTimer;
  int _charIndex = 0;
  bool _loading = true;

  // Parlaklık titremesi — 1200ms hızlı
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // Renk döngüsü — kırmızı→turuncu→sarı→pembe→kırmızı
  late AnimationController _colorCtrl;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _colorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _colorAnim = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.gold, end: AppColors.gold),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.gold, end: AppColors.gold),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.gold, end: AppColors.gold),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.gold, end: AppColors.gold),
        weight: 25,
      ),
    ]).animate(_colorCtrl);

    _loadData();
  }


  Future<void> _loadData() async {
    final str = await rootBundle.loadString('assets/data/maganda.json');
    final data = jsonDecode(str);
    final List all = data['sorular'] ?? [];
    final shuffled = List.from(all)..shuffle(Random());
    if (mounted) {
      setState(() {
        _sorular = shuffled.take(3).map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    }
  }

  Future<void> _onSoruSecildi(int index) async {
    final str = await rootBundle.loadString('assets/data/maganda.json');
    final data = jsonDecode(str);
    final List cevaplar = data['cevaplar'] ?? [];

    final prefs = await SharedPreferences.getInstance();
    const key = 'maganda_gosterilen';
    var shown = prefs.getStringList(key) ?? [];

    var eligible = cevaplar.where((e) => !shown.contains(e['id'].toString())).toList();
    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown = [];
      eligible = List.from(cevaplar);
    }

    eligible.shuffle(Random());
    final selected = eligible.first;
    final isEn = ref.read(localeProvider) == 'en';
    final rawMetin = (isEn && (selected['metin_en'] as String?)?.isNotEmpty == true)
        ? selected['metin_en'] as String
        : (selected['metin'] as String? ?? '');
    final varyasyonlar = rawMetin
        .split('\n\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    varyasyonlar.shuffle(Random());
    _cevap = varyasyonlar.isNotEmpty ? varyasyonlar.first : rawMetin;
    final profile = ref.read(userProfileProvider);
    _cevap = VariableReplacer.replace(_cevap, profile.toVariableMap());
    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);

    if (!mounted) return;

    // Odaklanıyor adımına geç, kum saatini başlat, 5s sonra metni göster
    setState(() {
      _adim = _MagandaAdim.odaklaniyor;
      _charIndex = 0;
      _displayed = '';
    });

    // 3s bekle → rewarded reklam → cevap animasyonu
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      AdService.instance.showRewarded(
        onRewarded: _goCevap,
        onFailed:   _goCevap,
      );
    });
  }

  void _goCevap() {
    if (!mounted) return;
    setState(() => _adim = _MagandaAdim.cevap);
    _startTypewriter();
  }

  void _startTypewriter() {
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (_charIndex >= _cevap.length) {
        t.cancel();
        return;
      }
      setState(() {
        _displayed = _cevap.substring(0, ++_charIndex);
      });
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _glowCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  // ── Öfkeli renk kaymalı hale + görsel ───────────────────────────────────────
  Widget _buildAngryGlowImage() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnim, _colorAnim]),
        builder: (context, child) {
          final t     = _glowAnim.value;
          final color = _colorAnim.value ?? AppColors.gold;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.12 + t * 0.13),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 5 + t * 16,
                  spreadRadius: 1 + t * 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14 + t * 26,
                  spreadRadius: t * 7,
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(height: 180, width: 180, child: FilmedImage('assets/images/kehanet/maganda.png', fit: BoxFit.contain)),
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
            // ── Başlık ─────────────────────────────────────────────────────
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
                      'Maganda',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Görsel — yükleme bitmeden gizli, sonra her adımda görünür ─
            if (!_loading)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: _buildAngryGlowImage(),
              ),

            // ── İçerik ─────────────────────────────────────────────────────
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )

            // ── Soru seçimi — dikeyde ortalanmış ──────────────────────────
            else if (_adim == _MagandaAdim.sorular)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OccultSectionLabel(s.selectQuestion),
                        const SizedBox(height: 14),
                        for (int i = 0; i < _sorular.length; i++) ...[
                          OccultListCard(
                            title: ((s.isEn && (_sorular[i]['metin_en'] as String?)?.isNotEmpty == true
                                    ? _sorular[i]['metin_en']
                                    : _sorular[i]['metin']) as String?) ?? '',
                            glyph: (color, size) => Icon(Icons.help_outline_rounded, color: color, size: size),
                            onTap: () => _onSoruSecildi(i),
                          ),
                          if (i < _sorular.length - 1) const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              )

            // ── Odaklanıyor — kum saati + yazı dikeyde ortalanmış ──────────
            else if (_adim == _MagandaAdim.odaklaniyor)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.magandaFocusing,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.boneDim,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const ElegantHourglass(size: 52, color: AppColors.gold),
                    ],
                  ),
                ),
              )

            // ── Cevap — typewriter dikeyde ortalanmış + kapat ─────────────
            else ...[
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GlassPanel(variant: GlassVariant.reading, padding: const EdgeInsets.all(18), child: RichTextParser.build(_displayed, style: AppTextStyles.reading)),
                          ],
                        ),
                      ),
                    );
                  },
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
