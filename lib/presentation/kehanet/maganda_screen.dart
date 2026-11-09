// C:/src/magnus_app/lib/presentation/kehanet/maganda_screen.dart
// Maganda - soru seç → 5s odaklanıyor animasyonu → cevap typewriter

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
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
  bool _secimYapildi = false; // hizli cift-dokunus korumasi (tek reklam/tek secim)

  // Parlaklık titremesi — 1200ms hızlı
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // Renk döngüsü — kırmızı→turuncu→sarı→pembe→kırmızı
  late AnimationController _colorCtrl;
  late Animation<Color?> _colorAnim;

  // Cevap gelince Maganda öfkeyle sarsılır (Grok: "cevapta bir silkinme").
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    value: 1,
  );

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
        tween: ColorTween(begin: const Color(0xFFFF2200), end: const Color(0xFFFF7700)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: const Color(0xFFFF7700), end: const Color(0xFFFFDD00)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: const Color(0xFFFFDD00), end: const Color(0xFFFF0077)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: const Color(0xFFFF0077), end: const Color(0xFFFF2200)),
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
    // Soru kartlari, asset/prefs await'leri bitip _adim 'odaklaniyor'a gecene
    // kadar ekranda kalir → bu pencerede ikinci dokunus ikinci reklam acardi.
    if (_secimYapildi) return;
    _secimYapildi = true;

    final secilenSoru = _sorular[index];
    final soruId = '${secilenSoru['id']}';

    final str = await rootBundle.loadString('assets/data/maganda.json');
    final data = jsonDecode(str);
    final isEn = ref.read(localeProvider) == 'en';

    // Yeni model: cevaplar = { "<soruId>": {metinler:[5], metinler_en:[5]} }.
    // Her soruya ait 5 cevaptan biri no-repeat ile seçilir (digerleri bitmeden tekrar yok).
    List<String> varyasyonlar = [];
    final dynamic cevaplarRaw = data['cevaplar'];
    if (cevaplarRaw is Map) {
      final entry = (cevaplarRaw[soruId] ??
          (cevaplarRaw.values.isNotEmpty ? cevaplarRaw.values.first : null));
      if (entry is Map) {
        final tr = (entry['metinler'] as List?)
                ?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ??
            const [];
        final en = (entry['metinler_en'] as List?)
                ?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ??
            const [];
        varyasyonlar = (isEn && en.isNotEmpty) ? en : tr;
        if (varyasyonlar.isEmpty) varyasyonlar = tr;
      }
    } else if (cevaplarRaw is List && cevaplarRaw.isNotEmpty) {
      // Eski/yedek format — herhangi bir cevabı \n\n ile böl.
      final any = cevaplarRaw.first as Map;
      final raw = (isEn ? any['metin_en'] : any['metin']) as String? ??
          (any['metin'] as String? ?? '');
      varyasyonlar =
          raw.split('\n\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    if (varyasyonlar.isEmpty) { _secimYapildi = false; return; }

    final prefs = await SharedPreferences.getInstance();
    final key   = 'maganda_cevap_${soruId}_gosterilen';
    final shown = prefs.getStringList(key) ?? [];
    final idxPool = List.generate(varyasyonlar.length, (i) => i);
    final pick = pickNoRepeat<int>(
        pool: idxPool, shown: shown, idOf: (i) => i.toString());
    final vi = pick?.selected ?? 0;
    if (pick != null) await prefs.setStringList(key, pick.shown);

    final profile = ref.read(userProfileProvider);
    _cevap = VariableReplacer.replace(varyasyonlar[vi], profile.toVariableMap());

    if (!mounted) return;

    // Odaklanıyor adımına geç, kum saatini başlat, 5s sonra metni göster
    setState(() {
      _adim = _MagandaAdim.odaklaniyor;
      _charIndex = 0;
      _displayed = '';
    });

    // 3s bekle → cevap animasyonu
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _goCevap();
    });
  }

  Future<void> _goCevap() async {
    if (!mounted) return;
    await sonucOncesiReklam();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _shakeCtrl.forward(from: 0);
    }
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
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Öfkeli renk kaymalı hale + görsel ───────────────────────────────────────
  Widget _buildAngryGlowImage() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        final v = _shakeCtrl.value;
        final dx = math.sin(v * math.pi * 7) * (1 - v) * 9;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(angle: dx * 0.004, child: child),
        );
      },
      child: _angryGlow(),
    );
  }

  Widget _angryGlow() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnim, _colorAnim]),
        builder: (context, child) {
          final t     = _glowAnim.value;
          final color = _colorAnim.value ?? const Color(0xFFFF2200);
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.30 + t * 0.60),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25 + t * 0.50),
                  blurRadius: 5 + t * 16,
                  spreadRadius: 1 + t * 4,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.08 + t * 0.28),
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
          child: Image.asset(
            'assets/images/kehanet/maganda.png',
            height: 180,
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
            // ── Başlık ─────────────────────────────────────────────────────
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
                      'MAGANDA',
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
                  child: CircularProgressIndicator(color: Color(0xFFFF55FF)),
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
                        Text(
                          s.selectQuestion,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 14),
                        for (int i = 0; i < _sorular.length; i++) ...[
                          GestureDetector(
                            onTap: () => _onSoruSecildi(i),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF55FF).withValues(alpha: 0.40),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                (s.isEn && (_sorular[i]['metin_en'] as String?)?.isNotEmpty == true
                                    ? _sorular[i]['metin_en']
                                    : _sorular[i]['metin']) ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
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
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const FocusRipple(color: Color(0xFFFF4422)),
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
                            Text(
                              _displayed,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Kapat butonu kaldırıldı (Anıl, 2026-11-06; kenardan kaydırarak geri dönülür).
            ],
            const FloatingBarSpacer(),
          ],
        ),
      ),
    );
  }
}
