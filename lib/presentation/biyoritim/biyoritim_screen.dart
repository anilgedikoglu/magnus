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
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// ─── Modeller ────────────────────────────────────────────────────────────────

class _Entry {
  final int id;
  final String metin;
  final List<Map<String, String>> kosullar;
  const _Entry({required this.id, required this.metin, required this.kosullar});
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
    final raw   = await rootBundle.loadString('assets/data/biyoritim.json');
    final data  = jsonDecode(raw) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    // Havuz yardımcıları
    List<_Entry> flatPool(String key) =>
        _parseList(data[key] as List);
    List<_Entry> rangedPool(String key, int pct) =>
        _parseList((data[key] as Map)[_rangeFor(pct)] as List);

    _BiyoResult result;
    final lastDate = prefs.getString('biyo_last_date') ?? '';

    if (lastDate == today) {
      // ── Aynı gün: cache'ten yükle ─────────────────────────────────────────
      final dp = prefs.getInt('biyo_pct_duygusal')    ?? 50;
      final fp = prefs.getInt('biyo_pct_fiziksel')    ?? 50;
      final ep = prefs.getInt('biyo_pct_entelektuel') ?? 50;
      final ap = prefs.getInt('biyo_pct_asksans')     ?? 50;
      final pp = prefs.getInt('biyo_pct_parasans')    ?? 50;

      result = _BiyoResult(
        b1Metin:         _findById(prefs, 'biyo_id_b1',  flatPool('b1')),
        duygusalPct:     dp,
        duygusalMetin:   _findById(prefs, 'biyo_id_b2a', rangedPool('b2a', dp)),
        fizikselPct:     fp,
        fizikselMetin:   _findById(prefs, 'biyo_id_b2b', rangedPool('b2b', fp)),
        entelektuelPct:  ep,
        entelektuelMetin:_findById(prefs, 'biyo_id_b2c', rangedPool('b2c', ep)),
        askSansPct:      ap,
        askSansMetin:    _findById(prefs, 'biyo_id_b3a', rangedPool('b3a', ap)),
        paraSansPct:     pp,
        paraSansMetin:   _findById(prefs, 'biyo_id_b3b', rangedPool('b3b', pp)),
        cakraMetin:      _findById(prefs, 'biyo_id_b4',  flatPool('b4')),
        cinTakvimMetin:  _findById(prefs, 'biyo_id_b5',  flatPool('b5')),
      );
    } else {
      // ── Yeni gün: taze değerler üret, kaydet ──────────────────────────────
      final dp = _rng.nextInt(101);
      final fp = _rng.nextInt(101);
      final ep = _rng.nextInt(101);
      final ap = _rng.nextInt(101);
      final pp = _rng.nextInt(101);

      result = _BiyoResult(
        b1Metin:          _pickAndSave(prefs, 'bio_b1',                       flatPool('b1'),          'biyo_id_b1'),
        duygusalPct:      dp,
        duygusalMetin:    _pickAndSave(prefs, 'bio_b2a_${_rangeFor(dp)}',     rangedPool('b2a', dp),   'biyo_id_b2a'),
        fizikselPct:      fp,
        fizikselMetin:    _pickAndSave(prefs, 'bio_b2b_${_rangeFor(fp)}',     rangedPool('b2b', fp),   'biyo_id_b2b'),
        entelektuelPct:   ep,
        entelektuelMetin: _pickAndSave(prefs, 'bio_b2c_${_rangeFor(ep)}',     rangedPool('b2c', ep),   'biyo_id_b2c'),
        askSansPct:       ap,
        askSansMetin:     _pickAndSave(prefs, 'bio_b3a_${_rangeFor(ap)}',     rangedPool('b3a', ap),   'biyo_id_b3a'),
        paraSansPct:      pp,
        paraSansMetin:    _pickAndSave(prefs, 'bio_b3b_${_rangeFor(pp)}',     rangedPool('b3b', pp),   'biyo_id_b3b'),
        cakraMetin:       _pickAndSave(prefs, 'bio_b4',                       flatPool('b4'),           'biyo_id_b4'),
        cinTakvimMetin:   _pickAndSave(prefs, 'bio_b5',                       flatPool('b5'),           'biyo_id_b5'),
      );

      // Yüzdeleri ve tarihi sakla
      await Future.wait([
        prefs.setInt('biyo_pct_duygusal',    dp),
        prefs.setInt('biyo_pct_fiziksel',    fp),
        prefs.setInt('biyo_pct_entelektuel', ep),
        prefs.setInt('biyo_pct_asksans',     ap),
        prefs.setInt('biyo_pct_parasans',    pp),
        prefs.setString('biyo_last_date',    today),
      ]);
    }

    if (!mounted) return;
    setState(() {
      _result  = result;
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
      orElse: () => pool.isNotEmpty ? pool.first : const _Entry(id: -1, metin: '', kosullar: []),
    );
    if (entry.metin.isEmpty) return '';
    return VariableReplacer.replace(entry.metin, profile.toVariableMap());
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
    final filtered = pool.where((e) {
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
      if (unseen.isEmpty) unseen = List.from(available); // tek metin var, zorunlu tekrar
    }

    unseen.shuffle(_rng);
    final pick = unseen.first;
    shown.add('${pick.id}');
    prefs.setStringList(noRepeatKey, shown);

    // Bugünün ID'sini kaydet
    prefs.setInt(idCacheKey, pick.id);

    return VariableReplacer.replace(pick.metin, profile.toVariableMap());
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
        kosullar: (m['kosullar'] as List)
            .map((k) => Map<String, String>.from(k as Map))
            .toList(),
      );
    }).toList();
  }

  String _profileVal(String key) {
    final p = ref.read(userProfileProvider);
    switch (key) {
      case 'cinsiyet':     return p.gender;
      case 'medeni_durum': return p.maritalStatus;
      case 'meslek':       return p.job;
      default:             return '';
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // ── Arka plan ─────────────────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/falbg/biyoritim.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF050018)),
            ),
          ),
          // ── Karartma ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x88000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          // ── İçerik ────────────────────────────────────────────────────────
          SafeArea(
            bottom: false, // bottomPad'i manuel ekleyeceğiz
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF),
                            strokeWidth: 2,
                          ),
                        )
                      : _buildContent(bottomPad),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Başlık ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    // SafeArea(bottom:false) üst inset'i zaten ekledi — sadece 10px iç boşluk yeterli.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
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
                ref.watch(l10nProvider).biyoritimTitle,
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 5,
                  shadows: const [
                    Shadow(color: Color(0xAA00E5FF), blurRadius: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 38), // simetri
        ],
      ),
    );
  }

  // ─── Ana içerik (kaydırılabilir) ──────────────────────────────────────────

  Widget _buildContent(double bottomPad) {
    final r = _result!;
    // Sistem nav çubuğu + ekstra boşluk
    final extraBottom = bottomPad + 16;
    return ListView(
      padding: EdgeInsets.fromLTRB(14, 12, 14, extraBottom),
      children: [
        // B1 — Giriş
        _buildIntroCard(r.b1Metin),
        const SizedBox(height: 10),

        // B2 — Biyoritim çubukları
        _buildBarCard(ref.read(l10nProvider).emotional,     r.duygusalPct,    r.duygusalMetin,    const Color(0xFFFF4444)),
        _buildBarCard(ref.read(l10nProvider).physical,      r.fizikselPct,    r.fizikselMetin,    const Color(0xFF4488FF)),
        _buildBarCard(ref.read(l10nProvider).intellectual,  r.entelektuelPct, r.entelektuelMetin, const Color(0xFF44DD66)),

        // B3 — Şans
        _buildSectionLabel('ŞANS'),
        _buildBarCard('Aşkta Şansın',  r.askSansPct,  r.askSansMetin,  const Color(0xFFFF44CC)),
        _buildBarCard('Parada Şansın', r.paraSansPct, r.paraSansMetin, const Color(0xFFFFDD00)),

        // B4 — Çakralar
        _buildSectionLabel('ÇAKRALAR'),
        _buildTextCard(r.cakraMetin, const Color(0xFFBB44FF)),

        // B5 — Çin Takvimi
        _buildSectionLabel('ÇİN TAKVİMİ'),
        _buildTextCard(r.cinTakvimMetin, const Color(0xFF44DDFF)),

        const SizedBox(height: 20),

        // Geri Dön — scroll sonunda görünür, sabit overlay DEĞİL
        _buildBackButton(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Giriş kartı ──────────────────────────────────────────────────────────

  Widget _buildIntroCard(String metin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        metin,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.65,
        ),
      ),
    );
  }

  // ─── Bar kartı ────────────────────────────────────────────────────────────

  Widget _buildBarCard(String baslik, int pct, String metin, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık + yüzde
            Text(
              '$baslik  %$pct',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Animasyonlu bar
            AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) {
                final widthFactor = (pct / 100.0) * _barAnim.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Arka plan izi
                      Container(
                        height: 10,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      // Dolu kısım
                      FractionallySizedBox(
                        widthFactor: widthFactor,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.7),
                                color,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Açıklama metni
            Text(
              metin,
              style: const TextStyle(
                color: Color(0xEEFFFFFF),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bölüm etiketi ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 4,
            shadows: const [
              Shadow(color: Color(0x88FFFFFF), blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Düz metin kartı (Çakra / Çin Takvimi) ───────────────────────────────

  Widget _buildTextCard(String metin, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Text(
          metin,
          style: const TextStyle(
            color: Color(0xEEFFFFFF),
            fontSize: 13,
            height: 1.65,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
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
    );
  }
}
