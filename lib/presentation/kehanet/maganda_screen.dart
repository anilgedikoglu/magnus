// C:/src/magnus_app/lib/presentation/kehanet/maganda_screen.dart
// Maganda - soru seç, cevap al; cevap ekranında öfkeli renk kaymalı hale animasyonu

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

class MagandaScreen extends ConsumerStatefulWidget {
  const MagandaScreen({super.key});

  @override
  ConsumerState<MagandaScreen> createState() => _MagandaScreenState();
}

enum _MagandaAdim { sorular, cevap }

class _MagandaScreenState extends ConsumerState<MagandaScreen>
    with TickerProviderStateMixin {
  _MagandaAdim _adim = _MagandaAdim.sorular;
  List<Map<String, dynamic>> _sorular = [];
  String _cevap = '';
  String _displayed = '';
  Timer? _typeTimer;
  int _charIndex = 0;
  bool _loading = true;

  // Nefes (parlaklık) — hızlı: 1200ms
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // Renk kayması (öfke döngüsü) — kırmızı→turuncu→sarı→pembe→kırmızı: 2200ms
  late AnimationController _colorCtrl;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();

    // Parlaklık — Faloya'dan daha hızlı (1200ms vs 2800ms)
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    // Renk döngüsü — sürekli forward, 4 aşamalı ateş spektrumu
    _colorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _colorAnim = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFFF2200), // kırmızı
          end:   const Color(0xFFFF7700), // turuncu
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFFF7700), // turuncu
          end:   const Color(0xFFFFDD00), // sarı-turuncu
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFFFDD00), // sarı-turuncu
          end:   const Color(0xFFFF0077), // kızgın pembe
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFFF0077), // kızgın pembe
          end:   const Color(0xFFFF2200), // kırmızıya dön
        ),
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
        _sorular = shuffled
            .take(3)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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

    var eligible =
        cevaplar.where((e) => !shown.contains(e['id'].toString())).toList();
    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown = [];
      eligible = List.from(cevaplar);
    }

    eligible.shuffle(Random());
    final selected = eligible.first;
    final rawMetin = selected['metin'] as String? ?? '';
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

    if (mounted) {
      setState(() {
        _adim = _MagandaAdim.cevap;
        _charIndex = 0;
        _displayed = '';
      });
      _startTypewriter();
    }
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
          final t     = _glowAnim.value;                          // 0→1 parlaklık
          final color = _colorAnim.value ?? const Color(0xFFFF2200);
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              // Çerçeve — renk kayarken opaklık da nefes alır
              border: Border.all(
                color: color.withValues(alpha: 0.30 + t * 0.60),
                width: 1.5,
              ),
              boxShadow: [
                // İç halka — dar, yoğun
                BoxShadow(
                  color: color.withValues(alpha: 0.25 + t * 0.50),
                  blurRadius: 5 + t * 16,
                  spreadRadius: 1 + t * 4,
                ),
                // Dış halo — geniş, yumuşak
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

            // ── İçerik ─────────────────────────────────────────────────────
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF55FF)),
                ),
              )
            else if (_adim == _MagandaAdim.sorular) ...[
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Bir soru seç:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _sorular.length,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => _onSoruSecildi(i),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              const Color(0xFFFF55FF).withValues(alpha: 0.40),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _sorular[i]['metin'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // ── Cevap ekranı: görsel + hale + typewriter ────────────────
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: _buildAngryGlowImage(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFF55FF).withValues(alpha: 0.80),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Kapat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
