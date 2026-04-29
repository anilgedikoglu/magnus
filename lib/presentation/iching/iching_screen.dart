// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\IChing\Metinler
// JSON:   assets/data/iching.json
// Arka plan: assets/images/falbg/ichingbg.png
//
// Metin motoru kuralları:
//   • No-repeat + üst üste aynı metin yasağı
//   • Günlük 1 hak: aynı gün aynı metin
//   • VariableReplacer ile {{isim}} değişimi

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';
import '../../data/models/user_profile.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class _IChingEntry {
  final int id;
  final String metin;
  final List<Map<String, String>> kosullar;
  const _IChingEntry({required this.id, required this.metin, required this.kosullar});
}

// ─── Ana ekran ───────────────────────────────────────────────────────────────

class IChingScreen extends ConsumerStatefulWidget {
  const IChingScreen({super.key});

  @override
  ConsumerState<IChingScreen> createState() => _IChingScreenState();
}

class _IChingScreenState extends ConsumerState<IChingScreen> {

  static const _prefKeyGosterilen = 'iching_gosterilen';
  static const _prefKeyBugunTarih = 'iching_bugun_tarih';
  static const _prefKeyBugunId    = 'iching_bugun_id';

  String? _metin;
  bool    _loading  = true;
  bool    _hakDoldu = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── Koşul eşleştirme ────────────────────────────────────────────────────

  bool _tumKosullarUygun(List<Map<String, String>> kosullar, UserProfile profile) {
    if (kosullar.isEmpty) return true;
    for (final k in kosullar) {
      final deg = k['degisken'] ?? '';
      final bek = k['deger'] ?? '';
      final grc = _profileDegeri(deg, profile);
      if (grc != bek) return false;
    }
    return true;
  }

  String _profileDegeri(String deg, UserProfile profile) {
    switch (deg) {
      case 'cinsiyet':     return profile.gender;
      case 'medeni_durum': return profile.maritalStatus;
      case 'meslek':       return profile.job;
      default:             return '';
    }
  }

  // ─── Veri yükle ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs    = await SharedPreferences.getInstance();
    final bugunStr = DateTime.now().toIso8601String().substring(0, 10);
    final profile  = ref.read(userProfileProvider);

    final raw  = await rootBundle.loadString('assets/data/iching.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final tumListe = (data['iching'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return _IChingEntry(
        id: m['id'] as int,
        metin: m['metin'] as String,
        kosullar: (m['kosullar'] as List)
            .map((k) => Map<String, String>.from(k as Map))
            .toList(),
      );
    }).toList();

    final uygunListe = tumListe.where((e) => _tumKosullarUygun(e.kosullar, profile)).toList();

    // Aynı gün → hak doldu
    if ((prefs.getString(_prefKeyBugunTarih) ?? '') == bugunStr) {
      if (!mounted) return;
      setState(() { _hakDoldu = true; _loading = false; });
      return;
    }

    // No-repeat seçim
    List<String> gosterilen = prefs.getStringList(_prefKeyGosterilen) ?? [];
    var kalan = uygunListe.where((e) => !gosterilen.contains('${e.id}')).toList();

    if (kalan.isEmpty) {
      final lastId = gosterilen.isNotEmpty ? gosterilen.last : null;
      gosterilen = lastId != null ? [lastId] : [];
      await prefs.setStringList(_prefKeyGosterilen, gosterilen);
      kalan = uygunListe.where((e) => '${e.id}' != lastId).toList();
      if (kalan.isEmpty) kalan = List.from(uygunListe);
    }

    kalan.shuffle(Random());
    final secilen = kalan.first;
    gosterilen.add('${secilen.id}');
    await prefs.setStringList(_prefKeyGosterilen, gosterilen);
    await prefs.setString(_prefKeyBugunTarih, bugunStr);
    await prefs.setInt(_prefKeyBugunId, secilen.id);

    final rendered = VariableReplacer.replace(secilen.metin, profile.toVariableMap());

    if (!mounted) return;
    setState(() { _metin = rendered; _loading = false; });
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/falbg/ichingbg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050A0F)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBB000000),
                  Color(0x44000000),
                  Color(0xBB000000),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(
                          color: Color(0xFFB8941F), strokeWidth: 2))
                      : _hakDoldu
                          ? _buildHakDoldu()
                          : _buildContent(bottomPad),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Başlık ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFB8941F).withValues(alpha: 0.5), width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFD4AF37),
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/ichingikonlogo.png',
                    height: 28,
                    width: 28,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'I-CHING',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD4AF37),
                      letterSpacing: 5,
                      shadows: const [
                        Shadow(color: Color(0xAAD4AF37), blurRadius: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ─── Hak Doldu ───────────────────────────────────────────────────────────

  Widget _buildHakDoldu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1020).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('☯', style: TextStyle(fontSize: 44, color: Color(0xFFD4AF37))),
              const SizedBox(height: 16),
              Text(
                'I-Ching bugün sana\nsöyleyeceklerini söyledi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 15,
                  color: const Color(0xFFD4AF37),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Yarın yeni bir heksagram seni bekliyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Metin içeriği ────────────────────────────────────────────────────────

  Widget _buildContent(double bottomPad) {
    final metin = _metin ?? '';
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 28),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF080E18).withValues(alpha: 0.88),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Üst süsleme çizgisi
            Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4AF37).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Text(
                metin,
                style: const TextStyle(
                  color: Color(0xFFE8E0D0),
                  fontSize: 14.5,
                  height: 1.9,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.15,
                ),
              ),
            ),
            // Alt süsleme çizgisi
            Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4AF37).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '☯',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
