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

  // ─── JSON parse ────────────────────────────────────────────────────────────

  List<_Entry> _parseSection(List raw) => raw.map((e) {
    final m = e as Map<String, dynamic>;
    return _Entry(id: m['id'] as int, metin: m['metin'] as String);
  }).toList();

  // ─── No-repeat: havuzdan bir metin seç, ID kaydet ──────────────────────────

  String _pick(SharedPreferences prefs, String key, List<_Entry> pool) {
    if (pool.isEmpty) return '';
    var shown = prefs.getStringList(key) ?? [];
    var unseen = pool.where((e) => !shown.contains('${e.id}')).toList();
    if (unseen.isEmpty) {
      shown = [];
      prefs.setStringList(key, []);
      unseen = List.from(pool);
    }
    unseen.shuffle(_rng);
    final pick = unseen.first;
    shown.add('${pick.id}');
    prefs.setStringList(key, shown);
    prefs.setInt('dh_id_$key', pick.id);
    return pick.metin;
  }

  // ─── Entry'yi ID'ye göre bul (aynı gün yeniden yükleme) ──────────────────

  String _findById(List<_Entry> pool, int id) {
    return pool.firstWhere((e) => e.id == id,
        orElse: () => pool.isNotEmpty ? pool.first : const _Entry(id: -1, metin: '')).metin;
  }

  // ─── Veri yükle ────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final raw   = await rootBundle.loadString('assets/data/dogumharitasi.json');
    final data  = jsonDecode(raw) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastDate = prefs.getString('dh_last_date') ?? '';

    final giris   = _parseSection(data['giris']   as List);
    final hisler  = _parseSection(data['hisler']  as List);
    final olaylar = _parseSection(data['olaylar'] as List);
    final fizik   = _parseSection(data['fizik']   as List);
    final veda    = _parseSection(data['veda']    as List);

    String gMetin, hMetin, oMetin, fMetin, vMetin;

    if (lastDate == today) {
      // Aynı gün — cache'ten yükle
      gMetin = _findById(giris,   prefs.getInt('dh_id_dh_giris')   ?? -1);
      hMetin = _findById(hisler,  prefs.getInt('dh_id_dh_hisler')  ?? -1);
      oMetin = _findById(olaylar, prefs.getInt('dh_id_dh_olaylar') ?? -1);
      fMetin = _findById(fizik,   prefs.getInt('dh_id_dh_fizik')   ?? -1);
      vMetin = _findById(veda,    prefs.getInt('dh_id_dh_veda')    ?? -1);
    } else {
      // Yeni gün — taze seç
      gMetin = _pick(prefs, 'dh_giris',   giris);
      hMetin = _pick(prefs, 'dh_hisler',  hisler);
      oMetin = _pick(prefs, 'dh_olaylar', olaylar);
      fMetin = _pick(prefs, 'dh_fizik',   fizik);
      vMetin = _pick(prefs, 'dh_veda',    veda);
      await prefs.setString('dh_last_date', today);
    }

    // 5 bölümü tek metin olarak birleştir
    final combined = [gMetin, hMetin, oMetin, fMetin, vMetin]
        .where((t) => t.isNotEmpty)
        .join('\n\n');

    final profile = ref.read(userProfileProvider);
    final metin   = VariableReplacer.replace(combined, profile.toVariableMap());

    if (!mounted) return;
    setState(() {
      _metin   = metin;
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
