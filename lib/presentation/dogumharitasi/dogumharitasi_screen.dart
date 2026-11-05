// Kaynak: C:\Users\AG\Desktop\Magnus\Assets\Resources\OnlineSohbetVeriTabani\Astroloji\DogumHaritasi\
// JSON:   assets/data/dogumharitasi.json
//
// Her açılışta 3 bölümden birer metin seçilir ve ana giriş + son ile birleştirilir:
//   Ana (sabit) → Bölüm1 (31 metin) → Bölüm2 (30 metin) → Bölüm3 (33 metin) → Son1 (sabit)
// Günlük tutarlılık: aynı gün aynı içerik gösterilir.
// Tekrar gösterilmeme: her bölüm kendi havuzunu tüketmeden tekrar etmez.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../data/providers.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class _Entry {
  final int id;
  final String metin;
  final String metinEn;
  const _Entry({required this.id, required this.metin, required this.metinEn});
}

// ─── Ekran ───────────────────────────────────────────────────────────────────

class DogumHaritasiScreen extends ConsumerStatefulWidget {
  const DogumHaritasiScreen({super.key});

  @override
  ConsumerState<DogumHaritasiScreen> createState() => _DogumHaritasiScreenState();
}

class _DogumHaritasiScreenState extends ConsumerState<DogumHaritasiScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();

  // Full assembled text (3 sections combined + intro + closing)
  String? _metin;
  bool _loading = true;

  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _breathAnim = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);
    _loadData();
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  // ─── No-repeat per section ────────────────────────────────────────────────

  Future<_Entry> _noRepeatPick(
    List<_Entry> pool,
    String prefsKey,
    SharedPreferences prefs,
  ) async {
    var shown = prefs.getStringList(prefsKey) ?? [];
    var available = pool.where((e) => !shown.contains('${e.id}')).toList();

    if (available.isEmpty) {
      final lastId = shown.isNotEmpty ? shown.last : null;
      shown = lastId != null ? [lastId] : [];
      await prefs.setStringList(prefsKey, shown);
      available = pool.where((e) => e.id.toString() != lastId).toList();
      if (available.isEmpty) available = List.from(pool);
    }

    available.shuffle(_rng);
    final pick = available.first;
    final updated = prefs.getStringList(prefsKey) ?? [];
    updated.add('${pick.id}');
    await prefs.setStringList(prefsKey, updated);
    return pick;
  }

  // ─── Veri yükle ────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final raw   = await rootBundle.loadString('assets/data/dogumharitasi.json');
    final data  = jsonDecode(raw) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final isEn  = ref.read(localeProvider) == 'en';

    // Helper to get metin from a fixed node (ana/ilk/son/son1)
    String fixedText(String key) {
      final node = data[key] as Map<String, dynamic>;
      return isEn ? (node['metin_en'] as String) : (node['metin'] as String);
    }

    // Helper to build pool from section array
    List<_Entry> buildPool(String key) {
      return (data[key] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return _Entry(
          id: m['id'] as int,
          metin: m['metin'] as String,
          metinEn: m['metin_en'] as String? ?? m['metin'] as String,
        );
      }).toList();
    }

    final bolum1 = buildPool('bolum1');
    final bolum2 = buildPool('bolum2');
    final bolum3 = buildPool('bolum3');

    // Cached daily IDs
    final lastDate = prefs.getString('dh_last_date') ?? '';
    final id1 = prefs.getInt('dh_bugun_id1');
    final id2 = prefs.getInt('dh_bugun_id2');
    final id3 = prefs.getInt('dh_bugun_id3');

    _Entry pick1, pick2, pick3;

    if (lastDate == today && id1 != null && id2 != null && id3 != null) {
      // Same day — use cached
      pick1 = bolum1.firstWhere((e) => e.id == id1, orElse: () => bolum1.first);
      pick2 = bolum2.firstWhere((e) => e.id == id2, orElse: () => bolum2.first);
      pick3 = bolum3.firstWhere((e) => e.id == id3, orElse: () => bolum3.first);
    } else {
      // New day — no-repeat pick for each section
      pick1 = await _noRepeatPick(bolum1, 'dh_gosterilen_1', prefs);
      pick2 = await _noRepeatPick(bolum2, 'dh_gosterilen_2', prefs);
      pick3 = await _noRepeatPick(bolum3, 'dh_gosterilen_3', prefs);
      await prefs.setString('dh_last_date', today);
      await prefs.setInt('dh_bugun_id1', pick1.id);
      await prefs.setInt('dh_bugun_id2', pick2.id);
      await prefs.setInt('dh_bugun_id3', pick3.id);
    }

    // Assemble full text: Ana → Bölüm1 → Bölüm2 → Bölüm3 → Son1
    final anaText  = fixedText('ana');
    final son1Text = fixedText('son1');

    final t1 = isEn ? pick1.metinEn : pick1.metin;
    final t2 = isEn ? pick2.metinEn : pick2.metin;
    final t3 = isEn ? pick3.metinEn : pick3.metin;

    final assembled = '$anaText\n\n$t1\n\n$t2\n\n$t3\n\n$son1Text';

    final profile  = ref.read(userProfileProvider);
    final replaced = VariableReplacer.replace(assembled, profile.toVariableMap());

    if (!mounted) return;
    setState(() {
      _metin   = replaced;
      _loading = false;
    });
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad    = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // Arka plan
          Positioned.fill(
            child: Image.asset(
              'assets/images/dogum.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050020)),
            ),
          ),
          // Karartma
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x88000000), Color(0xCC000000)],
              ),
            ),
          ),
          // İçerik
          Column(
            children: [
              // Başlık
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
                          ref.watch(l10nProvider).birthChartTitle,
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                            shadows: const [Shadow(color: Color(0xAA9988FF), blurRadius: 14)],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 38), // simetri
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // İçerik
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(
                        color: Color(0xFF9988FF), strokeWidth: 2))
                    : _buildContent(bottomPad),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Wheel chart + animated edge lights ──────────────────────────────────

  Widget _buildWheelChart() {
    const flareThick = 88.0;

    Widget breathWrap(Widget child) => AnimatedBuilder(
      animation: _breathAnim,
      builder: (_, __) => Opacity(
        opacity: 0.30 + 0.70 * _breathAnim.value,
        child: child,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final size      = constraints.maxWidth * 0.60;
          final flareLen  = size * 5.0;
          final sideOffset = (flareLen - size) / 2;

          Widget flareImg() => Image.asset(
            'assets/images/red-light-line-png-2.png',
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );

          Widget hFlare() => breathWrap(SizedBox(
            width: flareLen,
            height: flareThick,
            child: flareImg(),
          ));

          Widget vFlare() => breathWrap(SizedBox(
            width: flareThick,
            height: flareLen,
            child: RotatedBox(quarterTurns: 1, child: SizedBox(
              width: flareLen,
              height: flareThick,
              child: flareImg(),
            )),
          ));

          return Center(
            child: SizedBox(
              width: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(top: -flareThick / 2, left: -sideOffset, child: hFlare()),
                  Positioned(bottom: -flareThick / 2, left: -sideOffset, child: hFlare()),
                  Positioned(left: -flareThick / 2, top: -sideOffset, child: vFlare()),
                  Positioned(right: -flareThick / 2, top: -sideOffset, child: vFlare()),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9988FF).withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9944FF).withValues(alpha: 0.30),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Image.asset(
                          'assets/images/WheelChartBackground.jpg',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1A0033),
                            child: const Center(
                              child: Text('✦', style: TextStyle(color: Colors.white54, fontSize: 32)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(double bottomPad) {
    return Column(
      children: [
        // Wheel chart — sabit üstte
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildWheelChart(),
        ),

        // Metin kutusu — görsel ve buton arasında kalan tüm alanı doldurur,
        // içerik uzunsa kendi içinde scroll eder
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF9988FF).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: RichTextParser.build(
                  _metin ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.75,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Geri Git — her zaman ekran altında sabit
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 16),
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
        ),
      ],
    );
  }
}
