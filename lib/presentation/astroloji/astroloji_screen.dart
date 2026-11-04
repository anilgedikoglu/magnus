import '../../core/utils/rich_text_parser.dart';
import '../../core/widgets/occult_cards.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';
// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\GunlukAstroloji\GunlukAstro
// JSON:   assets/data/gunlukastroloji.json
// Bölümler (sırayla): giris · astroyorum · astrogununsozu · astrogununayeti ·
//   astrogununhadisi · astroeglencelibilgi · astrokesif · astrogununismi ·
//   astrogununyemegi · astroveda
//
// Her bölümden 1 random metin seçilir (tekrar gösterilmeme kuralı).
// 10 bölüm tek ekranda birleşik olarak gösterilir.
//
// ⚠️ METIN MOTORU NOTU: Unity `aciklama:` alanı YAML listesidir.
// Tek .asset dosyasında birden fazla `- "..."` maddesi olabilir → her biri ayrı JSON girdisi!
// JSON yeniden üretilirken extract_all_aciklama() tipi parser kullan. Bkz. CLAUDE.md.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// ─── Bölüm tanımları (sıra önemli) ──────────────────────────────────────────

class _Section {
  final String key;        // JSON anahtarı
  final String baslik;     // Ekranda gösterilecek başlık
  const _Section(this.key, this.baslik);
}

const _sections = [
  _Section('giris',             'Giriş'),
  _Section('astroyorum',        'Astro Yorum'),
  _Section('astrogununsozu',    'Günün Sözü'),
  _Section('astrogununayeti',   'Günün Ayeti'),
  _Section('astrogununhadisi',  'Günün Hadisi'),
  _Section('astroeglencelibilgi','Eğlenceli Bilgi'),
  _Section('astrokesif',        'Astro Keşif'),
  _Section('astrogununismi',    'Günün İsmi'),
  _Section('astrogununyemegi',  'Günün Yemeği'),
  _Section('astroveda',         'Astro Veda'),
];

// ─── Veri modeli ──────────────────────────────────────────────────────────────

class _AstroEntry {
  final int id;
  final String metin;
  final String metinEn;
  const _AstroEntry({required this.id, required this.metin, this.metinEn = ''});
  String metinFor(bool isEn) => (isEn && metinEn.isNotEmpty) ? metinEn : metin;
}

// ─── Seçilen metin (bölüm + içerik) ──────────────────────────────────────────

class _SelectedText {
  final _Section section;
  final String metin;
  const _SelectedText(this.section, this.metin);
}

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class AstrolojiScreen extends ConsumerStatefulWidget {
  const AstrolojiScreen({super.key});

  @override
  ConsumerState<AstrolojiScreen> createState() => _AstrolojiScreenState();
}

class _AstrolojiScreenState extends ConsumerState<AstrolojiScreen> {
  List<_SelectedText> _selected = [];
  bool _loading = true;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _loadAndPick();
  }

  // ─── Veri yükle + her bölümden 1 metin seç ──────────────────────────────────

  Future<void> _loadAndPick() async {
    final raw  = await rootBundle.loadString('assets/data/gunlukastroloji.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    // JSON artık bölüm anahtarlı: {"giris": [...], "astroyorum": [...], ...}
    final data = <String, List<_AstroEntry>>{};
    for (final key in json.keys) {
      final list = (json[key] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return _AstroEntry(id: m['id'] as int, metin: m['metin'] as String, metinEn: (m['metin_en'] as String?) ?? '');
      }).toList();
      data[key] = list;
    }

    final prefs    = await SharedPreferences.getInstance();
    final now      = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final selected = <_SelectedText>[];

    for (final sec in _sections) {
      final pool = data[sec.key] ?? [];
      if (pool.isEmpty) continue;

      final dateKey  = 'astroloji_${sec.key}_tarih';
      final idKey    = 'astroloji_${sec.key}_bugun_id';
      final shownKey = 'astroloji_${sec.key}_gosterilen';

      final savedDate = prefs.getString(dateKey);
      final savedId   = prefs.getInt(idKey);

      _AstroEntry pick;

      if (savedDate == todayStr && savedId != null) {
        // Aynı gün → bugün seçilen metni göster
        pick = pool.firstWhere((e) => e.id == savedId, orElse: () => pool.first);
      } else {
        // Farklı gün → no-repeat mantığıyla yeni metin seç
        final shown = prefs.getStringList(shownKey) ?? [];
        var available = pool.where((e) => !shown.contains('${e.id}')).toList();
        if (available.isEmpty) {
          // Tüm metinler gösterildi; üst üste yasağını koru
          final lastId = shown.isNotEmpty ? shown.last : null;
          final resetShown = lastId != null ? [lastId] : <String>[];
          await prefs.setStringList(shownKey, resetShown);
          available = pool.where((e) => e.id.toString() != lastId).toList();
          if (available.isEmpty) available = List.from(pool);
        }
        available.shuffle(_rng);
        pick = available.first;
        final updatedShown = prefs.getStringList(shownKey) ?? [];
        updatedShown.add('${pick.id}');
        await prefs.setStringList(shownKey, updatedShown);
        await prefs.setString(dateKey, todayStr);
        await prefs.setInt(idKey, pick.id);
      }

      selected.add(_SelectedText(sec, _applyVars(pick.metinFor(ref.read(localeProvider) == 'en'))));
    }

    if (mounted) {
      setState(() {
        _selected = selected;
        _loading  = false;
      });
    }
  }

  String _applyVars(String text) {
    final profile = ref.read(userProfileProvider);
    return VariableReplacer.replace(text, profile.toVariableMap());
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      extendBody: true,
      body: GrimoireBackdrop(asset: 'assets/images/space_bg.png', child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading ? _buildLoading() : _buildContent(),
                ),
              ],
            ),
          )),
    );
  }

  // ─── Başlık ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        children: [
          // Sol geri butonu + başlık satırı
          Row(
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
                    ref.watch(l10nProvider).astrologyTitle,
                    style: AppTextStyles.screenTitle,
                  ),
                ),
              ),
              const SizedBox(width: 38), // simetri
            ],
          ),
          const SizedBox(height: 4),
          // Tarih alt başlığı
          Text(
            _todayStr(),
            style: AppTextStyles.meta.copyWith(fontFeatures: AppTextStyles.tabular),
          ),
          const SizedBox(height: 8),
          // İnce ayraç
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.transparent, AppColors.rim, Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  String _todayStr() {
    // L10N: astroDateMonths
    const ay = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    final now = DateTime.now();
    return '${now.day} ${ay[now.month]} ${now.year}';
  }

  // ─── Yükleniyor ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.gold,
        strokeWidth: 2,
      ),
    );
  }

  // ─── Ana içerik ───────────────────────────────────────────────────────────────

  Widget _buildContent() {
    // itemCount + 1: son item = "Geri Dön" butonu (scroll sonunda görünür)
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      itemCount: _selected.length + 1,
      itemBuilder: (context, i) {
        if (i < _selected.length) return _buildSectionCard(_selected[i]);
        return _buildBackButton();
      },
    );
  }

  Widget _buildSectionCard(_SelectedText item) {
    // L10N: astroSectionLabels
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: GlassPanel(
      variant: GlassVariant.reading, padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OccultSectionLabel(item.section.baslik), const SizedBox(height:12),
        RichTextParser.build(item.metin, style: AppTextStyles.reading),
      ]),
    ));
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 2),
              Text(ref.read(l10nProvider).backButton,
                style: const TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
