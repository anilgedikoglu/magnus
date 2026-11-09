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
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/bir_tane_daha.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../data/providers.dart';
import '../../core/constants/app_text_styles.dart';

// ─── Burç listesi (index 0=Koç … 11=Balık) ───────────────────────────────────
const _kBurclar = [
  'Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak',
  'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık',
];

// ─── Çark hareketi (saf hesap, testli) ───────────────────────────────────────

/// Merkeze bu kadar yakın dokunuşta açı kararsızdır; çevirme başlatmaz.
const double kCarkOluYaricap = 18;

/// Dokunuş çarkın dairesi içinde mi? (Köşeler ve göbek hariç.)
bool carkUzerindeMi(Offset p, Offset merkez, double yaricap) {
  final d = (p - merkez).distance;
  return d <= yaricap && d >= kCarkOluYaricap;
}

/// [onceki]den [simdi]ye parmağın merkez etrafında süpürdüğü açı (radyan).
/// Ekranda y aşağı olduğundan pozitif = saat yönü (Transform.rotate ile aynı).
double carkAciFarki(Offset onceki, Offset simdi, Offset merkez) {
  final a = onceki - merkez;
  final b = simdi - merkez;
  if (a.distance < kCarkOluYaricap || b.distance < kCarkOluYaricap) return 0;
  return atan2(a.dx * b.dy - a.dy * b.dx, a.dx * b.dx + a.dy * b.dy);
}

/// Parmağın [hiz]ının (px/sn) merkez etrafındaki açısal karşılığı (rad/sn, pozitif = saat yönü).
double carkAcisalHiz(Offset konum, Offset hiz, Offset merkez) {
  final r = konum - merkez;
  final r2 = r.distanceSquared;
  if (r2 < kCarkOluYaricap * kCarkOluYaricap) return 0;
  return (r.dx * hiz.dy - r.dy * hiz.dx) / r2;
}

/// Kullanıcı burcu + seçilen burç + gün → sabit tohum (FNV-1a).
int askUyumuTohumu(String kullanici, String secilen, DateTime gun) {
  var h = 0x811c9dc5;
  for (final c in '$kullanici|$secilen|${gun.year}-${gun.month}-${gun.day}'.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  return h;
}

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
  int _lastBurc = -1; // çark tıkı: imleç altındaki burç değişince
  int _lastTickMs = 0;

  int get _burcIndex =>
      ((6 - ((_wheelAngle - _kSnapOffset) / (pi / 6)).round()) % 12 + 12) % 12;

  /// İmleç altındaki burç değiştiyse tık (iOS'ta en fazla ~22/sn).
  void _burcTik() {
    final i = _burcIndex;
    if (i == _lastBurc) return;
    _lastBurc = i;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTickMs < 45) return;
    _lastTickMs = now;
    HapticFeedback.selectionClick();
  }
  double _snapTarget = pi + pi / 12;
  late Ticker _spinTicker;

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
        if (status == AnimationStatus.completed) {
          HapticFeedback.heavyImpact(); // kalp doldu
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
        HapticFeedback.lightImpact(); // burca oturdu
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
    _burcTik();
    setState(() {});
  }

  // ── Çark döndürme — yalnız çarkın üzerinde, parmağı merkez etrafında izler ──
  // Açı farkı merkezden çıkan doğruya göre hesaplanır: nereden olursa olsun saat
  // yönünde yapılan kaydırma çarkı saat yönünde döndürür. Çark dışında başlayan
  // dokunuş çarkı çevirmez (Anıl, 2026-11-09).
  double _carkCapi = 320;
  bool _carkSuruklu = false;
  Offset _sonDokunus = Offset.zero;

  Offset get _carkMerkezi => Offset(_carkCapi / 2, _carkCapi / 2);

  void _onWheelDragStart(DragStartDetails d) {
    _carkSuruklu = carkUzerindeMi(d.localPosition, _carkMerkezi, _carkCapi / 2);
    if (!_carkSuruklu) return;
    _spinTicker.stop();
    _snapping = false;
    _velocity = 0;
    _sonDokunus = d.localPosition;
  }

  void _onWheelDragUpdate(DragUpdateDetails d) {
    if (!_carkSuruklu) return;
    _wheelAngle += carkAciFarki(_sonDokunus, d.localPosition, _carkMerkezi);
    _sonDokunus = d.localPosition;
    _burcTik();
    setState(() {});
  }

  void _onWheelDragEnd(DragEndDetails d) {
    if (!_carkSuruklu) return;
    _carkSuruklu = false;
    // Atışı yakala: parmağın teğet hızı (rad/sn) → rad/frame (≈16 ms).
    _velocity = (carkAcisalHiz(_sonDokunus, d.velocity.pixelsPerSecond, _carkMerkezi) * 0.016)
        .clamp(-0.6, 0.6);
    _snapping = _velocity.abs() <= 0.002;
    if (_snapping) {
      _snapTarget =
          ((_wheelAngle - _kSnapOffset) / (pi / 6)).round() * (pi / 6) + _kSnapOffset;
    }
    _spinTicker.start();
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

      // Aynı gün aynı burca bakan aynı yüzdeleri görür; "başka burca bak" anlamlı olur.
      final tohumlu = Random(askUyumuTohumu(
          profile.toVariableMap()['burc'] ?? '', selectedBurc, DateTime.now()));
      final results = <_BarResult>[];
      for (final (key, label, color) in barDefs) {
        final catData = barsData[key] as Map<String, dynamic>;
        const ranges = ['0-25', '25-50', '50-75', '75-100'];
        final pickedRange = ranges[tohumlu.nextInt(ranges.length)];
        final rangeEntries = (catData[pickedRange] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final metin = _pickEntry(prefs, 'askuyumu_${key}_gosterilen',
            rangeEntries, profile.toVariableMap());
        results.add(_BarResult(
          key: key,
          label: label,
          color: color,
          pct: _rangeValue(pickedRange, tohumlu),
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

  int _rangeValue(String range, Random rng) {
    switch (range) {
      case '0-25':
        return rng.nextInt(26);
      case '25-50':
        return 25 + rng.nextInt(26);
      case '50-75':
        return 50 + rng.nextInt(26);
      case '75-100':
        return 75 + rng.nextInt(26);
      default:
        return rng.nextInt(101);
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
          // Faz 1: bu ekranda global "soldan sağa kaydır = geri" kapalı (Anıl: sağa swipe geri
          // gitmesin). Katman saydam, dokunuşlar altındaki çarka ve düğmelere geçer. Geri dönüş:
          // üstteki ok, Android geri tuşu, sistemin kenar jesti.
          if (_phase == 1)
            const Positioned.fill(child: NoEdgeSwipeBack(child: SizedBox.expand())),
        ],
      ),
    );
  }

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
        Text(
          ref.watch(l10nProvider).askUyumuTitle,
          style: AppTextStyles.screenTitle,
        ),
        const Spacer(),
        const SizedBox(width: 36),
      ]),
    );
  }

  // ── Faz 1: burç seçimi + dokunma ─────────────────────────────────────────

  /// Çark çapı: yanlarda 12 pt pay, altında burç adı ve basılı-tut düğmesi sığacak kadar.
  double _carkCapiHesapla(Size yer, double barPayi, TextScaler olcek, String metin) {
    const yanPay = 24.0;
    final yonerge = TextPainter(
      text: TextSpan(text: metin, style: _kYonergeStili),
      textDirection: TextDirection.ltr,
      textScaler: olcek,
    )..layout(maxWidth: yer.width - 64);
    final ustBlok = 48 + 10 + yonerge.height + 16; // başlık, boşluk, yönerge, boşluk
    yonerge.dispose();
    final altBlok = 22 + 8 + olcek.scale(26) + 108 + 12 + olcek.scale(18) + 12; // imleç, burç adı, düğme, ipucu, nefes
    final enFazla = min(yer.width - yanPay, yer.height - ustBlok - altBlok - barPayi);
    return enFazla.clamp(120.0, 520.0);
  }

  int? _carkOlcuAnahtari; // çap yalnız ekran/yazı değişince yeniden hesaplanır

  static const _kYonergeStili = TextStyle(
    color: Colors.white,
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w300,
  );

  Widget _buildPhase1() {
    // `context` SafeArea'nın dışındadır: alt güvenli alan SafeArea'da düşer, bar için kalan bırakılır.
    final ekran = MediaQuery.sizeOf(context);
    final pay = MediaQuery.paddingOf(context);
    final barPayi = max(0.0, floatingBarInset(context) - pay.bottom);
    final yer = Size(ekran.width, ekran.height - pay.vertical);
    final olcek = MediaQuery.textScalerOf(context);
    final metin = ref.watch(l10nProvider).askUyumuPrompt;
    final anahtar = Object.hash(yer, barPayi, olcek.scale(100), metin);
    if (anahtar != _carkOlcuAnahtari) {
      _carkOlcuAnahtari = anahtar;
      _carkCapi = _carkCapiHesapla(yer, barPayi, olcek, metin);
    }
    return _buildPhase1Govde(barPayi);
  }

  Widget _buildPhase1Govde(double barPayi) {
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                ref.watch(l10nProvider).askUyumuPrompt,
                textAlign: TextAlign.center,
                style: _kYonergeStili,
              ),
            ),
            const SizedBox(height: 16),
            _buildWheelWithPointer(),
            const SizedBox(height: 8),
            Text(
              ref.watch(l10nProvider).zodiacName(_selectedBurc),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            // Basılı-tut butonu kalan boşlukta dikeyde ORTALANIR (Anıl, 2026-11-06:
            // "biraz aşağı indir, kalan boşluğa dikeyde ortala").
            Expanded(
              child: FittedBox( // çok büyük yazı boyutunda taşmak yerine küçülür
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHoldButton(),
                    const SizedBox(height: 12),
                    Text(
                      ref.watch(l10nProvider).askUyumuHold,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: barPayi),
    ]);
  }

  Widget _buildWheelWithPointer() {
    final wheelSize = _carkCapi; // Anıl, 2026-11-09: ekrana göre büyür (yanlarda 12 pt pay).
    const pointerSize = 30.0;
    return SizedBox(
      width: wheelSize,
      height: wheelSize + 22, // imleç diskin hemen altında, burç yazısını örtmez
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Görselde dairenin çevresinde saydam pay var (512'de 468 dolu): disk tam çap kadar çizilir.
          Transform.scale(
            scale: 512 / 468,
            child: SizedBox(
              width: wheelSize,
              height: wheelSize,
              child: Stack(
                children: [
                  Transform.rotate(
                    angle: _wheelAngle,
                    child: Image.asset(
                      'assets/images/burclar_wheel.png',
                      width: wheelSize,
                      height: wheelSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Highlight çarkı — çarkla aynı dönüşte, sadece üstteki dilim kliplenir
                  IgnorePointer(
                    child: ClipPath(
                      clipper: _TopSegmentClipper(wheelSize: wheelSize),
                      child: Transform.rotate(
                        angle: _wheelAngle,
                        child: Image.asset(
                          'assets/images/burclar_wheel_highlight.png',
                          width: wheelSize,
                          height: wheelSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Seçili dilim sarı ışık — fixed, touch geçirgen
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(wheelSize, wheelSize),
                      painter: _SegmentGlowPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 0, // kutu diskin 8 pt üstünden başlar; üçgenin ucu diskin altında kalır
            child: Icon(
              Icons.arrow_drop_up_rounded,
              color: Colors.white,
              size: pointerSize,
            ),
          ),
          // Sürükleme alanı: yalnız çark karesi; daire dışı başlangıçlar yok sayılır.
          Positioned(
            top: 0,
            width: wheelSize,
            height: wheelSize,
            child: GestureDetector(
              key: const ValueKey('ask_uyumu_cark'),
              behavior: HitTestBehavior.opaque,
              onPanStart: _onWheelDragStart,
              onPanUpdate: _onWheelDragUpdate,
              onPanEnd: _onWheelDragEnd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldButton() {
    const double buttonRadius = 54.0; // Anıl, 2026-11-06: basılı-tut butonu büyütüldü (40→54).
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
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(buttonRadius * 2, buttonRadius * 2),
                  painter: _FillCirclePainter(
                    progress: _fillCtrl.value,
                    maxRadius: buttonRadius,
                    color: const Color(0xFFFF4466),
                  ),
                ),
                const Icon(Icons.favorite_rounded, color: Colors.white, size: 38),
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
            const ElegantHourglass(size: 56, color: Color(0xFFFF4466)),
            const SizedBox(height: 20),
            Text(
              ref.watch(l10nProvider).askUyumuCalculating,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  // ── Faz 3: sonuç ─────────────────────────────────────────────────────────

  Widget _buildPhase3() {
    final results = _results;
    if (results == null) {
      return Column(children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Text(ref.watch(l10nProvider).askUyumuLoadFail,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
            BirTaneDaha(
              falTuru: 'askuyumu',
              hakAnahtari: 'askuyumu_bugun_tarih',
              etiket: ref.watch(l10nProvider).adOtherSign,
            ),
            const SizedBox(height: 8),
            const FloatingBarSpacer(),
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
          border: Border.all(color: bar.color.withValues(alpha: 0.30), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${bar.label}  %${bar.pct}',
              style: TextStyle(
                  color: bar.color, fontSize: 16, fontWeight: FontWeight.bold),
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
                        height: 10,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.12)),
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
                  ]),
                );
              },
            ),
            const SizedBox(height: 10),
            bar.metin.isNotEmpty
                ? RichTextParser.build(
                    bar.metin,
                    style: const TextStyle(
                        color: Color(0xEEFFFFFF), fontSize: 13, height: 1.6),
                  )
                : const SizedBox.shrink(),
          ],
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
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );

    // Kenar çizgisi — daha belirgin sarı
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.92),
      startAngle, sweepAngle, false,
      Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
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

