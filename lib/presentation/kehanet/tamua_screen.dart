// C:/src/magnus_app/lib/presentation/kehanet/tamua_screen.dart
// Tamua — tepsi görseli üzerinde bilardo sekme animasyonu, ardından fal metni

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

class TamuaScreen extends ConsumerStatefulWidget {
  const TamuaScreen({super.key});

  @override
  ConsumerState<TamuaScreen> createState() => _TamuaScreenState();
}

enum _TamuaAdim { yukleniyor, animasyon, icerik }

class _TamuaScreenState extends ConsumerState<TamuaScreen>
    with SingleTickerProviderStateMixin {
  _TamuaAdim _adim = _TamuaAdim.yukleniyor;
  String _metin = '';
  String _displayed = '';
  Timer? _typeTimer;
  int _charIndex = 0;

  // ── Bounce animasyon ────────────────────────────────────────────────────────
  late AnimationController _bounceCtrl;

  // Ekranda gösterim boyutları
  static const double _traySize  = 280.0; // tepsi
  static const double _innerSize =  56.0; // sekme taşı
  // Merkez-kenar arası efektif yarıçap (içten dolduracak payı bırak)
  static const double _bounceR   = _traySize / 2 - _innerSize / 2 - 6; // ≈ 102 px

  // Pre-hesaplanan yol noktaları (tepsi merkezine göre px cinsinden)
  List<Offset> _waypoints  = [];
  // Her segmentin [0,1] içindeki kümülatif duraklama noktaları: [0, w0, w0+w1, 1]
  List<double> _segStops   = [];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _loadData();
  }

  // ── Bilardo yolu hesapla ─────────────────────────────────────────────────────
  // P0 = merkez, P1 = ilk kenar, P2 = ikinci kenar (yansımayla), P3 = üçüncü kenar
  void _calculateBounce() {
    final rng = Random();
    const R = _bounceR;

    // İlk açı: rastgele
    final theta0 = rng.nextDouble() * 2 * pi;
    final p0 = Offset.zero;
    final p1 = Offset(R * cos(theta0), R * sin(theta0));

    // P0→P1 merkez-kenar topa fiziksel yansıma yapar (geri döner).
    // Bunun yerine ±60-120 derece sapma ekle → güzel kiriş çizer.
    final sign  = rng.nextBool() ? 1.0 : -1.0;
    final phi   = sign * (pi / 3 + rng.nextDouble() * pi / 3); // 60-120°
    final theta1 = theta0 + pi + phi;
    final dir1   = Offset(cos(theta1), sin(theta1));
    final p2     = _circleHit(p1, dir1, R);

    // P1→P2 kenarına gerçek bilardo yansıması
    final n2   = Offset(p2.dx / p2.distance, p2.dy / p2.distance); // dış normal
    final dot2 = dir1.dx * n2.dx + dir1.dy * n2.dy;
    final dir2 = Offset(dir1.dx - 2 * dot2 * n2.dx,
                        dir1.dy - 2 * dot2 * n2.dy);
    final p3   = _circleHit(p2, dir2, R);

    _waypoints = [p0, p1, p2, p3];

    // Segment ağırlıkları: mesafe orantılı → her şey aynı hızda gider
    final d01 = (p1 - p0).distance;
    final d12 = (p2 - p1).distance;
    final d23 = (p3 - p2).distance;
    final tot = d01 + d12 + d23;
    _segStops = [0.0, d01 / tot, (d01 + d12) / tot, 1.0];
  }

  /// Çemberle kesişim: from noktasından dir yönünde giden ışının R yarıçaplı çemberle
  /// kesişim noktası (from ≠ kesişim, yani başlangıç noktasından farklı olan).
  static Offset _circleHit(Offset from, Offset dir, double R) {
    // |from + t*dir|² = R²  →  t² + 2bt + (|from|²-R²) = 0
    final b    = from.dx * dir.dx + from.dy * dir.dy;
    final c    = from.dx * from.dx + from.dy * from.dy - R * R;
    final disc = b * b - c;
    if (disc < 0) return from; // degenerate (shouldn't happen)
    final sqrtD = sqrt(disc.abs());
    final t1 = -b + sqrtD;
    final t2 = -b - sqrtD;
    const eps = 0.5;
    // İkisinden pozitif ve epsilon'dan büyük olanı seç
    final t = (t1 > eps) ? t1 : ((t2 > eps) ? t2 : t1.abs());
    return Offset(from.dx + t * dir.dx, from.dy + t * dir.dy);
  }

  /// Animasyon değeri t ∈ [0,1] için ara pozisyonu döndür.
  Offset _lerpPosition(double t) {
    if (_segStops.isEmpty || _waypoints.length < 2) return Offset.zero;
    t = t.clamp(0.0, 1.0);
    for (int i = 0; i < _segStops.length - 1; i++) {
      final s0 = _segStops[i];
      final s1 = _segStops[i + 1];
      if (t <= s1 + 0.0001) {
        final span   = s1 - s0;
        final localT = span < 0.0001 ? 1.0 : ((t - s0) / span).clamp(0.0, 1.0);
        // İlk segment easeIn, son segment easeOut, ortalar linear
        final curvedT = i == 0
            ? Curves.easeIn.transform(localT)
            : (i == _segStops.length - 2
                ? Curves.easeOut.transform(localT)
                : localT);
        return Offset.lerp(_waypoints[i], _waypoints[i + 1], curvedT)!;
      }
    }
    return _waypoints.last;
  }

  // ── Veri yükleme ─────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final str  = await rootBundle.loadString('assets/data/tamua.json');
    final data = jsonDecode(str);
    final List all = data['tamua'] ?? [];

    final prefs = await SharedPreferences.getInstance();
    const key   = 'tamua_gosterilen';
    var shown   = prefs.getStringList(key) ?? [];

    var eligible = all.where((e) => !shown.contains(e['id'].toString())).toList();
    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown    = [];
      eligible = List.from(all);
    }

    eligible.shuffle(Random());
    final selected = eligible.first;
    _metin = selected['metin'] ?? '';
    final profile = ref.read(userProfileProvider);
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());
    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);

    if (!mounted) return;

    _calculateBounce();
    setState(() => _adim = _TamuaAdim.animasyon);

    _bounceCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() => _adim = _TamuaAdim.icerik);
      _startTypewriter();
    });
  }

  void _startTypewriter() {
    _typeTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (_charIndex >= _metin.length) { t.cancel(); return; }
      setState(() => _displayed = _metin.substring(0, ++_charIndex));
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _bounceCtrl.dispose();
    super.dispose();
  }

  // ── Tepsi + sekan taşı widget'ı ──────────────────────────────────────────────
  Widget _buildTray() {
    return SizedBox(
      width:  _traySize,
      height: _traySize,
      child: AnimatedBuilder(
        animation: _bounceCtrl,
        builder: (context, child) {
          final pos = _lerpPosition(_bounceCtrl.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Tepsi görseli (arka plan, dairesel)
              Image.asset(
                'assets/images/kehanet/tauma_tray.png',
                width:  _traySize,
                height: _traySize,
                fit:    BoxFit.contain,
              ),
              // Sekme taşı — merkezden offset ile konumlanır
              Transform.translate(
                offset: pos,
                child: Image.asset(
                  'assets/images/kehanet/tauma_inner.png',
                  width:  _innerSize,
                  height: _innerSize,
                  fit:    BoxFit.contain,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Başlık ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'TAMUA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── İçerik ───────────────────────────────────────────────────────
            if (_adim == _TamuaAdim.yukleniyor)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF55FF)),
                ),
              )
            else ...[
              // Tepsi animasyonu — animasyon ve icerik adımlarında görünür
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: _buildTray(),
                ),
              ),

              if (_adim == _TamuaAdim.animasyon)
                // Animasyon oynarken alt alan boş
                const Expanded(child: SizedBox.shrink())
              else ...[
                // ── Fal metni — dikeyde ortalanmış, uzunsa kaydırılabilir ──
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 24,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _displayed,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)],
                        ),
                        border: Border.all(
                          color: const Color(0xFFFF55FF).withValues(alpha: 0.80),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Kapat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
