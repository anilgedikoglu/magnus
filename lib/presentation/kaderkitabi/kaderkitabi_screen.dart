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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/swipe_back.dart';
import '../../data/providers.dart';
import '../../data/models/user_profile.dart';

// ─── Logaritmik eğriler ──────────────────────────────────────────────────────

// Yavaş başlar, hızlanır — metin yavaşça açılır
class _SlowRevealCurve extends Curve {
  const _SlowRevealCurve();
  @override
  double transformInternal(double t) => (exp(t) - 1) / (exp(1) - 1);
}

// Hızlı başlar, yavaşlar — karanlık hızla örtüp sakinleşir
class _FastCoverCurve extends Curve {
  const _FastCoverCurve();
  @override
  double transformInternal(double t) => log(1 + t * (exp(1) - 1));
}

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

class KaderKitabiScreen extends ConsumerStatefulWidget {
  const KaderKitabiScreen({super.key});

  @override
  ConsumerState<KaderKitabiScreen> createState() => _KaderKitabiScreenState();
}

class _KaderKitabiScreenState extends ConsumerState<KaderKitabiScreen>
    with SingleTickerProviderStateMixin {

  static const _prefKeyGosterilen = 'kaderkitabi_gosterilen';
  static const _prefKeyBugunTarih = 'kaderkitabi_bugun_tarih';
  static const _prefKeyBugunId    = 'kaderkitabi_bugun_id';

  String? _metin;
  bool    _loading  = true;
  bool    _hakDoldu = false;

  late final AnimationController _mistikCtrl;
  // 0.0 = metin tam görünür, 1.0 = kapkara
  late final Animation<double> _darkOverlay;

  @override
  void initState() {
    super.initState();
    // Toplam döngü: 3s karanlık + 3s açılış + 1s görünür + 3s kapanış = 10s
    _mistikCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _darkOverlay = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0), // 3s kapkara
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: const _SlowRevealCurve())),
        weight: 30, // 3s yavaş açılış
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0), // 1s tam görünür
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: const _FastCoverCurve())),
        weight: 30, // 3s kapanış
      ),
    ]).animate(_mistikCtrl);

    _loadData();
  }

  @override
  void dispose() {
    _mistikCtrl.dispose();
    super.dispose();
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
    _mistikCtrl.repeat(); // animasyon sadece metin hazır olunca başlar
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SwipeBack(
      onSwipeBack: () => context.pop(),
      child: Scaffold(
      backgroundColor: AppColors.ink,
      extendBody: true,
      body: GrimoireBackdrop(
        asset: 'assets/images/ozlusoz_bg.png',
        imageSaturation: 0.22,
        imageBrightness: 0.40, // parşömen karanlık dilde fazla açıktı (0.60)
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(
                        color: AppColors.gold, strokeWidth: 2))
                    : _hakDoldu
                        ? _buildHakDoldu()
                        : _buildContent(context, bottomPad),
              ),
            ],
          ),
        ),
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
                color: AppColors.glassTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.rim, width: 0.9),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.bone,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                ref.watch(l10nProvider).fatebookTitle,
                style: AppTextStyles.screenTitle,
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
        child: GlassPanel(
          variant: GlassVariant.reading,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, color: AppColors.gold, size: 40),
              const SizedBox(height: 16),
              Text(
                ref.watch(l10nProvider).fatebookPageRead,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardLabel.copyWith(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                ref.watch(l10nProvider).fatebookTomorrow,
                textAlign: TextAlign.center,
                style: AppTextStyles.meta.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Metin içeriği ────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, double bottomPad) {
    final metin = _metin ?? '';

    final bookCard = SizedBox(
      width: double.infinity,
      child: GlassPanel(
        variant: GlassVariant.reading,
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichTextParser.build(
              metin,
              textAlign: TextAlign.justify,
              style: AppTextStyles.reading.copyWith(fontSize: 16.5, height: 1.75),
            ),
            const SizedBox(height: 18),
            Container(
              height: 1,
              width: 48,
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );

    final animatedCard = AnimatedBuilder(
      animation: _darkOverlay,
      builder: (_, child) {
        return Stack(
          children: [
            child!,
            if (_darkOverlay.value > 0.001)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: AppColors.ink.withValues(alpha: _darkOverlay.value),
                  ),
                ),
              ),
          ],
        );
      },
      child: bookCard,
    );

    return Column(
      children: [
        // Kitap kartı — dikeyde ortalı, uzunsa kaydırılabilir
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
                child: Center(child: animatedCard),
              ),
            ),
          ),
        ),
        // Geri Git — her zaman altta sabit
        Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad + 16),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 2),
                  Text(
                    ref.read(l10nProvider).backButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
