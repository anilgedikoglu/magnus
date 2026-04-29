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
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// ─── Bölüm tanımları (sıra önemli) ──────────────────────────────────────────

class _Section {
  final String key;        // JSON anahtarı
  final String baslik;     // Ekranda gösterilecek başlık
  final Color renk;        // Başlık / vurgu rengi
  const _Section(this.key, this.baslik, this.renk);
}

const _sections = [
  _Section('giris',             'Giriş',           Color(0xFFBB88FF)),
  _Section('astroyorum',        'Astro Yorum',      Color(0xFF00D4FF)),
  _Section('astrogununsozu',    'Günün Sözü',       Color(0xFFFFCC44)),
  _Section('astrogununayeti',   'Günün Ayeti',      Color(0xFF66FF99)),
  _Section('astrogununhadisi',  'Günün Hadisi',     Color(0xFF88DDFF)),
  _Section('astroeglencelibilgi','Eğlenceli Bilgi', Color(0xFFFF88AA)),
  _Section('astrokesif',        'Astro Keşif',      Color(0xFFFFAA44)),
  _Section('astrogununismi',    'Günün İsmi',       Color(0xFFBBFF88)),
  _Section('astrogununyemegi',  'Günün Yemeği',     Color(0xFFFFDD88)),
  _Section('astroveda',         'Astro Veda',       Color(0xFFBB88FF)),
];

// ─── Veri modeli ──────────────────────────────────────────────────────────────

class _AstroEntry {
  final int id;
  final String metin;
  const _AstroEntry({required this.id, required this.metin});
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
        return _AstroEntry(id: m['id'] as int, metin: m['metin'] as String);
      }).toList();
      data[key] = list;
    }

    final prefs   = await SharedPreferences.getInstance();
    final selected = <_SelectedText>[];

    for (final sec in _sections) {
      final pool = data[sec.key] ?? [];
      if (pool.isEmpty) continue;

      final prefKey = 'astroloji_${sec.key}_gosterilen';
      final shown   = prefs.getStringList(prefKey) ?? [];

      var available = pool.where((e) => !shown.contains('${e.id}')).toList();
      if (available.isEmpty) {
        await prefs.remove(prefKey);
        available = List.from(pool);
      }

      available.shuffle(_rng);
      final pick = available.first;
      shown.add('${pick.id}');
      await prefs.setStringList(prefKey, shown);

      selected.add(_SelectedText(sec, _applyVars(pick.metin)));
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
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // Arka plan — uzay görseli
          SizedBox.expand(
            child: Image.asset(
              'assets/images/space_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF050010)),
            ),
          ),
          // Karartma katmanı
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x99000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading ? _buildLoading() : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
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
                    'GÜNLÜK ASTROLOJİ',
                    style: GoogleFonts.cinzel(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFBB88FF),
                      letterSpacing: 4,
                      shadows: const [
                        Shadow(color: Color(0xAABB88FF), blurRadius: 16),
                      ],
                    ),
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
            style: const TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          // İnce ayraç
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.transparent, Color(0x88BB88FF), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  String _todayStr() {
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
        color: Color(0xFFBB88FF),
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
    final color = item.section.renk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık şeridi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                border: Border(
                  bottom: BorderSide(color: color.withValues(alpha: 0.35), width: 0.8),
                ),
              ),
              child: Text(
                item.section.baslik.toUpperCase(),
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
                  ],
                ),
              ),
            ),
            // Metin
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                item.metin,
                style: const TextStyle(
                  color: Color(0xF0FFFFFF),
                  fontSize: 14,
                  height: 1.7,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              SizedBox(width: 2),
              Text('Geri Git',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
