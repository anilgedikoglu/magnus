// Kaynak: assets/data/dertortagi.json
// Akış: Kategori → Dert seçimi → Kum saati (5sn) → Derman (tavsiye)
// Günlük limit  : günde 1 kez  (dertortagi_bugun_tarih)
// Günlük seçim  : aynı gün aynı kategoride hep aynı 6 dert (dertortagi_gunluk_<k>_<tarih>)
// Tekrar gösterilmeme: kategori bazlı, farklı günlerde yeni sorular (dertortagi_gosterilen_<k>)
// Koşul filtrelemesi: cinsiyet, medeni_durum, meslek

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/occult_glyphs.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/occult_button.dart';
import '../../core/widgets/occult_cards.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../core/widgets/swipe_back.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

enum _DertAdim { kategori, dert, yukleniyor, derman }

class DertOrtagiScreen extends ConsumerStatefulWidget {
  const DertOrtagiScreen({super.key});

  @override
  ConsumerState<DertOrtagiScreen> createState() => _DertOrtagiScreenState();
}

class _DertOrtagiScreenState extends ConsumerState<DertOrtagiScreen>
    with TickerProviderStateMixin {
  // ── Pref anahtarları ────────────────────────────────────────────────────────
  static const _prefBugun = 'dertortagi_bugun_tarih';
  static const _prefGosterilen = 'dertortagi_gosterilen_'; // + kategori
  static const _prefGunluk = 'dertortagi_gunluk_'; // + kategori_tarih

  // ── Durum ───────────────────────────────────────────────────────────────────
  _DertAdim _adim = _DertAdim.kategori;
  String _seciliKategori = '';
  Map<String, dynamic>? _seciliDert;
  bool _limitDoldu = false;
  bool _ilkYukleme = true;

  Map<String, List<Map<String, dynamic>>> _tumDertler = {};
  List<Map<String, dynamic>> _gosterilenDertler = [];

  // ── Animasyon ───────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  Timer? _gecisTimer;

  String get _bugun => DateTime.now().toIso8601String().substring(0, 10);

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _gecisTimer?.cancel();
    super.dispose();
  }

  // ── Veri yükleme ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_prefBugun) == _bugun) {
      if (mounted)
        setState(() {
          _limitDoldu = true;
          _ilkYukleme = false;
        });
      return;
    }
    final jsonStr = await rootBundle.loadString('assets/data/dertortagi.json');
    final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = raw['dertler'] as Map<String, dynamic>;

    final tumDertler = <String, List<Map<String, dynamic>>>{};
    for (final k in ['genel', 'ask', 'saglik', 'kariyer']) {
      tumDertler[k] =
          (data[k] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    }
    if (mounted) {
      setState(() {
        _tumDertler = tumDertler;
        _ilkYukleme = false;
      });
      _fadeCtrl.forward();
    }
  }

  // ── Koşul filtresi ───────────────────────────────────────────────────────────

  bool _kosullarUygun(List<dynamic> kosullar, UserProfile profile) {
    if (kosullar.isEmpty) return true;
    for (final k in kosullar) {
      final m = k as Map;
      if (_profilDegeri(m['degisken'] as String? ?? '', profile) !=
          (m['deger'] as String? ?? '')) {
        return false;
      }
    }
    return true;
  }

  String _profilDegeri(String deg, UserProfile p) {
    switch (deg) {
      case 'cinsiyet':
        return p.gender;
      case 'medeni_durum':
        return p.maritalStatus;
      case 'meslek':
        return p.job;
      default:
        return '';
    }
  }

  // ── Kategori seçildi ─────────────────────────────────────────────────────────
  // Aynı gün aynı kategoride hep aynı dertler gösterilir.

  Future<void> _kategoriSec(String kategori) async {
    final profile = ref.read(userProfileProvider);
    final prefs = await SharedPreferences.getInstance();
    final gunlukKey = '$_prefGunluk${kategori}_$_bugun';

    List<Map<String, dynamic>> secilen;

    // Bugün bu kategori için seçim yapıldı mı?
    final savedIds = prefs.getStringList(gunlukKey);
    if (savedIds != null && savedIds.isNotEmpty) {
      final tumK = _tumDertler[kategori] ?? [];
      secilen =
          savedIds
              .map(
                (id) => tumK.firstWhere(
                  (d) => d['id'] == id,
                  orElse: () => <String, dynamic>{},
                ),
              )
              .where((d) => d.isNotEmpty)
              .toList();
    } else {
      // Yeni seçim yap
      final uygunlar =
          (_tumDertler[kategori] ?? [])
              .where(
                (d) => _kosullarUygun(d['kosullar'] as List<dynamic>, profile),
              )
              .toList();

      if (uygunlar.isEmpty) {
        secilen = [];
      } else {
        // Tekrar gösterilmeme
        final gostKey = '$_prefGosterilen$kategori';
        List<String> gostIds = prefs.getStringList(gostKey) ?? [];
        List<Map<String, dynamic>> havuz =
            uygunlar
                .where((d) => !gostIds.contains(d['id'] as String))
                .toList();

        if (havuz.isEmpty) {
          await prefs.remove(gostKey);
          havuz = List.from(uygunlar);
        }

        havuz.shuffle(Random());
        secilen = havuz.take(havuz.length.clamp(1, 6)).toList();
        // Bugünkü seçimi kaydet
        await prefs.setStringList(
          gunlukKey,
          secilen.map((d) => d['id'] as String).toList(),
        );
      }
    }

    if (mounted) {
      setState(() {
        _seciliKategori = kategori;
        _gosterilenDertler = secilen;
        _adim = _DertAdim.dert;
      });
      _fadeCtrl.forward(from: 0);
    }
  }

  // ── Dert seçildi ─────────────────────────────────────────────────────────────

  Future<void> _dertSec(Map<String, dynamic> dert) async {
    final prefs = await SharedPreferences.getInstance();

    // Gösterilen listeye ekle (farklı günler için no-repeat)
    final gostKey = '$_prefGosterilen$_seciliKategori';
    final ids = prefs.getStringList(gostKey) ?? [];
    final dertId = dert['id'] as String;
    if (!ids.contains(dertId)) {
      ids.add(dertId);
      await prefs.setStringList(gostKey, ids);
    }

    // Günlük limiti işaretle
    await prefs.setString(_prefBugun, _bugun);

    if (!mounted) return;
    setState(() {
      _seciliDert = dert;
      _adim = _DertAdim.yukleniyor;
    });
    _fadeCtrl.forward(from: 0);

    // 5 saniye sonra tavsiyelere geç
    _gecisTimer?.cancel();
    _gecisTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _adim = _DertAdim.derman);
        _fadeCtrl.forward(from: 0);
      }
    });
  }

  // ── Geri git ─────────────────────────────────────────────────────────────────

  void _geriDon() {
    switch (_adim) {
      case _DertAdim.dert:
        setState(() {
          _adim = _DertAdim.kategori;
        });
        _fadeCtrl.forward(from: 0);
      case _DertAdim.yukleniyor:
        _gecisTimer?.cancel();
        setState(() {
          _adim = _DertAdim.dert;
        });
        _fadeCtrl.forward(from: 0);
      case _DertAdim.derman:
        context.pop();
      case _DertAdim.kategori:
        context.pop();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SwipeBack(
      onSwipeBack: _geriDon,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: GrimoireBackdrop(
          child: _ilkYukleme
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                )
              : _limitDoldu
                  ? _buildLimitSayfasi()
                  : FadeTransition(opacity: _fadeAnim, child: _buildAdim()),
        ),
      ),
    );
  }

  Widget _buildAdim() {
    switch (_adim) {
      case _DertAdim.kategori:
        return _buildKategoriSayfasi();
      case _DertAdim.dert:
        return _buildDertSayfasi();
      case _DertAdim.yukleniyor:
        return _buildYukleniyorSayfasi();
      case _DertAdim.derman:
        return _buildDermanSayfasi();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Limit doldu
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildLimitSayfasi() {
    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 64,
                      color: AppColors.boneDim,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      ref.watch(l10nProvider).dertEnoughToday,
                      style: TextStyle(
                        color: AppColors.bone,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ref.watch(l10nProvider).dertComeTomorrow,
                      style: TextStyle(
                        color: AppColors.bone.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Kategori seçimi (dikeyde ortalı, alta geri butonu)
  // ─────────────────────────────────────────────────────────────────────────────

  // Gece Grimuarı okült çizgi glifleri (kahve falıyla aynı aile; genel = pusula).
  /// Eski kategori renkleri (2026-11-05 geri geldi).
  static const _konuRenk = <String, Color>{
    'genel': Color(0xFF6A3FBF),
    'ask': Color(0xFFBB1A7A),
    'saglik': Color(0xFF1A6B4A),
    'kariyer': Color(0xFF1A3A8F),
  };

  GlyphBuilder _konuGlyph(String konu) {
    final g = switch (konu) {
      'ask' => OccultGlyph.heart,
      'saglik' => OccultGlyph.sprig,
      'kariyer' => OccultGlyph.key,
      _ => OccultGlyph.compass,
    };
    return (c, s) => OccultGlyphIcon(g, color: c, size: s);
  }

  Widget _buildKategoriSayfasi() {
    final profile = ref.watch(userProfileProvider);
    final isim = profile.name.isNotEmpty ? profile.name : '';
    final baslik = ref.watch(l10nProvider).dertAskTopic(isim);

    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          // Şıklar tam ortalı; balon üstteki boşluğa Stack ile yerleşir
          Expanded(
            child: LayoutBuilder(
              builder:
                  (context, box) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: max(0, box.maxHeight - 40),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MagnusBalonu(metin: baslik),
                          const SizedBox(height: 28),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.05,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                for (final k in [
                                  ('genel', ref.watch(l10nProvider).general),
                                  ('ask', ref.watch(l10nProvider).love),
                                  ('saglik', ref.watch(l10nProvider).health),
                                  ('kariyer', ref.watch(l10nProvider).career),
                                ])
                                  OccultChoiceTile(
                                    label: k.$2,
                                    glyph: _konuGlyph(k.$1),
                                    accent: _konuRenk[k.$1],
                                    onTap: () => _kategoriSec(k.$1),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
          // Alt geri butonu
          _buildAltGeriButonu(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Dert seçimi (dikeyde ortalı, alta geri butonu)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDertSayfasi() {
    if (_gosterilenDertler.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _buildBaslikBar(),
            Expanded(
              child: Center(
                child: Text(
                  ref.watch(l10nProvider).dertNoneInCategory,
                  style: const TextStyle(color: AppColors.ash),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            _buildAltGeriButonu(),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          Expanded(
            child: LayoutBuilder(
              builder:
                  (context, box) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: max(0, box.maxHeight - 40),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MagnusBalonu(
                            metin: ref.watch(l10nProvider).dertWhichFits,
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                for (
                                  int i = 0;
                                  i < _gosterilenDertler.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  _DertSecenegi(
                                    metin:
                                        _gosterilenDertler[i]['metin']
                                            as String,
                                    onTap:
                                        () => _dertSec(_gosterilenDertler[i]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
          _buildAltGeriButonu(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Kum saati yükleme ekranı
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildYukleniyorSayfasi() {
    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kum saati animasyonu
                  const ElegantHourglass(size: 72, color: AppColors.gold),
                  const SizedBox(height: 28),
                  Text(
                    ref.watch(l10nProvider).dertAnalyzing,
                    style: const TextStyle(
                      color: AppColors.bone,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ref.watch(l10nProvider).dertPatience,
                    style: TextStyle(
                      color: AppColors.bone.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Derman (tavsiye) sayfası
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDermanSayfasi() {
    final profile = ref.read(userProfileProvider);
    final varMap = profile.toVariableMap();
    final dermanlar = (_seciliDert!['dermanlar'] as List).cast<String>();
    final secilenM = _seciliDert!['metin'] as String;

    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          const SizedBox(height: 8),
          _MagnusBalonu(metin: ref.watch(l10nProvider).dertMyAdvice),
          const SizedBox(height: 10),
          // Seçilen dert alıntısı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassPanel(
              variant: GlassVariant.reading,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: RichTextParser.build(
                '"$secilenM"',
                style: AppTextStyles.reading.copyWith(
                  color: AppColors.boneDim,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Dermanlar
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              itemCount: dermanlar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:
                  (_, i) => _DermanKarti(
                    numara: i + 1,
                    metin: VariableReplacer.replace(dermanlar[i], varMap),
                  ),
            ),
          ),
          // Kapat
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: OccultButton(
              label: ref.watch(l10nProvider).thanks,
              onTap: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Ortak widget'lar
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildBaslikBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _geriDon,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.boneDim,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              ref.watch(l10nProvider).companionTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAltGeriButonu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: GestureDetector(
        onTap: _geriDon,
        child: Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 2),
              Text(
                ref.read(l10nProvider).backButton,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Magnus konuşma balonu
// ─────────────────────────────────────────────────────────────────────────────

class _MagnusBalonu extends StatelessWidget {
  final String metin;
  const _MagnusBalonu({required this.metin});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(
          width: 38,
          height: 38,
          child: ClipOval(child: FilmedImage('assets/images/magnusicon.png')),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassPanel(
            variant: GlassVariant.bubble,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: RichTextParser.build(metin, style: AppTextStyles.bubbleText),
          ),
        ),
      ],
    ),
  );
}

class _DertSecenegi extends StatelessWidget {
  final String metin;
  final VoidCallback onTap;
  const _DertSecenegi({required this.metin, required this.onTap});
  @override
  Widget build(BuildContext context) => OccultListCard(
    title: metin,
    glyph: (c, s) => Icon(Icons.chat_bubble_outline_rounded, color: c, size: s),
    onTap: onTap,
  );
}

class _DermanKarti extends StatelessWidget {
  final int numara;
  final String metin;
  const _DermanKarti({required this.numara, required this.metin});
  @override
  Widget build(BuildContext context) => GlassPanel(
    variant: GlassVariant.reading,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OccultSectionLabel('$numara'),
        const SizedBox(height: 8),
        RichTextParser.build(metin, style: AppTextStyles.reading),
      ],
    ),
  );
}
