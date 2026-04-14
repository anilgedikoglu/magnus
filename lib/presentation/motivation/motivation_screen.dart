// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Motivasyon\Motivasyonlar\
// JSON:   assets/data/motivasyonlar.json
// Arka plan: assets/images/bgkazan1.jpeg ve bgkazan2.jpeg (sırayla değişir)
//
// ⚠️ METIN MOTORU NOTU: Unity .asset dosyalarında `aciklama:` bir YAML listesidir.
// Tek dosyada birden fazla `- "..."` maddesi olabilir → her biri ayrı JSON girdisi!
// Bu klasörde birden fazla madde içeren dosyalar tespit edildi.
// JSON yeniden üretilirken extract_all_aciklama() tipi bir parser kullan.
// Bkz. CLAUDE.md → "Kaynak Yapısı" bölümü.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// ── Motivasyon Metinleri ──────────────────────────────────────────────────────
// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Motivasyon\Motivasyonlar\
// Her .asset dosyasındaki Türkçe "aciklama" alanından derlendi.
// gerekliDegiskenler: sadece "mod: motivasyon" içeriyor → kosullar: [] (herkese açık)
// Günlük limit: 1. Tüm metinler gösterilince liste sıfırlanır.

class _MotivasyonEntry {
  final int id;
  final String metin;
  const _MotivasyonEntry({required this.id, required this.metin});
}

class MotivationScreen extends ConsumerStatefulWidget {
  const MotivationScreen({super.key});

  @override
  ConsumerState<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends ConsumerState<MotivationScreen>
    with SingleTickerProviderStateMixin {
  static const _prefKeyGosterilen = 'motivasyon_gosterilen_idler';
  static const _prefKeyBugunTarih = 'motivasyon_bugun_tarih';
  static const _prefKeyBugunId    = 'motivasyon_bugun_id';
  static const _prefKeyBgIndex    = 'motivasyon_bg_index'; // 0 veya 1, sırayla değişir

  static const List<String> _bgFiles = [
    'assets/images/bgkazan1.jpeg',
    'assets/images/bgkazan2.jpeg',
  ];

  final _rng = Random();

  _MotivasyonEntry? _bugunEntry;
  String? _bgPath;
  bool _loading = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs    = await SharedPreferences.getInstance();
    final bugunStr = DateTime.now().toIso8601String().substring(0, 10);

    // JSON yükle
    final jsonStr = await rootBundle.loadString('assets/data/motivasyonlar.json');
    final data    = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tumListe = (data['motivasyonlar'] as List<dynamic>)
        .map((e) => _MotivasyonEntry(
              id: (e as Map<String, dynamic>)['id'] as int,
              metin: e['metin'] as String,
            ))
        .toList();

    // ── Metin seç (no-repeat) ─────────────────────────────────────────────
    final bugunKayitliTarih = prefs.getString(_prefKeyBugunTarih) ?? '';
    final bugunKayitliId    = prefs.getInt(_prefKeyBugunId);

    _MotivasyonEntry secilen;

    if (bugunKayitliTarih == bugunStr && bugunKayitliId != null) {
      // Aynı gün — cache'ten yükle
      secilen = tumListe.firstWhere(
        (m) => m.id == bugunKayitliId,
        orElse: () => tumListe.first,
      );
    } else {
      // Yeni gün — no-repeat mantığı (üst üste aynı metin yasağı dahil)
      List<String> gosterilenIdler = prefs.getStringList(_prefKeyGosterilen) ?? [];
      var kalan = tumListe.where((m) => !gosterilenIdler.contains('${m.id}')).toList();
      if (kalan.isEmpty) {
        final lastId = gosterilenIdler.isNotEmpty ? gosterilenIdler.last : null;
        gosterilenIdler = lastId != null ? [lastId] : [];
        await prefs.setStringList(_prefKeyGosterilen, gosterilenIdler);
        kalan = tumListe.where((m) => '${m.id}' != lastId).toList();
        if (kalan.isEmpty) kalan = List.from(tumListe);
      }
      kalan.shuffle(_rng);
      secilen = kalan.first;
      gosterilenIdler.add('${secilen.id}');
      await prefs.setStringList(_prefKeyGosterilen, gosterilenIdler);
      await prefs.setString(_prefKeyBugunTarih, bugunStr);
      await prefs.setInt(_prefKeyBugunId, secilen.id);
    }

    // ── Arka plan seç (sırayla değişir) ──────────────────────────────────
    final lastBg  = prefs.getInt(_prefKeyBgIndex) ?? 0;
    final bgIndex = (lastBg + 1) % _bgFiles.length;
    await prefs.setInt(_prefKeyBgIndex, bgIndex);

    if (!mounted) return;
    setState(() {
      _bugunEntry = secilen;
      _bgPath     = _bgFiles[bgIndex];
      _loading    = false;
    });
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Arka plan ────────────────────────────────────────────────────
          if (_bgPath != null)
            Image.asset(
              _bgPath!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0D0A20)),
            ),
          // ── Koyu overlay ─────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xAA000000), // üst %67
                  Color(0x44000000), // orta %27
                  Color(0xAA000000), // alt %67
                ],
              ),
            ),
          ),
          // ── İçerik ───────────────────────────────────────────────────────
          _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFBB88FF),
                    strokeWidth: 2,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildContent(topPad, bottomPad),
                ),
        ],
      ),
    );
  }

  Widget _buildContent(double topPad, double bottomPad) {
    final entry = _bugunEntry;
    if (entry == null) return const SizedBox.shrink();

    final profile = ref.read(userProfileProvider);
    final text    = VariableReplacer.replace(entry.metin, profile.toVariableMap());

    return Column(
      children: [
        // ── Başlık ─────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(12, topPad + 10, 12, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25), width: 1),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'MOTİVASYON',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: const [
                        Shadow(color: Color(0xAABB88FF), blurRadius: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
        ),
        // ── Metin ──────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('💫', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 20),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: text.length > 300 ? 13 : (text.length > 150 ? 15 : 17),
                      height: 1.75,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
