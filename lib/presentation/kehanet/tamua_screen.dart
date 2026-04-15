// C:/src/magnus_app/lib/presentation/kehanet/tamua_screen.dart
// Tamua — tepsi + taş bilardo animasyonu (4 sekme, 3s gecikme, ardından fal metni)

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

enum _TamuaAdim { yukleniyor, hazir, animasyon, icerik }

class _TamuaScreenState extends ConsumerState<TamuaScreen>
    with SingleTickerProviderStateMixin {
  _TamuaAdim _adim = _TamuaAdim.yukleniyor;
  String _metin = '';
  String _displayed = '';
  Timer? _typeTimer;
  int _charIndex = 0;

  // ── Boyutlar ─────────────────────────────────────────────────────────────────
  static const double _traySize  = 280.0;
  static const double _innerSize =  56.0;
  // Efektif sekme yarıçapı: tepsi iç kenarından taşın merkezi ne kadar uzak?
  static const double _bounceR   = _traySize / 2 - _innerSize / 2 - 6; // ≈ 102 px

  // ── Animasyon ────────────────────────────────────────────────────────────────
  late AnimationController _bounceCtrl;
  // Yol noktaları: P0(merkez), P1, P2, P3, P4 — 4 segment
  List<Offset> _waypoints = [];
  // Kümülatif duraklama noktaları: [0, d01/T, (d01+d12)/T, ..., 1]
  List<double> _segStops  = [];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _loadData();
  }

  // ── Yol Hesaplama ─────────────────────────────────────────────────────────────
  // Her sekme noktasında: önce saf bilardo yansıması hesaplanır,
  // sonra yön ±φ derece döndürülür (1. sekme: 30°, 2-3. sekme: 30-60° random).
  void _calculateBounce() {
    final rng = Random();
    const R   = _bounceR;

    // P0 → P1: merkez → rastgele açıyla ilk kenar
    final theta0 = rng.nextDouble() * 2 * pi;
    final p0 = Offset.zero;
    final p1 = Offset(R * cos(theta0), R * sin(theta0));

    // P1'deki saf yansıma: merkez→P1 tam radyal → geri dönüş = (-cos θ, -sin θ)
    // Bunun yerine 30° sap (hem sol hem sağ eşit ihtimalle)
    final dir1 = _deviateReflection(
      pureReflect: Offset(-cos(theta0), -sin(theta0)),
      inwardNormal: Offset(-cos(theta0), -sin(theta0)),
      deviationDeg: 30.0,
      rng: rng,
    );
    final p2 = _circleHit(p1, dir1, R);

    // P2'deki saf bilardo yansıması + 30-60° sapma
    final dir2 = _deviateReflection(
      pureReflect: _billiardReflect(dir1, p2),
      inwardNormal: _inward(p2),
      deviationDeg: 30 + rng.nextDouble() * 30, // 30-60°
      rng: rng,
    );
    final p3 = _circleHit(p2, dir2, R);

    // P3'teki saf bilardo yansıması + 30-60° sapma
    final dir3 = _deviateReflection(
      pureReflect: _billiardReflect(dir2, p3),
      inwardNormal: _inward(p3),
      deviationDeg: 30 + rng.nextDouble() * 30,
      rng: rng,
    );
    final p4 = _circleHit(p3, dir3, R);

    _waypoints = [p0, p1, p2, p3, p4];

    // Segment ağırlıkları: mesafe orantılı → sabit hız
    final dists = [
      (p1 - p0).distance,
      (p2 - p1).distance,
      (p3 - p2).distance,
      (p4 - p3).distance,
    ];
    final total = dists.fold(0.0, (a, b) => a + b);
    double acc  = 0.0;
    _segStops   = [0.0];
    for (final d in dists) {
      acc += d / total;
      _segStops.add(acc.clamp(0.0, 1.0));
    }
  }

  // Saf bilardo yansıması: gelen yön dir → çember üstündeki p noktasına çarpar
  static Offset _billiardReflect(Offset dir, Offset p) {
    final n   = _inward(p); // içe bakan birim normal
    final dot = dir.dx * n.dx + dir.dy * n.dy;
    return Offset(dir.dx - 2 * dot * n.dx, dir.dy - 2 * dot * n.dy);
  }

  // p noktasındaki içe bakan birim normal (merkezden p'ye ters yön)
  static Offset _inward(Offset p) {
    final d = p.distance;
    if (d < 0.001) return const Offset(1, 0);
    return Offset(-p.dx / d, -p.dy / d);
  }

  // pureReflect yönünü ±deviationDeg döndür; sonuç içe bakmalı (>0 inward bileşen)
  static Offset _deviateReflection({
    required Offset pureReflect,
    required Offset inwardNormal,
    required double deviationDeg,
    required Random rng,
  }) {
    final phi  = deviationDeg * pi / 180;
    final sign = rng.nextBool() ? 1.0 : -1.0;
    final dir  = _rotate(pureReflect, sign * phi);
    // İçe bakan bileşen kontrolü; yanlış işaretse işareti çevir
    final dot = dir.dx * inwardNormal.dx + dir.dy * inwardNormal.dy;
    return dot >= 0 ? dir : _rotate(pureReflect, -sign * phi);
  }

  // Vektörü φ açısı kadar döndür (CCW)
  static Offset _rotate(Offset v, double phi) {
    final c = cos(phi), s = sin(phi);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  /// from noktasından dir yönünde giden ışın ile R yarıçaplı çemberin
  /// from'dan farklı kesişim noktasını döndürür.
  static Offset _circleHit(Offset from, Offset dir, double R) {
    // |from + t·dir|² = R²  →  t² + 2bt + c = 0
    // b = from·dir,  c = |from|² − R²
    final b    = from.dx * dir.dx + from.dy * dir.dy;
    final c    = from.dx * from.dx + from.dy * from.dy - R * R;
    final disc = (b * b - c).clamp(0.0, double.infinity);
    final sqD  = sqrt(disc);
    final t1   = -b + sqD;
    final t2   = -b - sqD;
    // "from" çember üstündeyse c≈0, t'lerden biri ≈0 diğeri ≈ -2b.
    // Epsilon'dan büyük pozitif t'yi seç; ikisi de buysa büyüğünü al.
    const eps = 0.5;
    final tUse = (t1 > eps && t2 > eps)
        ? max(t1, t2)
        : (t1 > eps ? t1 : (t2 > eps ? t2 : max(t1.abs(), t2.abs())));
    return Offset(from.dx + tUse * dir.dx, from.dy + tUse * dir.dy);
  }

  // ── Animasyon değerinden konum ────────────────────────────────────────────────
  Offset _lerpPos(double t) {
    if (_segStops.isEmpty || _waypoints.length < 2) return Offset.zero;
    t = t.clamp(0.0, 1.0);
    for (int i = 0; i < _segStops.length - 1; i++) {
      final s0 = _segStops[i];
      final s1 = _segStops[i + 1];
      if (t <= s1 + 0.0001) {
        final span   = s1 - s0;
        final local  = span < 0.0001 ? 1.0 : ((t - s0) / span).clamp(0.0, 1.0);
        // İlk segment easeIn, son segment easeOut, ortalar linear
        final curved = i == 0
            ? Curves.easeIn.transform(local)
            : (i == _segStops.length - 2
                ? Curves.easeOut.transform(local)
                : local);
        return Offset.lerp(_waypoints[i], _waypoints[i + 1], curved)!;
      }
    }
    return _waypoints.last;
  }

  // ── Veri Yükleme ─────────────────────────────────────────────────────────────
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

    // Görseller çıktı, 3 saniye bekle sonra hareket başlasın
    setState(() => _adim = _TamuaAdim.hazir);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _adim = _TamuaAdim.animasyon);
      _bounceCtrl.forward().then((_) {
        if (!mounted) return;
        setState(() => _adim = _TamuaAdim.icerik);
        _startTypewriter();
      });
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

  // ── Tepsi widget'ı ────────────────────────────────────────────────────────────
  Widget _buildTray() {
    return SizedBox(
      width:  _traySize,
      height: _traySize,
      child: AnimatedBuilder(
        animation: _bounceCtrl,
        builder: (context, _) {
          final pos = _lerpPos(_bounceCtrl.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/kehanet/tauma_tray.png',
                width: _traySize, height: _traySize, fit: BoxFit.contain,
              ),
              Transform.translate(
                offset: pos,
                child: Image.asset(
                  'assets/images/kehanet/tauma_inner.png',
                  width: _innerSize, height: _innerSize, fit: BoxFit.contain,
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
            // ── Başlık ──────────────────────────────────────────────────────
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
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.bold, letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── İçerik ──────────────────────────────────────────────────────
            if (_adim == _TamuaAdim.yukleniyor)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF55FF)),
                ),
              )
            else ...[
              // Tepsi — hazir/animasyon/icerik adımlarında görünür
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: _buildTray(),
                ),
              ),

              if (_adim == _TamuaAdim.hazir || _adim == _TamuaAdim.animasyon)
                // Animasyon beklerken / oynarken alt boşluk
                const Expanded(child: SizedBox.shrink())
              else ...[
                // ── Fal metni ─────────────────────────────────────────────
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
                            color: Colors.white, fontSize: 16,
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
