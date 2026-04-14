// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Ozlusoz\
// JSON:   assets/data/ozlusozler.json
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

class _OzluSozEntry {
  final int id;
  final String metin;
  final String yazar;
  const _OzluSozEntry({required this.id, required this.metin, required this.yazar});
}

class OzluSozScreen extends ConsumerStatefulWidget {
  const OzluSozScreen({super.key});

  @override
  ConsumerState<OzluSozScreen> createState() => _OzluSozScreenState();
}

class _OzluSozScreenState extends ConsumerState<OzluSozScreen>
    with SingleTickerProviderStateMixin {
  static const _prefKeyGosterilen = 'ozlusoz_gosterilen_idler';
  static const _prefKeyBugunTarih = 'ozlusoz_bugun_tarih';

  final _rng = Random();

  _OzluSozEntry? _bugunEntry;
  bool _loading = true;
  bool _hakDoldu = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final bugunStr = DateTime.now().toIso8601String().substring(0, 10);

    // Bugün zaten gösterildi mi?
    final kayitliTarih = prefs.getString(_prefKeyBugunTarih);
    if (kayitliTarih == bugunStr) {
      if (!mounted) return;
      setState(() {
        _hakDoldu = true;
        _loading = false;
      });
      return;
    }

    // JSON yükle
    final jsonStr = await rootBundle.loadString('assets/data/ozlusozler.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tumListe = (data['ozlusozler'] as List<dynamic>)
        .map((e) => _OzluSozEntry(
              id: (e as Map<String, dynamic>)['id'] as int,
              metin: e['metin'] as String,
              yazar: (e['yazar'] as String?) ?? '',
            ))
        .toList();

    // Gösterilen ID'leri yükle
    List<String> gosterilenIdler = prefs.getStringList(_prefKeyGosterilen) ?? [];

    // Gösterilmeyenleri filtrele
    var kalan = tumListe.where((s) => !gosterilenIdler.contains('${s.id}')).toList();

    // Hepsi gösterildiyse sıfırla (üst üste aynı metin yasağı dahil)
    if (kalan.isEmpty) {
      final lastId = gosterilenIdler.isNotEmpty ? gosterilenIdler.last : null;
      gosterilenIdler = lastId != null ? [lastId] : [];
      await prefs.setStringList(_prefKeyGosterilen, gosterilenIdler);
      kalan = tumListe.where((s) => '${s.id}' != lastId).toList();
      if (kalan.isEmpty) kalan = List.from(tumListe);
    }

    // Karıştır ve ilkini seç
    kalan.shuffle(_rng);
    final secilen = kalan.first;

    // Kaydet
    gosterilenIdler.add('${secilen.id}');
    await prefs.setStringList(_prefKeyGosterilen, gosterilenIdler);
    await prefs.setString(_prefKeyBugunTarih, bugunStr);

    if (!mounted) return;
    setState(() {
      _bugunEntry = secilen;
      _loading = false;
    });
    _animCtrl.forward();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Tam ekran arka plan ────────────────────────────────────────────
          Image.asset(
            'assets/images/ozluSozIntroBg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF0D0A20)),
          ),
          // ── Koyu overlay — %50 ─────────────────────────────────────────
          Container(color: Colors.black.withValues(alpha: 0.50)),
          // ── İçerik ────────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFBB88FF),
                            strokeWidth: 2,
                          ),
                        )
                      : _hakDoldu
                          ? _buildHakDoldu()
                          : FadeTransition(
                              opacity: _fadeAnim,
                              child: SlideTransition(
                                position: _slideAnim,
                                child: _buildContent(),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Başlık ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          // Başlık
          Expanded(
            child: Center(
              child: Text(
                'ÖZLÜ SÖZLER',
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 5,
                  shadows: const [
                    Shadow(color: Color(0xAABB88FF), blurRadius: 14),
                  ],
                ),
              ),
            ),
          ),
          // Simetri
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ─── Hak doldu ────────────────────────────────────────────────────────────────

  Widget _buildHakDoldu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF7B5CE8).withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📖', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              const Text(
                'Günlük özlü söz hakkın doldu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yarın yeni bir söz seni bekliyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── İçerik ───────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    final entry = _bugunEntry;
    if (entry == null) return const SizedBox.shrink();

    final resolvedMetin = VariableReplacer.replace(
      entry.metin,
      ref.read(userProfileProvider).toVariableMap(),
    );

    const accent = Color(0xFFBB88FF);

    return Center(
      child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Alıntı kartı ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Açılış tırnağı
                Text(
                  '❝',
                  style: TextStyle(
                    fontSize: 38,
                    color: accent.withValues(alpha: 0.75),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 14),
                // Metin
                Text(
                  resolvedMetin,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: resolvedMetin.length > 200 ? 15 : 17,
                    height: 1.75,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6),
                    ],
                  ),
                ),
                // Kapanış tırnağı
                Text(
                  '❞',
                  style: TextStyle(
                    fontSize: 38,
                    color: accent.withValues(alpha: 0.75),
                    height: 1,
                  ),
                ),
                // Yazar
                if (entry.yazar.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: accent.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '— ${entry.yazar}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: accent.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
