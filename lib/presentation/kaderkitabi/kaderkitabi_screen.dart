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

  // Sayfalama: metin iki sayfaya sığmazsa açılımlara bölünür, dokununca ilerlenir.
  int _spread = 0;
  List<(String, String)>? _spreads;
  Object? _spreadKey;

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

    // Aynı gün → bugünkü sayfa okunmuş. "Okudun" mesajı KİTAPTA gösterilmez; ekran
    // kendini kapatıp 'zaten_okundu' döndürür, ana menü sohbeti söyler (Anıl, 2026-11-06).
    if ((prefs.getString(_prefKeyBugunTarih) ?? '') == bugunStr) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop('zaten_okundu');
      });
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

          // Açılımları hesapla (boyut/metin/yazı ölçeği değişince): metin iki sayfaya
          // sığıyorsa dengeli tek açılım; sığmıyorsa küçültmeden sayfalara böl.
          final key = (metin, bookW.round(), bookH.round(), scaler.scale(16).toStringAsFixed(2));
          if (_spreadKey != key) {
            final (sol, sag, olcek) = splitKaderPages(metin, page, scaler);
            _spreads = olcek >= 0.999
                ? [(sol, sag)]
                : paginateKaderPages(metin, page, scaler);
            _spreadKey = key;
            if (_spread >= _spreads!.length) _spread = 0;
          }
          final spreads = _spreads!;
          final idx = _spread.clamp(0, spreads.length - 1);
          final multi = spreads.length > 1;

          return Stack(children: [
            KaderBookScene(
              leftText: spreads[idx].$1,
              rightText: spreads[idx].$2,
              dropCap: idx == 0,
              showNextArrow: idx < spreads.length - 1,
              // Metin iki sayfaya sığmadıysa dokunuş SONRAKİ açılıma geçer; sığdıysa dokunuş yok.
              onTap: multi
                  ? () {
                      HapticFeedback.selectionClick();
                      setState(() => _spread = (_spread + 1) % spreads.length);
                    }
                  : null,
            ),
            if (multi)
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: IgnorePointer(child: _PageDots(count: spreads.length, active: idx)),
              ),
          ]);
        }),
      ),
      const FloatingBarSpacer(),
    ]);
  }
}

/// Çok açılımlı Kader Kitabı'nda sayfa göstergesi: ince altın noktalar (dokununca ilerler).
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFD4AF37)
                  .withValues(alpha: i == active ? 0.95 : 0.4),
            ),
          ),
      ],
    );
  }
}
