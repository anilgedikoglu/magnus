// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\DogumHaritasi\Metinler\
// JSON:   assets/data/dogumharitasi.json
// Arka plan: assets/images/dogum.png (falbg)
//
// Her açılışta 5 bölümden birer metin seçilir ve tek metin olarak birleştirilir:
//   Giris → 1Hisler → 2Olaylar → 3FizikSaglik → Veda
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
import '../../data/providers.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class _Entry {
  final int id;
  final String metin;
  const _Entry({required this.id, required this.metin});
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

  // ─── Veri yükle ────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final raw   = await rootBundle.loadString('assets/data/dogumharitasi.json');
    final data  = jsonDecode(raw) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    // JSON düz liste: {"dogumharitasi": [{id, metin, kosullar}, ...]}
    final pool = (data['dogumharitasi'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return _Entry(id: m['id'] as int, metin: m['metin'] as String);
    }).toList();

    final lastDate = prefs.getString('dh_last_date') ?? '';
    final lastId   = prefs.getInt('dh_bugun_id');

    String metin;

    if (lastDate == today && lastId != null) {
      // Aynı gün — cache'ten yükle
      final entry = pool.firstWhere(
          (e) => e.id == lastId, orElse: () => pool.first);
      metin = entry.metin;
    } else {
      // Yeni gün — no-repeat seç
      const shownKey = 'dh_gosterilen';
      var shown = prefs.getStringList(shownKey) ?? [];
      var available =
          pool.where((e) => !shown.contains('${e.id}')).toList();

      if (available.isEmpty) {
        // Hepsi gösterildi → son gösterilen hariç sıfırla
        final lastShownId = shown.isNotEmpty ? shown.last : null;
        shown = lastShownId != null ? [lastShownId] : [];
        await prefs.setStringList(shownKey, shown);
        available =
            pool.where((e) => e.id.toString() != lastShownId).toList();
        if (available.isEmpty) available = List.from(pool);
      }

      available.shuffle(_rng);
      final pick = available.first;
      shown.add('${pick.id}');
      await prefs.setStringList(shownKey, shown);
      await prefs.setString('dh_last_date', today);
      await prefs.setInt('dh_bugun_id', pick.id);
      metin = pick.metin;
    }

    final profile = ref.read(userProfileProvider);
    final replaced = VariableReplacer.replace(metin, profile.toVariableMap());

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
                          'DOĞUM HARİTASI',
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
    const flareThick = 88.0; // en: 2x (44*2) — kenara dik yön

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
          final flareLen  = size * 5.0; // boy: 5x — kenar boyunca uzanır
          final sideOffset = (flareLen - size) / 2; // her yöne taşma miktarı

          Widget flareImg() => Image.asset(
            'assets/images/red-light-line-png-2.png',
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );

          // Yatay flare (üst/alt kenar)
          Widget hFlare() => breathWrap(SizedBox(
            width: flareLen,
            height: flareThick,
            child: flareImg(),
          ));

          // Dikey flare (sol/sağ kenar) — RotatedBox layout boyutunu da döndürür
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
                  // ── Flare'ler ALTTA (görsel arkasında) ──────────────────
                  // Üst kenar
                  Positioned(
                    top: -flareThick / 2,
                    left: -sideOffset,
                    child: hFlare(),
                  ),
                  // Alt kenar
                  Positioned(
                    bottom: -flareThick / 2,
                    left: -sideOffset,
                    child: hFlare(),
                  ),
                  // Sol kenar
                  Positioned(
                    left: -flareThick / 2,
                    top: -sideOffset,
                    child: vFlare(),
                  ),
                  // Sağ kenar
                  Positioned(
                    right: -flareThick / 2,
                    top: -sideOffset,
                    child: vFlare(),
                  ),

                  // ── Kare görsel ÜSTTE ────────────────────────────────────
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
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 24),
      children: [
        _buildWheelChart(),
        // Metin kartı
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF9988FF).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            _metin ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.75,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Geri Git — scroll sonunda görünür
        GestureDetector(
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
        const SizedBox(height: 8),
      ],
    );
  }
}
