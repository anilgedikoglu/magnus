// Kaynak metinler: C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/AskUyumu/
// JSON: assets/data/askuyumu.json
// Arka plan: assets/images/askuyumu.png (üst 52% görsel, alta siyah fade)
// Akış: Dokunma (3s basma) → Kum saati yükleme (5s) → 7 bar sonuç

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// ─── Veri modeli ──────────────────────────────────────────────────────────────

class _BarResult {
  final String key;
  final String label;
  final Color color;
  final int pct;
  final String metin;
  const _BarResult({
    required this.key,
    required this.label,
    required this.color,
    required this.pct,
    required this.metin,
  });
}

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class AskUyumuScreen extends ConsumerStatefulWidget {
  const AskUyumuScreen({super.key});

  @override
  ConsumerState<AskUyumuScreen> createState() => _AskUyumuScreenState();
}

class _AskUyumuScreenState extends ConsumerState<AskUyumuScreen>
    with TickerProviderStateMixin {
  // Faz: 1=dokunma, 2=yükleme, 3=sonuç
  int _phase = 1;

  // Faz 1 — basma doldurma animasyonu
  late AnimationController _fillCtrl;

  // Faz 3 — bar genişleme animasyonu
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  final _rng = Random();
  List<_BarResult>? _results;

  @override
  void initState() {
    super.initState();

    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _gotoPhase2();
        }
      });

    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  // ── Faz 2 başlatıcı ───────────────────────────────────────────────────────

  Future<void> _gotoPhase2() async {
    if (!mounted) return;
    setState(() => _phase = 2);

    await Future.wait<void>([
      _metinleriHazirla(),
      Future.delayed(const Duration(seconds: 5)),
    ]);
    if (!mounted) return;

    // Günlük kullanım tarihi kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('askuyumu_bugun_tarih',
        DateTime.now().toIso8601String().substring(0, 10));
    if (!mounted) return;

    setState(() => _phase = 3);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barCtrl.forward();
    });
  }

  // ── Veri yükleme ──────────────────────────────────────────────────────────

  Future<void> _metinleriHazirla() async {
    try {
      final profile = ref.read(userProfileProvider);
      final raw = await rootBundle.loadString('assets/data/askuyumu.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final barsData = data['bars'] as Map<String, dynamic>;
      final uyumData = data['uyum'] as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();

      // 6 bar kategorisi
      final barDefs = [
        ('ask', 'Aşk', const Color(0xFFFF4466)),
        ('aile', 'Aile', const Color(0xFFFF8844)),
        ('maddi', 'Maddi', const Color(0xFFFFDD00)),
        ('ten', 'Ten', const Color(0xFFAA44FF)),
        ('vizyon', 'Vizyon', const Color(0xFF4488FF)),
        ('iletisim', 'İletişim', const Color(0xFF44DDCC)),
      ];

      final results = <_BarResult>[];

      for (final (key, label, color) in barDefs) {
        final catData = barsData[key] as Map<String, dynamic>;
        // Rastgele aralık seç
        const ranges = ['0-25', '25-50', '50-75', '75-100'];
        final pickedRange = ranges[_rng.nextInt(ranges.length)];
        final rangeEntries = (catData[pickedRange] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        final metin = _pickEntry(prefs, 'askuyumu_${key}_gosterilen', rangeEntries, profile.toVariableMap());

        // Bar değeri: aralık içinde rastgele
        final pct = _rangeValue(pickedRange);

        results.add(_BarResult(
          key: key,
          label: label,
          color: color,
          pct: pct,
          metin: metin,
        ));
      }

      // 7. bar: uyum
      final uyumKey = _uyumKey(profile.maritalStatus);
      final uyumEntries = (uyumData[uyumKey] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final uyumMetin = _pickEntry(prefs, 'askuyumu_uyum_gosterilen', uyumEntries, profile.toVariableMap());
      final uyumPct = _rng.nextInt(101);

      results.add(_BarResult(
        key: 'uyum',
        label: 'Uyum',
        color: const Color(0xFF44DD66),
        pct: uyumPct,
        metin: uyumMetin,
      ));

      if (mounted) {
        setState(() => _results = results);
      }
    } catch (_) {
      // sessizce geç, sonuçlar null kalırsa fallback gösterilir
    }
  }

  String _uyumKey(String maritalStatus) {
    switch (maritalStatus) {
      case 'evli':
        return 'evli';
      case 'iliski_var':
      case 'nisanli':
      case 'flort':
      case 'platonik':
      case 'karisik':
        return 'iliskisivar';
      default:
        return 'iliskisiyok';
    }
  }

  int _rangeValue(String range) {
    switch (range) {
      case '0-25':
        return _rng.nextInt(26); // 0..25
      case '25-50':
        return 25 + _rng.nextInt(26); // 25..50
      case '50-75':
        return 50 + _rng.nextInt(26); // 50..75
      case '75-100':
        return 75 + _rng.nextInt(26); // 75..100
      default:
        return _rng.nextInt(101);
    }
  }

  String _pickEntry(
    SharedPreferences prefs,
    String prefsKey,
    List<Map<String, dynamic>> entries,
    Map<String, String> varMap,
  ) {
    if (entries.isEmpty) return '';

    var shown = prefs.getStringList(prefsKey) ?? [];
    var unseen = entries.where((e) => !shown.contains('${e['id']}')).toList();
    if (unseen.isEmpty) {
      shown = [];
      prefs.setStringList(prefsKey, shown);
      unseen = List.from(entries);
    }
    unseen.shuffle(_rng);
    final pick = unseen.first;
    shown.add('${pick['id']}');
    prefs.setStringList(prefsKey, shown);

    return VariableReplacer.replace(pick['metin'] as String, varMap);
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          SafeArea(
            child: _phase == 1
                ? _buildPhase1()
                : _phase == 2
                    ? _buildPhase2()
                    : _buildPhase3(),
          ),
        ],
      ),
    );
  }

  // ── Arka plan ─────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: 0.52,
            widthFactor: 1.0,
            child: Image.asset(
              'assets/images/askuyumu.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0A0018)),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.25, 0.52, 0.65, 1.0],
              colors: [
                Color(0x00000000),
                Color(0x22000000),
                Color(0xBB000000),
                Color(0xEE000000),
                Color(0xFF000000),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(
                Icons.chevron_left_rounded, color: Colors.white, size: 22),
          ),
        ),
        const Spacer(),
        const Text(
          'Aşk Uyumu',
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        const SizedBox(width: 36),
      ]),
    );
  }

  // ── Faz 1: dokunma ekranı ─────────────────────────────────────────────────

  Widget _buildPhase1() {
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Uyumunu merak ettiğin kişiyi zihninden geçir ve alttaki yuvarlağa dokun!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 60),
            _buildHoldButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ]);
  }

  Widget _buildHoldButton() {
    const double buttonRadius = 40.0;
    return GestureDetector(
      onTapDown: (_) => _fillCtrl.forward(),
      onTapUp: (_) => _fillCtrl.reverse(),
      onTapCancel: () => _fillCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _fillCtrl,
        builder: (context, child) {
          return SizedBox(
            width: buttonRadius * 2,
            height: buttonRadius * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Arka plan daire
                Container(
                  width: buttonRadius * 2,
                  height: buttonRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
                // Dolum dairesi
                CustomPaint(
                  size: const Size(buttonRadius * 2, buttonRadius * 2),
                  painter: _FillCirclePainter(
                    progress: _fillCtrl.value,
                    maxRadius: buttonRadius,
                    color: const Color(0xFFFF4466),
                  ),
                ),
                // Kalp ikonu
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Faz 2: yükleme ekranı ─────────────────────────────────────────────────

  Widget _buildPhase2() {
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _HourglassWidget(),
            const SizedBox(height: 20),
            const Text(
              'Uyumun hesaplanıyor...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ── Faz 3: sonuç ekranı ───────────────────────────────────────────────────

  Widget _buildPhase3() {
    final results = _results;
    if (results == null) {
      return Column(children: [
        _buildHeader(),
        const Expanded(
          child: Center(
            child: Text(
              'Sonuçlar yüklenemedi.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ]);
    }

    return Column(children: [
      _buildHeader(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          children: [
            for (final bar in results) _buildBarCard(bar),
            const SizedBox(height: 8),
            _buildExitButton(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    ]);
  }

  Widget _buildBarCard(_BarResult bar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bar.color.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık + yüzde
            Text(
              '${bar.label}  %${bar.pct}',
              style: TextStyle(
                color: bar.color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Animasyonlu bar
            AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) {
                final widthFactor = (bar.pct / 100.0) * _barAnim.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      FractionallySizedBox(
                        widthFactor: widthFactor,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                bar.color.withValues(alpha: 0.7),
                                bar.color,
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
            bar.metin.isNotEmpty
                ? RichTextParser.build(
                    bar.metin,
                    style: const TextStyle(
                      color: Color(0xEEFFFFFF),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildExitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              SizedBox(width: 2),
              Text(
                'Çıkış',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dolum dairesi painter ───────────────────────────────────────────────────

class _FillCirclePainter extends CustomPainter {
  final double progress;
  final double maxRadius;
  final Color color;

  const _FillCirclePainter({
    required this.progress,
    required this.maxRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = progress * maxRadius;
    if (radius <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(_FillCirclePainter old) =>
      old.progress != progress;
}

// ─── Kum saati animasyonu ─────────────────────────────────────────────────────

class _HourglassWidget extends StatefulWidget {
  @override
  State<_HourglassWidget> createState() => _HourglassWidgetState();
}

class _HourglassWidgetState extends State<_HourglassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _top = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _top = !_top);
          _ctrl.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Icon(
        _top ? Icons.hourglass_top_rounded : Icons.hourglass_bottom_rounded,
        key: ValueKey(_top),
        color: const Color(0xFFFF4466),
        size: 56,
      ),
    );
  }
}
