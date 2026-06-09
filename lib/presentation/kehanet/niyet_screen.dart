// C:/src/magnus_app/lib/presentation/kehanet/niyet_screen.dart
// Niyet Falı — kazı-kazan tarzı metin açma ekranı

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ad_service.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

class NiyetScreen extends ConsumerStatefulWidget {
  const NiyetScreen({super.key});

  @override
  ConsumerState<NiyetScreen> createState() => _NiyetScreenState();
}

enum _NiyetAdim { yukleniyor, kazima, tamamlandi }

class _NiyetScreenState extends ConsumerState<NiyetScreen>
    with SingleTickerProviderStateMixin {
  _NiyetAdim _adim = _NiyetAdim.yukleniyor;
  String _metin = '';

  // ── Kazıma durumu ──────────────────────────────────────────────────────────
  bool _adShown = false; // ilk kazımada bir kez rewarded reklam gösterilir
  final List<Offset> _scratchPoints = [];
  // Izgara tabanlı kazılan alan takibi (hassas % hesabı için)
  final Set<int> _scratchedCells = {};
  static const int _gridCols = 32;
  static const int _gridRows = 32;
  double _scratchPct = 0.0;
  bool _fullyRevealed = false;
  // Kutu boyutları — GestureDetector'ın içindeki LayoutBuilder'dan beslenir
  double _boxW = 1.0;
  double _boxH = 1.0;

  // ── Tam açılma animasyonu ──────────────────────────────────────────────────
  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim; // örtü opaklığı: 1 → 0

  static const double _brushRadius = 30.0;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _revealAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  // ── Metin yükle (SharedPreferences tekrar gösterilmeme) ───────────────────
  Future<void> _loadData() async {
    final str  = await rootBundle.loadString('assets/data/niyet.json');
    final data = jsonDecode(str) as Map<String, dynamic>;
    final List all = data['niyet'] ?? [];

    final prefs = await SharedPreferences.getInstance();
    const key   = 'niyet_gosterilen';
    var shown   = prefs.getStringList(key) ?? [];

    final profile = ref.read(userProfileProvider);

    // Koşul filtresi + daha önce gösterilmemiş
    var eligible = all.where((e) {
      final kosullar = e['kosullar'] as List? ?? [];
      if (kosullar.isNotEmpty) {
        final varMap = profile.toVariableMap();
        for (final k in kosullar) {
          final val = varMap[k['degisken']];
          if (val == null || val != k['deger']) return false;
        }
      }
      return !shown.contains(e['id'].toString());
    }).toList();

    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown    = [];
      eligible = all.where((e) {
        final kosullar = e['kosullar'] as List? ?? [];
        if (kosullar.isEmpty) return true;
        final varMap = profile.toVariableMap();
        for (final k in kosullar) {
          final val = varMap[k['degisken']];
          if (val == null || val != k['deger']) return false;
        }
        return true;
      }).toList();
    }

    eligible.shuffle(Random());
    final selected = eligible.first as Map<String, dynamic>;
    _metin = VariableReplacer.replace(
        selected['metin'] as String? ?? '', profile.toVariableMap());
    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);

    if (mounted) setState(() => _adim = _NiyetAdim.kazima);
  }

  // ── Parmak hareketi → kazıma ───────────────────────────────────────────────
  void _onPanUpdate(DragUpdateDetails d) {
    if (_fullyRevealed) return;

    // İlk kazımada rewarded reklam — sonrasında normal devam
    if (!_adShown) {
      _adShown = true;
      AdService.instance.showRewarded(
        onRewarded: () {}, // reklam sonrası kullanıcı yeniden kazır
        onFailed:   () {},
      );
      return;
    }

    final pos = d.localPosition;
    if (pos.dx < 0 || pos.dy < 0 || pos.dx > _boxW || pos.dy > _boxH) return;

    setState(() {
      _scratchPoints.add(pos);

      // Izgara hücrelerini işaretle (fırça yarıçapı kadar)
      final cellW = _boxW / _gridCols;
      final cellH = _boxH / _gridRows;
      final cx = (pos.dx / cellW).floor();
      final cy = (pos.dy / cellH).floor();
      const r = 2; // izgara hücre yarıçapı
      for (int dx = -r; dx <= r; dx++) {
        for (int dy = -r; dy <= r; dy++) {
          final nx = (cx + dx).clamp(0, _gridCols - 1);
          final ny = (cy + dy).clamp(0, _gridRows - 1);
          _scratchedCells.add(ny * _gridCols + nx);
        }
      }

      _scratchPct = _scratchedCells.length / (_gridCols * _gridRows);

      if (!_fullyRevealed && _scratchPct >= 0.40) {
        _fullyRevealed = true;
        _revealCtrl.forward().then((_) {
          if (mounted) setState(() => _adim = _NiyetAdim.tamamlandi);
        });
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Başlık ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Expanded(child: Text('NİYET',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.bold, letterSpacing: 1.2))),
                const SizedBox(width: 48),
              ]),
            ),

            // ── İçerik ──────────────────────────────────────────────────────
            if (_adim == _NiyetAdim.yukleniyor)
              const Expanded(child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF55FF)))),

            if (_adim != _NiyetAdim.yukleniyor) ...[
              // Kazı-kazan kutusu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: LayoutBuilder(builder: (ctx, bc) {
                    _boxW = bc.maxWidth;
                    _boxH = bc.maxHeight;
                    return _buildScratchCard(bc.maxWidth, bc.maxHeight);
                  }),
                ),
              ),

              // Alt alan — sabit yükseklik (86 px) → Expanded kaymasın
              SizedBox(
                height: 86,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _adim == _NiyetAdim.tamamlandi
                      ? Padding(
                          key: const ValueKey('kapat'),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)]),
                                border: Border.all(
                                  color: const Color(0xFFFF55FF)
                                      .withValues(alpha: 0.80),
                                  width: 1.5),
                              ),
                              child: const Center(child: Text('Kapat',
                                style: TextStyle(color: Colors.white,
                                    fontSize: 16, fontWeight: FontWeight.bold))),
                            ),
                          ),
                        )
                      : Padding(
                          key: const ValueKey('talim'),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: SizedBox(
                            height: 50,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('☝️', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Parmağınla niyetini kazı!',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 15,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Kazıma ilerlemesine göre kenarlık/glow rengi ──────────────────────────
  Color _scratchGlowColor() {
    if (_adim == _NiyetAdim.tamamlandi) return const Color(0xFF00FF88);
    final t = (_scratchPct / 0.40).clamp(0.0, 1.0);
    if (t < 0.5) {
      // loş kırmızı → parlak kırmızı
      final s = t / 0.5;
      return HSVColor.fromAHSV(1.0, 0, 0.55 + s * 0.45, 0.20 + s * 0.80).toColor();
    } else {
      // parlak kırmızı → parlak mavi (RGB renk süpürmesi)
      final s = (t - 0.5) / 0.5;
      return HSVColor.fromAHSV(1.0, s * 240, 1.0, 1.0).toColor();
    }
  }

  // ── Kazı-kazan kartı ───────────────────────────────────────────────────────
  Widget _buildScratchCard(double w, double h) {
    final glowColor = _scratchGlowColor();
    final intensity = _adim == _NiyetAdim.tamamlandi
        ? 1.0
        : (_scratchPct / 0.60).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: glowColor.withValues(alpha: 0.25 + intensity * 0.65),
          width: 1.5,
        ),
        boxShadow: [
          // İç halka — yoğun, dar
          BoxShadow(
            color: glowColor.withValues(alpha: 0.20 + intensity * 0.45),
            blurRadius: 4 + intensity * 10,
            spreadRadius: intensity * 2,
          ),
          // Dış halo — kısa mesafeli, yumuşak
          BoxShadow(
            color: glowColor.withValues(alpha: 0.08 + intensity * 0.18),
            blurRadius: 8 + intensity * 12,
            spreadRadius: intensity * 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: w, height: h,
          child: Stack(children: [
            // ── Arka plan: metin içeriği ────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF12063A), Color(0xFF1E0A4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Text(
                    _metin,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.8,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),

            // ── Kazı örtüsü ─────────────────────────────────────────────
            if (!_fullyRevealed || _revealCtrl.value < 1.0)
              AnimatedBuilder(
                animation: _revealAnim,
                builder: (ctx, _) => GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(w, h),
                      painter: _ScratchPainter(
                        points: List<Offset>.unmodifiable(_scratchPoints),
                        coverOpacity: 1.0 - _revealAnim.value,
                        brushRadius: _brushRadius,
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Örtü boyayıcısı ─────────────────────────────────────────────────────────
class _ScratchPainter extends CustomPainter {
  final List<Offset> points;
  final double coverOpacity; // 1.0 = tam örtülü, 0.0 = tamamen açık
  final double brushRadius;

  const _ScratchPainter({
    required this.points,
    required this.coverOpacity,
    required this.brushRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (coverOpacity <= 0) return;

    // saveLayer: BlendMode.clear'ın doğru çalışması için ayrı katman gerekli
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: coverOpacity),
    );

    final rect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(18));

    // ── Koyu mor zemin ─────────────────────────────────────────────────────
    canvas.drawRRect(rect,
        Paint()..color = const Color(0xFF2D1060));

    // ── Dekoratif altın nokta deseni ──────────────────────────────────────
    final dotPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = spacing; x < size.width - 4; x += spacing) {
      for (double y = spacing; y < size.height - 4; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
      }
    }

    // ── Merkez yıldız/glow ─────────────────────────────────────────────────
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD4AF37).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width:  size.width * 0.8,
          height: size.width * 0.8));
    canvas.drawRect(Offset.zero & size, centerGlow);

    // ── "NİYET" yazısı (soluk, arka plan ipucu) ───────────────────────────
    final tp = TextPainter(
      text: const TextSpan(
        text: 'NİYET',
        style: TextStyle(
          color: Color(0x22D4AF37),
          fontSize: 64,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));

    // ── Kazınan alanları sil ───────────────────────────────────────────────
    final erasePaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, brushRadius, erasePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchPainter old) =>
      !identical(old.points, points) ||
      old.coverOpacity != coverOpacity;
}
