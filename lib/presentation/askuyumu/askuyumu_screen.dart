// Kaynak metinler: C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/AskUyumu/
// JSON: assets/data/askuyumu.json
// Arka plan: assets/images/askuyumu.png
// Akış: Burç seçimi (döner çark) → Basma (3s) → Kum saati (5s) → 7 bar sonuç

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../data/providers.dart';

// ─── Burç listesi (index 0=Koç … 11=Balık) ───────────────────────────────────
const _kBurclar = [
  'Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak',
  'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık',
];

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
  // Faz: 1=seçim+dokunma, 2=yükleme, 3=sonuç
  int _phase = 1;

  // ── Çark durumu ──────────────────────────────────────────────────────────
  // Görsel snap offset: burç merkezleri π/6*n değil π/6*n+π/12 konumunda
  static const _kSnapOffset = pi / 12;
  double _wheelAngle = pi + pi / 12;
  double _velocity = 0; // rad/frame
  bool _snapping = false;
  double _snapTarget = pi + pi / 12;
  late Ticker _spinTicker;

  // Pan geçici durumu
  double? _panStartAngle;
  double _lastPanAngle = 0;
  int _prevPanMs = 0;

  // Faz 1 — basma doldurma animasyonu
  late AnimationController _fillCtrl;

  // Faz 3 — bar genişleme animasyonu
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  final _rng = Random();
  List<_BarResult>? _results;

  String get _selectedBurc {
    final idx = ((6 - ((_wheelAngle - _kSnapOffset) / (pi / 6)).round()) % 12 + 12) % 12;
    return _kBurclar[idx];
  }

  @override
  void initState() {
    super.initState();

    _spinTicker = createTicker(_onSpinTick);

    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _gotoPhase2();
      });

    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _spinTicker.dispose();
    _fillCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  // ── Çark spin ticker ──────────────────────────────────────────────────────

  void _onSpinTick(Duration _) {
    if (!mounted) return;
    if (_snapping) {
      _wheelAngle += (_snapTarget - _wheelAngle) * 0.15;
      if ((_wheelAngle - _snapTarget).abs() < 0.005) {
        _wheelAngle = _snapTarget;
        _snapping = false;
        _spinTicker.stop();
      }
    } else {
      _velocity *= 0.93;
      _wheelAngle += _velocity;
      if (_velocity.abs() < 0.004) {
        _velocity = 0;
        _snapping = true;
        _snapTarget = ((_wheelAngle - _kSnapOffset) / (pi / 6)).round() * (pi / 6) + _kSnapOffset;
      }
    }
    setState(() {});
  }

  // ── Pan işleyicileri ──────────────────────────────────────────────────────

  void _onWheelPanStart(DragStartDetails details) {
    _spinTicker.stop();
    _snapping = false;
    _velocity = 0;
    const center = Offset(140, 140); // 280/2
    final d = details.localPosition - center;
    _panStartAngle = atan2(d.dy, d.dx);
    _lastPanAngle = _panStartAngle!;
    _prevPanMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _onWheelPanUpdate(DragUpdateDetails details) {
    if (_panStartAngle == null) return;
    const center = Offset(140, 140);
    final d = details.localPosition - center;
    final currentAngle = atan2(d.dy, d.dx);
    final delta = _wrapAngle(currentAngle - _lastPanAngle);
    _wheelAngle += delta;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = (now - _prevPanMs).clamp(1, 50);
    _velocity = delta / dt * 16.0;
    _prevPanMs = now;
    _lastPanAngle = currentAngle;
    setState(() {});
  }

  void _onWheelPanEnd(DragEndDetails _) {
    _panStartAngle = null;
    _snapping = _velocity.abs() <= 0.002;
    if (_snapping) {
      _snapTarget = ((_wheelAngle - _kSnapOffset) / (pi / 6)).round() * (pi / 6) + _kSnapOffset;
    }
    _spinTicker.start();
  }

  double _wrapAngle(double a) {
    while (a > pi) a -= 2 * pi;
    while (a < -pi) a += 2 * pi;
    return a;
  }

  // ── Faz 2 başlatıcı ───────────────────────────────────────────────────────

  Future<void> _gotoPhase2() async {
    final burc = _selectedBurc;
    _spinTicker.stop();
    if (!mounted) return;
    setState(() => _phase = 2);

    await Future.wait<void>([
      _metinleriHazirla(burc),
      Future.delayed(const Duration(seconds: 5)),
    ]);
    if (!mounted) return;

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

  Future<void> _metinleriHazirla(String selectedBurc) async {
    try {
      final profile = ref.read(userProfileProvider);
      final raw = await rootBundle.loadString('assets/data/askuyumu.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final barsData = data['bars'] as Map<String, dynamic>;
      final uyumData = data['uyum'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      final barDefs = [
        ('ask', ref.read(l10nProvider).askUyumuCategory('ask'), const Color(0xFFFF4466)),
        ('aile', ref.read(l10nProvider).askUyumuCategory('aile'), const Color(0xFFFF8844)),
        ('maddi', ref.read(l10nProvider).askUyumuCategory('maddi'), const Color(0xFFFFDD00)),
        ('ten', ref.read(l10nProvider).askUyumuCategory('ten'), const Color(0xFFAA44FF)),
        ('vizyon', ref.read(l10nProvider).askUyumuCategory('vizyon'), const Color(0xFF4488FF)),
        ('iletisim', ref.read(l10nProvider).askUyumuCategory('iletisim'), const Color(0xFF44DDCC)),
      ];

      final results = <_BarResult>[];
      for (final (key, label, color) in barDefs) {
        final catData = barsData[key] as Map<String, dynamic>;
        const ranges = ['0-25', '25-50', '50-75', '75-100'];
        final pickedRange = ranges[_rng.nextInt(ranges.length)];
        final rangeEntries = (catData[pickedRange] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final metin = _pickEntry(prefs, 'askuyumu_${key}_gosterilen',
            rangeEntries, profile.toVariableMap());
        results.add(_BarResult(
          key: key,
          label: label,
          color: color,
          pct: _rangeValue(pickedRange),
          metin: metin,
        ));
      }

      // 7. bar: genel uyum — seçili burca göre filtrele
      final uyumKey = _uyumKey(profile.maritalStatus);
      final uyumAll = (uyumData[uyumKey] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final uyumPool = uyumAll.where((e) => e['burc'] == selectedBurc).toList();
      final uyumPrefsKey = 'askuyumu_uyum_${selectedBurc}_gosterilen';
      final uyumMetin = _pickEntry(
          prefs, uyumPrefsKey, uyumPool.isNotEmpty ? uyumPool : uyumAll,
          profile.toVariableMap());
      final uyumPct =
          (results.map((r) => r.pct).reduce((a, b) => a + b) / results.length)
              .round();

      results.add(_BarResult(
        key: 'uyum',
        label: ref.read(l10nProvider).askUyumuOverall,
        color: const Color(0xFF44DD66),
        pct: uyumPct,
        metin: uyumMetin,
      ));

      if (mounted) setState(() => _results = results);
    } catch (_) {}
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
        return _rng.nextInt(26);
      case '25-50':
        return 25 + _rng.nextInt(26);
      case '50-75':
        return 50 + _rng.nextInt(26);
      case '75-100':
        return 75 + _rng.nextInt(26);
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
    final isEn = ref.read(localeProvider) == 'en';
    final pickMetin = (isEn && (pick['metin_en'] as String?)?.isNotEmpty == true)
        ? pick['metin_en'] as String
        : pick['metin'] as String;
    return VariableReplacer.replace(pickMetin, varMap);
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      extendBody: true,
      body: GrimoireBackdrop(
        asset: 'assets/images/askuyumu.png',
        imageAlignment: Alignment.topCenter,
        child: SafeArea(
          child: _phase == 1
              ? _buildPhase1()
              : _phase == 2
                  ? _buildPhase2()
                  : _buildPhase3(),
        ),
      ),
    );
  }

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
            child: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 22),
          ),
        ),
        const Spacer(),
        Text(ref.watch(l10nProvider).askUyumuTitle, style: AppTextStyles.screenTitle),
        const Spacer(),
        const SizedBox(width: 36),
      ]),
    );
  }

  // ── Faz 1: burç seçimi + dokunma ─────────────────────────────────────────

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
                ref.watch(l10nProvider).askUyumuPrompt,
                textAlign: TextAlign.center,
                style: AppTextStyles.bubbleText.copyWith(color: AppColors.boneDim),
              ),
            ),
            const SizedBox(height: 20),
            _buildWheelWithPointer(),
            const SizedBox(height: 8),
            Text(
              ref.watch(l10nProvider).zodiacName(_selectedBurc),
              style: AppTextStyles.ritualTitle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 24),
            _buildHoldButton(),
            const SizedBox(height: 10),
            Text(ref.watch(l10nProvider).askUyumuHold, style: AppTextStyles.meta),
            const SizedBox(height: 16),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 2),
                  Text(
                    ref.read(l10nProvider).backButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildWheelWithPointer() {
    const wheelSize = 280.0;
    const pointerSize = 28.0;
    return SizedBox(
      width: wheelSize,
      height: wheelSize + pointerSize * 0.5,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          NoEdgeSwipeBack(child: GestureDetector(
            onPanStart: _onWheelPanStart,
            onPanUpdate: _onWheelPanUpdate,
            onPanEnd: _onWheelPanEnd,
            child: Transform.rotate(
              angle: _wheelAngle,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(
                    FilmedImage.matrix(1.0, 1.0)),
                child: Image.asset(
                  'assets/images/burclar_wheel.png',
                  width: wheelSize,
                  height: wheelSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          )),
          // Highlight çarkı — çarkla aynı dönüşte, sadece üstteki dilim kliplenir
          IgnorePointer(
            child: ClipPath(
              clipper: const _TopSegmentClipper(wheelSize: wheelSize),
              child: Transform.rotate(
                angle: _wheelAngle,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(FilmedImage.matrix(
                      FilmedImage.activeSaturation, FilmedImage.activeBrightness)),
                  child: Image.asset(
                    'assets/images/burclar_wheel_highlight.png',
                    width: wheelSize,
                    height: wheelSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          // Seçili dilim altın ışık — fixed, touch geçirgen
          IgnorePointer(
            child: CustomPaint(
              size: const Size(wheelSize, wheelSize),
              painter: _SegmentGlowPainter(),
            ),
          ),
          const Positioned(
            bottom: 0,
            child: Icon(
              Icons.arrow_drop_up_rounded,
              color: AppColors.gold,
              size: pointerSize,
            ),
          ),
        ],
      ),
    );
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
                Container(
                  width: buttonRadius * 2,
                  height: buttonRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.glassTint,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(buttonRadius * 2, buttonRadius * 2),
                  painter: _FillCirclePainter(
                    progress: _fillCtrl.value,
                    maxRadius: buttonRadius,
                    color: AppColors.gold,
                  ),
                ),
                const Icon(Icons.favorite_border_rounded,
                    color: AppColors.gold, size: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Faz 2: yükleme ────────────────────────────────────────────────────────

  Widget _buildPhase2() {
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const ElegantHourglass(size: 56, color: AppColors.gold),
            const SizedBox(height: 20),
            Text(
              ref.watch(l10nProvider).askUyumuCalculating,
              textAlign: TextAlign.center,
              style: AppTextStyles.bubbleText.copyWith(color: AppColors.boneDim),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ── Faz 3: sonuç ─────────────────────────────────────────────────────────

  Widget _buildPhase3() {
    final results = _results;
    if (results == null) {
      return Column(children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Text(ref.watch(l10nProvider).askUyumuLoadFail, style: AppTextStyles.meta),
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
    // Kategori başına ayrı renk yok: altın dolgu; düşük değer (<25) kurumuş kan.
    final fill = bar.pct < 25 ? AppColors.blood : AppColors.gold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        variant: GlassVariant.reading,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${bar.label}  %${bar.pct}',
              style: AppTextStyles.value.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTextStyles.tabular),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) {
                final widthFactor = (bar.pct / 100.0) * _barAnim.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: [
                    Container(
                        height: 6,
                        width: double.infinity,
                        color: AppColors.bone.withValues(alpha: 0.10)),
                    FractionallySizedBox(
                      widthFactor: widthFactor,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: fill,
                        ),
                      ),
                    ),
                  ]),
                );
              },
            ),
            const SizedBox(height: 10),
            bar.metin.isNotEmpty
                ? RichTextParser.build(
                    bar.metin,
                    style: AppTextStyles.reading.copyWith(fontSize: 15.5),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 2),
              Text(ref.watch(l10nProvider).exit,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Seçili dilim sarı ışık (fixed, pointer konumunda = alt merkez) ──────────

class _SegmentGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    // Alt merkez = π/2, yarım dilim = π/12 (30° dilimin yarısı)
    const startAngle = pi / 2 - pi / 12;
    const sweepAngle = pi / 6;

    // İç dolgu — yarı saydam sarı
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.92),
      startAngle, sweepAngle, true,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );

    // Kenar çizgisi — daha belirgin sarı
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.92),
      startAngle, sweepAngle, false,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3),
    );
  }

  @override
  bool shouldRepaint(_SegmentGlowPainter _) => false;
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
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(_FillCirclePainter old) => old.progress != progress;
}

// ─── Seçili dilim kliplayıcısı — sabit, üstteki 1/12 dilimi açar ─────────────

class _TopSegmentClipper extends CustomClipper<Path> {
  final double wheelSize;
  const _TopSegmentClipper({required this.wheelSize});

  @override
  Path getClip(Size size) {
    final center = Offset(wheelSize / 2, wheelSize / 2);
    final radius = wheelSize / 2;
    const segAngle = pi / 6; // 30° = 1/12 çark
    const startAngle = pi / 2 - segAngle / 2; // alt merkez (imleç konumu)
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(_TopSegmentClipper old) => old.wheelSize != wheelSize;
}

