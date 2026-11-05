// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Biyoritim\
// JSON:   assets/data/biyoritim.json
// Arka plan: assets/images/falbg/biyoritim.png
//
// Bölüm düzeni (görsellere bakılarak):
//   B1      → Giriş metni (doğum tarihi / burç / cinsiyet ile kişiselleştirilmiş)
//   B2A     → Duygusal    %xx — 0-25 / 25-50 / 50-75 / 75-100 metin havuzları
//   B2B     → Fiziksel    %xx
//   B2C     → Entelektüel %xx
//   B3A     → Aşkta şans  %xx
//   B3B     → Parada şans %xx
//   B4      → Çakralar (% yok, düz metin)
//   B5      → Çin Takvimi (% yok, düz metin)
//
// Günlük tutarlılık kuralı:
//   Aynı gün içinde ekran kaç kez açılırsa açılsın hep aynı yüzdeler ve
//   metinler gösterilir. Yeni gün geldiğinde yeni değerler üretilir.
//   Yüzdeler + seçilen metin ID'leri SharedPreferences'a kaydedilir.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/occult_cards.dart';
import '../../core/utils/rich_text_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// ─── Modeller ────────────────────────────────────────────────────────────────

class _Entry {
  final int id;
  final String metin;
  final String metinEn;
  final List<Map<String, String>> kosullar;
  const _Entry({
    required this.id,
    required this.metin,
    this.metinEn = '',
    required this.kosullar,
  });
  String metinFor(bool isEn) => (isEn && metinEn.isNotEmpty) ? metinEn : metin;
}

// ─── Seçilen biyoritim verisi ─────────────────────────────────────────────────

class _BiyoResult {
  final String b1Metin;
  final int duygusalPct;
  final String duygusalMetin;
  final int fizikselPct;
  final String fizikselMetin;
  final int entelektuelPct;
  final String entelektuelMetin;
  final int askSansPct;
  final String askSansMetin;
  final int paraSansPct;
  final String paraSansMetin;
  final String cakraMetin;
  final String cinTakvimMetin;

  const _BiyoResult({
    required this.b1Metin,
    required this.duygusalPct,
    required this.duygusalMetin,
    required this.fizikselPct,
    required this.fizikselMetin,
    required this.entelektuelPct,
    required this.entelektuelMetin,
    required this.askSansPct,
    required this.askSansMetin,
    required this.paraSansPct,
    required this.paraSansMetin,
    required this.cakraMetin,
    required this.cinTakvimMetin,
  });
}

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class BiyoritimScreen extends ConsumerStatefulWidget {
  const BiyoritimScreen({super.key});

  @override
  ConsumerState<BiyoritimScreen> createState() => _BiyoritimScreenState();
}

class _BiyoritimScreenState extends ConsumerState<BiyoritimScreen>
    with TickerProviderStateMixin {
  final _rng = Random();

  _BiyoResult? _result;
  bool _loading = true;

  // Bar animasyon controller'ı
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  // ─── Bugünün tarih anahtarı (YYYY-MM-DD) ─────────────────────────────────

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ─── JSON yükle, günlük cache'e bak, gerekirse yeni üret ─────────────────

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('assets/data/biyoritim.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    // Havuz yardımcıları
    List<_Entry> flatPool(String key) => _parseList(data[key] as List);
    List<_Entry> rangedPool(String key, int pct) =>
        _parseList((data[key] as Map)[_rangeFor(pct)] as List);

    _BiyoResult result;
    final lastDate = prefs.getString('biyo_last_date') ?? '';

    if (lastDate == today) {
      // ── Aynı gün: cache'ten yükle ─────────────────────────────────────────
      final dp = prefs.getInt('biyo_pct_duygusal') ?? 50;
      final fp = prefs.getInt('biyo_pct_fiziksel') ?? 50;
      final ep = prefs.getInt('biyo_pct_entelektuel') ?? 50;
      final ap = prefs.getInt('biyo_pct_asksans') ?? 50;
      final pp = prefs.getInt('biyo_pct_parasans') ?? 50;

      result = _BiyoResult(
        b1Metin: _findById(prefs, 'biyo_id_b1', flatPool('b1')),
        duygusalPct: dp,
        duygusalMetin: _findById(prefs, 'biyo_id_b2a', rangedPool('b2a', dp)),
        fizikselPct: fp,
        fizikselMetin: _findById(prefs, 'biyo_id_b2b', rangedPool('b2b', fp)),
        entelektuelPct: ep,
        entelektuelMetin: _findById(
          prefs,
          'biyo_id_b2c',
          rangedPool('b2c', ep),
        ),
        askSansPct: ap,
        askSansMetin: _findById(prefs, 'biyo_id_b3a', rangedPool('b3a', ap)),
        paraSansPct: pp,
        paraSansMetin: _findById(prefs, 'biyo_id_b3b', rangedPool('b3b', pp)),
        cakraMetin: _findById(prefs, 'biyo_id_b4', flatPool('b4')),
        cinTakvimMetin: _findById(prefs, 'biyo_id_b5', flatPool('b5')),
      );
    } else {
      // ── Yeni gün: taze değerler üret, kaydet ──────────────────────────────
      final dp = _rng.nextInt(101);
      final fp = _rng.nextInt(101);
      final ep = _rng.nextInt(101);
      final ap = _rng.nextInt(101);
      final pp = _rng.nextInt(101);

      result = _BiyoResult(
        b1Metin: _pickAndSave(prefs, 'bio_b1', flatPool('b1'), 'biyo_id_b1'),
        duygusalPct: dp,
        duygusalMetin: _pickAndSave(
          prefs,
          'bio_b2a_${_rangeFor(dp)}',
          rangedPool('b2a', dp),
          'biyo_id_b2a',
        ),
        fizikselPct: fp,
        fizikselMetin: _pickAndSave(
          prefs,
          'bio_b2b_${_rangeFor(fp)}',
          rangedPool('b2b', fp),
          'biyo_id_b2b',
        ),
        entelektuelPct: ep,
        entelektuelMetin: _pickAndSave(
          prefs,
          'bio_b2c_${_rangeFor(ep)}',
          rangedPool('b2c', ep),
          'biyo_id_b2c',
        ),
        askSansPct: ap,
        askSansMetin: _pickAndSave(
          prefs,
          'bio_b3a_${_rangeFor(ap)}',
          rangedPool('b3a', ap),
          'biyo_id_b3a',
        ),
        paraSansPct: pp,
        paraSansMetin: _pickAndSave(
          prefs,
          'bio_b3b_${_rangeFor(pp)}',
          rangedPool('b3b', pp),
          'biyo_id_b3b',
        ),
        cakraMetin: _pickAndSave(prefs, 'bio_b4', flatPool('b4'), 'biyo_id_b4'),
        cinTakvimMetin: _pickAndSave(
          prefs,
          'bio_b5',
          flatPool('b5'),
          'biyo_id_b5',
        ),
      );

      // Yüzdeleri ve tarihi sakla
      await Future.wait([
        prefs.setInt('biyo_pct_duygusal', dp),
        prefs.setInt('biyo_pct_fiziksel', fp),
        prefs.setInt('biyo_pct_entelektuel', ep),
        prefs.setInt('biyo_pct_asksans', ap),
        prefs.setInt('biyo_pct_parasans', pp),
        prefs.setString('biyo_last_date', today),
      ]);
    }

    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });

    // Barlar 400 ms sonra dolmaya başlasın
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _barCtrl.forward();
    });
  }

  // ─── Yardımcı: aynı gün, ID ile metni bul ────────────────────────────────

  String _findById(SharedPreferences prefs, String idKey, List<_Entry> pool) {
    final id = prefs.getInt(idKey) ?? -1;
    final profile = ref.read(userProfileProvider);
    final entry = pool.firstWhere(
      (e) => e.id == id,
      orElse:
          () =>
              pool.isNotEmpty
                  ? pool.first
                  : const _Entry(id: -1, metin: '', kosullar: []),
    );
    if (entry.metin.isEmpty) return '';
    final isEn = ref.read(localeProvider) == 'en';
    return VariableReplacer.replace(
      entry.metinFor(isEn),
      profile.toVariableMap(),
    );
  }

  // ─── Yardımcı: yeni metin seç, no-repeat kaydet, ID'yi cache'e yaz ───────

  String _pickAndSave(
    SharedPreferences prefs,
    String noRepeatKey,
    List<_Entry> pool,
    String idCacheKey,
  ) {
    if (pool.isEmpty) return '';
    final profile = ref.read(userProfileProvider);

    // Koşul filtresi
    final filtered =
        pool.where((e) {
          for (final k in e.kosullar) {
            final val = _profileVal(k['degisken'] ?? '');
            if (val != k['deger']) return false;
          }
          return true;
        }).toList();

    final available = filtered.isEmpty ? pool : filtered;

    // Tekrar gösterilmeme (üst üste aynı metin yasağı dahil)
    var shown = prefs.getStringList(noRepeatKey) ?? [];
    var unseen = available.where((e) => !shown.contains('${e.id}')).toList();
    if (unseen.isEmpty) {
      // Havuz bitti → sıfırla, ama son gösterilen metni bir sonraki döngüye taşı
      final lastId = shown.isNotEmpty ? shown.last : null;
      shown = lastId != null ? [lastId] : [];
      prefs.setStringList(noRepeatKey, shown);
      unseen = available.where((e) => '${e.id}' != lastId).toList();
      if (unseen.isEmpty) {
        unseen = List.from(available); // tek metin var, zorunlu tekrar
      }
    }

    unseen.shuffle(_rng);
    final pick = unseen.first;
    shown.add('${pick.id}');
    prefs.setStringList(noRepeatKey, shown);

    // Bugünün ID'sini kaydet
    prefs.setInt(idCacheKey, pick.id);

    final isEn = ref.read(localeProvider) == 'en';
    return VariableReplacer.replace(
      pick.metinFor(isEn),
      profile.toVariableMap(),
    );
  }

  // ─── Yardımcı: yüzdeye göre aralık anahtarı ──────────────────────────────

  String _rangeFor(int pct) {
    if (pct < 25) return '0-25';
    if (pct < 50) return '25-50';
    if (pct < 75) return '50-75';
    return '75-100';
  }

  // ─── Yardımcı: JSON listesini _Entry listesine çevir ─────────────────────

  List<_Entry> _parseList(List raw) {
    return raw.map((e) {
      final m = e as Map<String, dynamic>;
      return _Entry(
        id: m['id'] as int,
        metin: m['metin'] as String,
        metinEn: (m['metin_en'] as String?) ?? '',
        kosullar:
            (m['kosullar'] as List)
                .map((k) => Map<String, String>.from(k as Map))
                .toList(),
      );
    }).toList();
  }

  String _profileVal(String key) {
    final p = ref.read(userProfileProvider);
    switch (key) {
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

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    extendBody: true,
    body: GrimoireBackdrop(
      asset: 'assets/images/falbg/biyoritim.png',
      imageAlignment: Alignment.topCenter,
      child: SafeArea(
        child: Column(
          children: [
            // Üst bar: cam geri kutusu + başlık (Codex/inceleme: üst geri kaldırılmıştı;
            // rota FadeTransition olduğu için iOS'ta kenardan kaydırma yok).
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: ref.watch(l10nProvider).backButton,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.glassTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.rim, width: 0.8),
                        ),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: AppColors.bone, size: 24),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ref.watch(l10nProvider).biyoritimTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Expanded(
              child:
                  _loading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                          strokeWidth: 2,
                        ),
                      )
                      : _buildContent(),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _buildContent() {
    final r = _result!;
    final s = ref.watch(l10nProvider);
    final isEn = ref.watch(localeProvider) == 'en';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _buildTextCard(r.b1Metin),
        // Eski çubuk renkleri (2026-11-05 geri geldi)
        _buildBarCard(s.emotional, r.duygusalPct, r.duygusalMetin, const Color(0xFFFF4444)),
        _buildBarCard(s.physical, r.fizikselPct, r.fizikselMetin, const Color(0xFF4488FF)),
        _buildBarCard(s.intellectual, r.entelektuelPct, r.entelektuelMetin, const Color(0xFF44DD66)),
        _buildSectionLabel(isEn ? 'Luck' : 'Şans'),
        _buildBarCard(
          isEn ? 'Luck in love' : 'Aşkta Şansın',
          r.askSansPct,
          r.askSansMetin,
          const Color(0xFFFF44CC),
        ),
        _buildBarCard(
          isEn ? 'Luck with money' : 'Parada Şansın',
          r.paraSansPct,
          r.paraSansMetin,
          const Color(0xFFFFDD00),
        ),
        _buildSectionLabel(isEn ? 'Chakras' : 'Çakralar'),
        _buildTextCard(r.cakraMetin),
        _buildSectionLabel(isEn ? 'Chinese calendar' : 'Çin Takvimi'),
        _buildTextCard(r.cinTakvimMetin),
        const SizedBox(height: 12), _buildBackButton(),
      ],
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: OccultSectionLabel(label),
  );
  Widget _buildTextCard(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassPanel(
      variant: GlassVariant.reading,
      padding: const EdgeInsets.all(18),
      child: RichTextParser.build(
        text.replaceAll(RegExp(r'<sprite=[^>]*>', caseSensitive: false), ''),
        style: AppTextStyles.reading,
      ),
    ),
  );
  Widget _buildBarCard(String label, int pct, String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassPanel(
      variant: GlassVariant.reading,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.uiLabel.copyWith(color: color))),
              Text(
                ref.read(localeProvider) == 'en' ? '$pct%' : '%$pct',
                style: AppTextStyles.value.copyWith(
                  color: color,
                  fontFeatures: AppTextStyles.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _barAnim,
            builder:
                (context, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100 * _barAnim.value,
                    minHeight: 6,
                    backgroundColor: AppColors.bone.withValues(alpha: 0.08),
                    color: color,
                  ),
                ),
          ),
          const SizedBox(height: 14),
          RichTextParser.build(
            text.replaceAll(
              RegExp(r'<sprite=[^>]*>', caseSensitive: false),
              '',
            ),
            style: AppTextStyles.reading,
          ),
        ],
      ),
    ),
  );
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.bone.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: AppColors.bone.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.bone,
              size: 20,
            ),
            const SizedBox(width: 2),
            Text(
              ref.read(l10nProvider).backButton,
              style: const TextStyle(
                color: AppColors.bone,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
