// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\KaderKitabı\Tefeul
// JSON:   assets/data/kaderkitabi.json
// Arka plan: assets/images/ozlusoz_bg.png
//
// Metin motoru kuralları:
//   • Koşullu filtreleme (cinsiyet, medeni_durum, meslek, iliski_durumu, yasmin/yasmax)
//   • No-repeat + üst üste aynı metin yasağı
//   • Günlük 1 hak: aynı gün aynı metin
//   • VariableReplacer ile render

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/swipe_back.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../core/widgets/living_sea.dart';
import 'kader_book_scene.dart';
import '../../data/providers.dart';
import '../../data/models/user_profile.dart';

// ─── Logaritmik eğriler ──────────────────────────────────────────────────────

// Yavaş başlar, hızlanır — metin yavaşça açılır

// ─── Model ───────────────────────────────────────────────────────────────────

class _KitapEntry {
  final int id;
  final String metin;
  final String metinEn;
  final List<Map<String, String>> kosullar;
  const _KitapEntry({required this.id, required this.metin, this.metinEn = '', required this.kosullar});
  String metinFor(bool isEn) => (isEn && metinEn.isNotEmpty) ? metinEn : metin;
}

// ─── Ana ekran ───────────────────────────────────────────────────────────────

/// Gece denizi arka planı ve ufkunun yeri (görselin uv.y'si).
const String kKaderSea = 'assets/images/kaderkitabi/deniz.jpg';
const double kKaderSeaHorizon = 0.28;

class KaderKitabiScreen extends ConsumerStatefulWidget {
  const KaderKitabiScreen({super.key});

  @override
  ConsumerState<KaderKitabiScreen> createState() => _KaderKitabiScreenState();
}

class _KaderKitabiScreenState extends ConsumerState<KaderKitabiScreen> {

  static const _prefKeyGosterilen = 'kaderkitabi_gosterilen';
  static const _prefKeyBugunTarih = 'kaderkitabi_bugun_tarih';
  static const _prefKeyBugunId    = 'kaderkitabi_bugun_id';

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
    int? yasMin, yasMax;
    for (final k in kosullar) {
      if (k['degisken'] == 'yasmin') yasMin = int.tryParse(k['deger'] ?? '');
      if (k['degisken'] == 'yasmax') yasMax = int.tryParse(k['deger'] ?? '');
    }
    if (yasMin != null && profile.age < yasMin) return false;
    if (yasMax != null && profile.age > yasMax) return false;

    for (final k in kosullar) {
      final deg = k['degisken'] ?? '';
      if (deg == 'yasmin' || deg == 'yasmax') continue;
      final bek = k['deger'] ?? '';
      final grc = _profileDegeri(deg, profile);
      if (grc != bek) return false;
    }
    return true;
  }

  String _profileDegeri(String deg, UserProfile profile) {
    switch (deg) {
      case 'cinsiyet':      return profile.gender;
      case 'medeni_durum':  return profile.maritalStatus;
      case 'meslek':        return profile.job;
      case 'iliski_durumu':
        const varOlanlar = {'iliski_var','evli','nisanli','karisik','flort','ayri_yasiyor'};
        return varOlanlar.contains(profile.maritalStatus) ? 'var' : 'yok';
      default: return '';
    }
  }

  // ─── Veri yükle ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs    = await SharedPreferences.getInstance();
    final bugunStr = DateTime.now().toIso8601String().substring(0, 10);
    final profile  = ref.read(userProfileProvider);

    final raw      = await rootBundle.loadString('assets/data/kaderkitabi.json');
    final data     = jsonDecode(raw) as Map<String, dynamic>;
    final tumListe = (data['kaderkitabi'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return _KitapEntry(
        id: m['id'] as int,
        metin: m['metin'] as String,
        metinEn: (m['metin_en'] as String?) ?? '',
        kosullar: (m['kosullar'] as List)
            // değerler sayı da olabilir (yasmax: 25) → metne çevir, TypeError yok
            .map((k) => (k as Map).map((a, b) => MapEntry('$a', '${b ?? ''}')))
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

    // No-repeat seçim (üst üste aynı metin yasağı)
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

    // || işaretlerini temizle, değişken değiştir (dile göre)
    final isEn = ref.read(localeProvider) == 'en';
    final rendered = VariableReplacer
        .replace(secilen.metinFor(isEn), profile.toVariableMap())
        .replaceAll(RegExp(r'\s*\|\|\s*'), ' ')
        .trim();

    if (!mounted) return;
    setState(() {
      _metin = rendered;
      _loading = false;
    });
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {

    return SwipeBack(
      onSwipeBack: () => context.pop(),
      child: Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Yaşayan gece denizi (Anıl, 2026-11-06: Hooop'taki gibi dalgalanan koyu deniz).
          const LivingSeaBackground(asset: kKaderSea, horizon: kKaderSeaHorizon, dark: 0.06),
          // Üstte başlık okunsun diye hafif karartma (deniz açık kalır).
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.22, 1.0],
                  colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          // İçerik
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(
                          color: Color(0xFFD4AF37), strokeWidth: 2))
                      : _hakDoldu
                          ? _buildHakDoldu()
                          : _buildContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1),
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
              child: Text(
                ref.watch(l10nProvider).fatebookTitle,
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                  letterSpacing: 4,
                  shadows: const [
                    Shadow(color: Color(0xAAD4AF37), blurRadius: 16),
                  ],
                ),
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
    final s = ref.watch(l10nProvider);
    return Column(children: [
      Expanded(
        child: KaderBookScene(
          leftText: s.fatebookPageRead,
          rightText: s.fatebookTomorrow,
          animate: false,
        ),
      ),
      const FloatingBarSpacer(),
    ]);
  }

  // ─── Metin içeriği ────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final metin = _metin ?? '';
    final scaler = MediaQuery.textScalerOf(context);
    return Column(children: [
      Expanded(
        child: LayoutBuilder(builder: (context, box) {
          final bookW = min(box.maxWidth * 0.94, 560.0);
          final bookH = bookW / kKaderParchmentAspect;
          final page = Size(kKaderLeftPage.width * bookW, kKaderLeftPage.height * bookH);
          final (sol, sag, olcek) = splitKaderPages(metin, page, scaler);
          return KaderBookScene(
            leftText: sol,
            rightText: sag,
            textScale: olcek,
            onTap: metin.isEmpty ? null : () => _yakinOku(metin),
          );
        }),
      ),
      const FloatingBarSpacer(),
    ]);
  }

  /// Kitaba dokununca metin büyük yazıyla, parşömen renginde bir pencerede okunur
  /// (küçük ekranda ve büyük sistem yazısında sayfalar küçük kalıyordu; inceleme bulgusu).
  void _yakinOku(String metin) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (dctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
        child: GestureDetector(
          onTap: () => Navigator.pop(dctx),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(dctx).height * 0.72),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEBD7AE), Color(0xFFD9BC86)],
              ),
              border: Border.all(color: const Color(0xFF6B4A1E), width: 1.2),
              boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24)],
            ),
            child: SingleChildScrollView(
              child: Text(
                metin,
                style: GoogleFonts.raleway(
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A1808),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
