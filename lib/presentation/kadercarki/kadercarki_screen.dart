// Kaynak metinler: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\KaderCarki
// Görseller:      C:\Magnus\Assets\Resources\YerelDOSYALAR\Gorseller\Wheel
// Akış (2026-11-06 yeniden): çarkı savur → çivilerde tık + ok sekmesi → durunca vuruş, kazanan
// dilim parlar (1,2 sn) → ödüllü reklam → sonuç sırayla süzülür (eski 2+2+3 sn boş beklemeler yok).

import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/ad_service.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/floating_bar_spacer.dart';

// ─── Çark bölmeleri (saat yönünde, 0'dan başlar) ─────────────────────────────

class _Bolme {
  final String key;       // JSON anahtar prefix'i
  final String label;     // Ekranda gösterilecek isim
  final String ikonAsset; // Segment görseli
  final Color  renk;      // Segment arka plan rengi

  const _Bolme(this.key, this.label, this.ikonAsset, this.renk);
}

const _bolmeler = [
  _Bolme('alev',   'Alev',    'assets/images/wheel/alev.png',    Color(0xFFCC3300)),
  _Bolme('hayvan', 'Hayvan',  'assets/images/wheel/hayvan.png',  Color(0xFF336600)),
  _Bolme('kure',   'Küre',    'assets/images/wheel/kure.png',    Color(0xFF003399)),
  _Bolme('renk',   'Renkler', 'assets/images/wheel/renkler.png', Color(0xFF993399)),
  _Bolme('tas',    'Taş',     'assets/images/wheel/tas.png',     Color(0xFF996600)),
  _Bolme('zar',    'Zar',     'assets/images/wheel/zar.png',     Color(0xFF006666)),
];

const int _bolmeSayisi = 6;
const double _bolmeAcisi = 2 * pi / _bolmeSayisi; // 60°

// ─── Çark geometrisi (test edilebilir) ───────────────────────────────────────

/// Ok (altta) hangi dilimi gösteriyor? [angle] çarkın dönüş açısı.
@visibleForTesting
int kaderSegUnderPointer(double angle) {
  var local = (pi / 2 - angle) % (2 * pi);
  if (local < 0) local += 2 * pi;
  final off = (local + pi / 2) % (2 * pi);
  return (off / _bolmeAcisi).floor().clamp(0, _bolmeSayisi - 1);
}

/// [current] açısından [dir] yönünde ([+1]/[-1]) [turns] tam tur atıp [target] diliminin
/// MERKEZİ okta duracak şekilde biten açı. Kalan yol dönüş yönünde ölçülür (ters savrulmada
/// da ok seçilen dilimde durur — 2026-11-06 hatası: eskiden ok hedefin aynasında duruyordu).
@visibleForTesting
double kaderSpinEnd(double current, int target, int dir, int turns) {
  final hedefAci = pi - (target * _bolmeAcisi + _bolmeAcisi / 2);
  var kalan = dir > 0 ? (hedefAci - current) % (2 * pi) : (current - hedefAci) % (2 * pi);
  if (kalan < 0) kalan += 2 * pi;
  return current + dir * (turns * 2 * pi + kalan);
}

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class KaderCarkiScreen extends ConsumerStatefulWidget {
  const KaderCarkiScreen({super.key});

  @override
  ConsumerState<KaderCarkiScreen> createState() => _KaderCarkiScreenState();
}

class _KaderCarkiScreenState extends ConsumerState<KaderCarkiScreen>
    with TickerProviderStateMixin {

  // Animasyon
  late final AnimationController _spinCtrl;
  Animation<double>? _spinAnim;
  // Ok: her çividen geçerken hafifçe sekip yerine döner.
  late final AnimationController _kickCtrl;
  double _kickDir = 1;
  // Duruş: kazanan dilim parlar ve nabız gibi atar.
  late final AnimationController _winCtrl;
  // Sonuç ekranı: ikon → başlık → metin sırayla süzülür.
  late final AnimationController _revealCtrl;

  // Durum
  bool   _doniyor      = false;
  bool   _bitti        = false; // çark durdu: bir daha çevrilemez (günde 1; ikinci akış yok)
  bool   _metinGeldi   = false;
  int    _kazananIndex = -1;
  String _metin        = '';
  Future<String>? _metinFuture;

  // Swipe takibi
  double _angularVelocity = 0;
  DateTime _lastPanTime   = DateTime.now();
  // pi/6 = yarım bölme offset → başlangıçta pointer tam bölme merkezinde
  double _currentAngle    = pi / 6;
  double _speedFraction   = 0.0; // gerçek açısal hıza göre 0 (durgun) … 1 (çok hızlı)
  double _prevSpinAngle   = 0;
  int    _prevSpinMicros  = 0;
  int    _lastSeg         = -1;
  int    _lastHapticMs    = 0;

  // Görsel cache. Her yüklemede YENİ Map referansı atanır (aşağıda): yerinde değiştirilen
  // tek Map'i _WheelPainter.shouldRepaint referansla karşılaştırıyordu → görseller yüklenince
  // çark yeniden çizilmiyor, ancak dönünce (açı değişince) beliriyordu (Anıl, 2026-11-06).
  Map<String, ui.Image?> _ikonCache = {};

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _spinCtrl.addListener(_onSpinTick);
    _spinCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onSpinComplete();
    });
    _kickCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 170));
    _winCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _lastSeg = _segUnderPointer(_currentAngle);
    _preloadImages();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _kickCtrl.dispose();
    _winCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  Future<void> _preloadImages() async {
    for (final b in _bolmeler) {
      final data = await rootBundle.load(b.ikonAsset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      // Yeni Map referansı → shouldRepaint değişimi görür, çark hemen yeniden çizilir.
      if (mounted) setState(() => _ikonCache = {..._ikonCache, b.key: frame.image});
    }
  }

  // ── Ok altındaki dilim + çivi geçişi (tık) ────────────────────────────────────

  static int _segUnderPointer(double angle) => kaderSegUnderPointer(angle);

  /// Ok bir dilim sınırını (çiviyi) geçtiyse: tık titreşimi + ok sekmesi.
  void _checkPeg(double angle, double dir) {
    final seg = _segUnderPointer(angle);
    if (seg == _lastSeg) return;
    _lastSeg = seg;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticMs > 45) {
      // Çok hızlıyken titreşim seli olmasın (iOS'ta en fazla ~22/sn).
      _lastHapticMs = now;
      HapticFeedback.selectionClick();
    }
    _kickDir = dir >= 0 ? 1 : -1;
    _kickCtrl.forward(from: 0);
  }

  void _onSpinTick() {
    final a = _spinAnim?.value ?? _currentAngle;
    final us = DateTime.now().microsecondsSinceEpoch;
    final dt = (us - _prevSpinMicros) / 1e6;
    if (dt > 0 && dt < 0.2) {
      final v = (a - _prevSpinAngle).abs() / dt;
      _speedFraction = (v / 16.0).clamp(0.0, 1.0);
    }
    _checkPeg(a, a - _prevSpinAngle);
    _prevSpinAngle = a;
    _prevSpinMicros = us;
    setState(() => _currentAngle = a);
  }

  // ── Swipe işleme ────────────────────────────────────────────────────────────
  // Ekranın HERHANGİ bir yerindeki yatay sürükleme çarkı çevirir (Anıl, 2026-11-07):
  // yatay piksel hareketi açısal dönüşe çevrilir; bırakınca sürükleme hızıyla savrulur.
  // Jest tüm gövdeye yayıldı (bkz. build()); soldan-sağa "geri gitme" bu ekranda kaldırıldı.

  /// Yatay piksel → açısal dönüş katsayısı (rad/piksel). Çark kenarında ~1:1 hissi + hafif
  /// ivme; tüm ekrana yayılan savurmanın çarkı rahat döndürmesi için.
  static const double _kDragToAngle = 0.008;

  bool get _kilitli => _doniyor || _bitti || _metinGeldi;

  void _onDragStart(DragStartDetails d) {
    if (_kilitli) return;
    _angularVelocity = 0;
    _lastPanTime = DateTime.now();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_kilitli) return;
    final deltaAngle = (d.primaryDelta ?? 0) * _kDragToAngle;
    final now = DateTime.now();
    final dt  = now.difference(_lastPanTime).inMicroseconds / 1e6;
    if (dt > 0) _angularVelocity = deltaAngle / dt;
    _currentAngle += deltaAngle;
    _lastPanTime   = now;
    _speedFraction = (_angularVelocity.abs() / 16.0).clamp(0.0, 1.0);
    _checkPeg(_currentAngle, deltaAngle);
    setState(() {});
  }

  void _onDragEnd(DragEndDetails d) {
    if (_kilitli) return;
    // Savurma hızı: framework'ün hız ölçerinden (px/sn) açısal hıza (rad/sn).
    final angVel = (d.primaryVelocity ?? 0) * _kDragToAngle;
    final speed  = angVel.abs();
    if (speed < 0.5) {
      setState(() => _speedFraction = 0);
      return;
    }
    _startSpin(speed, angVel >= 0 ? 1 : -1);
  }

  // ── Spin başlat ──────────────────────────────────────────────────────────────

  void _startSpin(double speed, int dir) {
    setState(() => _doniyor = true);
    HapticFeedback.mediumImpact();
    final rnd = Random();
    final hedefBolme = rnd.nextInt(_bolmeSayisi);
    // Güçlü savurma = daha çok tur (daha hızlı görünür); 4–10 tur.
    final tur = (3 + speed * 0.45).round().clamp(4, 9) + (rnd.nextBool() ? 1 : 0);
    final baslangic = _currentAngle;
    final bitis = kaderSpinEnd(baslangic, hedefBolme, dir, tur);
    // Süre turla orantılı (5,5–9 sn); easeOutCubic: başlangıç hızı ortalamanın 3 katı →
    // ilk anda kare başına ~20°, dilimler göz takibinde (eski eğride 18 kat, strobe).
    _spinCtrl.duration = Duration(milliseconds: (4200 + tur * 520).clamp(5500, 9000));
    _spinAnim = Tween<double>(begin: baslangic, end: bitis)
        .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOutCubic));
    _prevSpinAngle = baslangic;
    _prevSpinMicros = DateTime.now().microsecondsSinceEpoch;
    _kazananIndex = hedefBolme;
    // Metin dönüş sırasında hazırlanır (sonra bekleme yok).
    // Hata _sonucuGoster'deki await'te yakalanır; o ana kadar "yakalanmamış" sayılmasın.
    _metinFuture = _rastgeleMetnAl(_bolmeler[hedefBolme].key, ref.read(userProfileProvider))
      ..ignore();
    _spinCtrl.forward(from: 0);
  }

  // ── Duruş: vuruş → kazanan dilim parlar → reklam → sonuç sırayla süzülür ─────────

  Color get _haloColor => Color.lerp(
    const Color(0xFFFF1166),
    const Color(0xFF44FFCC),
    _speedFraction,
  )!;

  void _onSpinComplete() {
    HapticFeedback.heavyImpact();
    setState(() { _doniyor = false; _bitti = true; _speedFraction = 0.0; });
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _winCtrl.value = 1; // azaltılmış harekette nabız yok, kazanan sabit parlar
    } else {
      _winCtrl.repeat(reverse: true);
    }
    // Kazanan an kısa sürsün ama görülsün (1,2 sn), sonra reklam → sonuç.
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      AdService.instance.showRewarded(onRewarded: _sonucuGoster, onFailed: _sonucuGoster);
    });
  }

  bool _sonucIstendi = false;

  Future<void> _sonucuGoster() async {
    if (!mounted || _sonucIstendi) return; // reklamın iki geri çağrısı da gelse tek akış
    _sonucIstendi = true;
    // ref yalnız await ÖNCESİ (Codex: ekrandan çıkılırsa catch içindeki ref.read de patlardı).
    final hataMetni = ref.read(l10nProvider).kaderCarkiError;
    String metin;
    try {
      metin = await (_metinFuture ??
          _rastgeleMetnAl(_bolmeler[_kazananIndex].key, ref.read(userProfileProvider)));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kadercarki_bugun_tarih',
          DateTime.now().toIso8601String().substring(0, 10));
    } catch (_) {
      metin = hataMetni;
    }
    if (!mounted) return;
    _winCtrl.stop();
    HapticFeedback.lightImpact();
    setState(() {
      _metinGeldi = true;
      _metin = metin;
    });
    _revealCtrl.forward(from: 0);
  }

  // ── Metin motoru: no-repeat, koşul filtreli ──────────────────────────────────

  Future<String> _rastgeleMetnAl(String key, UserProfile profile) async {
    final isEn = ref.read(localeProvider) == 'en'; // await öncesi (ekran kapanabilir)
    final jsonStr  = await rootBundle.loadString('assets/data/kadercarki_$key.json');
    final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
    final tumListe = (jsonData['kadercarki_$key'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // Koşul filtresi
    final uygun = tumListe.where((m) {
      final kosullar = (m['kosullar'] as List?) ?? [];
      for (final k in kosullar) {
        final deg   = '${k['degisken'] ?? ''}';
        final deger = '${k['deger'] ?? ''}';
        if (_profilDeger(deg, profile) != deger) return false;
      }
      return true;
    }).toList();

    // No-repeat
    final prefsKey  = 'kadercarki_${key}_gosterilen';
    final prefs     = await SharedPreferences.getInstance();
    List<String> gosterilen = prefs.getStringList(prefsKey) ?? [];
    var kalan = uygun.where((m) => !gosterilen.contains('${m['id']}')).toList();
    if (kalan.isEmpty) {
      await prefs.remove(prefsKey);
      gosterilen = [];
      kalan = List.from(uygun);
    }
    if (kalan.isEmpty) kalan = List.from(tumListe); // koşullar çok kısıtlıysa fallback
    kalan.shuffle();
    final secilen = kalan.first;
    gosterilen.add('${secilen['id']}');
    await prefs.setStringList(prefsKey, gosterilen);

    final vars = {
      'isim':        profile.name,
      'cinsiyet':    profile.gender,
      'medeni_durum': profile.maritalStatus,
      'meslek':      profile.job,
    };
    final secMetin = (isEn && (secilen['metin_en'] as String?)?.isNotEmpty == true)
        ? secilen['metin_en'] as String
        : secilen['metin'] as String;
    return VariableReplacer.replace(secMetin, vars);
  }

  String _profilDeger(String deg, UserProfile p) {
    switch (deg) {
      case 'cinsiyet':     return p.gender;
      case 'medeni durum': return p.maritalStatusLabel;
      case 'medeni_durum': return p.maritalStatusLabel;
      case 'meslek':       return p.jobLabel;
      default:             return '';
    }
  }

  // Anlık pointer'ın altındaki bölmenin adı
  String get _pointerBolmeLabel =>
      ref.read(l10nProvider).kaderBolmeName(_bolmeler[_segUnderPointer(_currentAngle)].key);

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      // Soldan-sağa "geri gitme" bu ekranda KALDIRILDI: gövde NoEdgeSwipeBack ile sarılı
      // (global kenar-geri jesti devre dışı; geri = üstteki buton / Android geri / sistem
      // kenar jesti). Ekranın HERHANGİ bir yerindeki yatay sürükleme çarkı çevirir.
      body: NoEdgeSwipeBack(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart:  _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd:    _onDragEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/kadercarkimenu.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF060D1A)),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xBB000000), Color(0x55000000), Color(0xBB000000)],
                  ),
                ),
              ),
              SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _metinGeldi
                      ? KeyedSubtree(key: const ValueKey('metin'), child: _buildMetin())
                      : KeyedSubtree(key: const ValueKey('cark'), child: _buildCark()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Çark ekranı ──────────────────────────────────────────────────────────────

  Widget _buildCark() {
    final s = ref.watch(l10nProvider);
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: Center(
          child: LayoutBuilder(builder: (ctx, constraints) {
            final size = min(constraints.maxWidth, constraints.maxHeight) * 0.84;
            final kazanildi = _bitti && _kazananIndex >= 0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCarkWidget(size),
                const SizedBox(height: 16),
                // Anlık bölme adı; durunca kazanan "X Falı" olarak parlar.
                AnimatedBuilder(
                  animation: _winCtrl,
                  builder: (context, _) {
                    final g = kazanildi ? Curves.easeInOut.transform(_winCtrl.value) : 0.0;
                    final renk = kazanildi ? _bolmeler[_kazananIndex].renk : Colors.white;
                    return Text(
                      kazanildi
                          ? s.kaderFalTitle(s.kaderBolmeName(_bolmeler[_kazananIndex].key))
                          : _pointerBolmeLabel,
                      style: (kazanildi
                              ? AppTextStyles.screenTitle.copyWith(fontSize: 20)
                              : const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6))
                          .copyWith(shadows: [
                        Shadow(
                            color: Color.lerp(renk, Colors.white, 0.3)!
                                .withValues(alpha: 0.35 + 0.5 * g),
                            blurRadius: 8 + 16 * g),
                      ]),
                    );
                  },
                ),
              ],
            );
          }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: AnimatedOpacity(
          opacity: (_doniyor || _bitti) ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: Text(
            s.kaderCarkiSpinHint,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
      const FloatingBarSpacer(),
    ]);
  }

  Widget _buildCarkWidget(double size) {
    return SizedBox(
      width: size,
      height: size + 18,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Çark yüzeyi. Sürükleme jesti artık tüm ekranda (bkz. build()); burada
          // yalnız çizim var.
          SizedBox(
            width:  size,
            height: size,
            // Gölge sabit: ayrı katmanda bir kez çizilir (dönerken her karede bulanıklık yok).
            child: Stack(fit: StackFit.expand, children: [
              const RepaintBoundary(child: CustomPaint(painter: _WheelShadowPainter())),
              RepaintBoundary(child: AnimatedBuilder(
                animation: _winCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _WheelPainter(
                    angle:         _currentAngle,
                    bolmeler:      _bolmeler,
                    ikonler:       _ikonCache,
                    haloColor:     _haloColor,
                    speedFraction: _speedFraction,
                    winner:        _bitti ? _kazananIndex : -1,
                    winGlow:       _bitti ? Curves.easeInOut.transform(_winCtrl.value) : 0,
                  ),
                ),
              )),
            ]),
          ),
          // Ok: altta, çarkın kenarına batan altın gösterge; çivi geçişinde seker.
          Positioned(
            top: size - 30,
            child: AnimatedBuilder(
              animation: _kickCtrl,
              builder: (context, child) {
                final t = _kickCtrl.isAnimating || _kickCtrl.value < 1
                    ? sin(pi * _kickCtrl.value) * (1 - _kickCtrl.value * 0.4)
                    : 0.0;
                return Transform.rotate(
                  angle: -_kickDir * 0.32 * t,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: CustomPaint(size: const Size(30, 42), painter: _ArrowPainter()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Metin ekranı ──────────────────────────────────────────────────────────────

  Widget _buildMetin() {
    final s = ref.watch(l10nProvider);
    final bolme = _bolmeler[_kazananIndex];
    // drive: CurvedAnimation gibi kontrolcüye kalıcı durum dinleyicisi eklemez (her build'de sızıntı yok).
    Animation<double> seg(double a, double b) =>
        _revealCtrl.drive(CurveTween(curve: Interval(a, b, curve: Curves.easeOutCubic)));
    final ikonA = seg(0.0, 0.45);
    final baslikA = seg(0.18, 0.6);
    final metinA = seg(0.38, 1.0);
    return Column(children: [
      _buildHeader(),
      const SizedBox(height: 20),
      // İkon — kazanan dilimin renginde hale ile büyüyerek gelir.
      ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(ikonA),
        child: FadeTransition(
          opacity: ikonA,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                bolme.renk.withValues(alpha: 0.55),
                bolme.renk.withValues(alpha: 0.0),
              ]),
            ),
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: -pi / 2,
              child: Image.asset(
                bolme.ikonAsset,
                width: 72, height: 72,
                errorBuilder: (_, __, ___) => const SizedBox(height: 72),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      FadeTransition(
        opacity: baslikA,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(baslikA),
          child: Text(
            s.kaderFalTitle(s.kaderBolmeName(bolme.key)),
            style: AppTextStyles.screenTitle,
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Çerçeveli metin kutusu — kalan alanı doldurur, içi scroll edilebilir
      Expanded(
        child: FadeTransition(
          opacity: metinA,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(metinA),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color.lerp(bolme.renk, Colors.white, 0.45)!.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(color: bolme.renk.withValues(alpha: 0.28), blurRadius: 24),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: RichTextParser.build(
                    _metin,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.85,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const FloatingBarSpacer(),
    ]);
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
            child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
          ),
        ),
        const Spacer(),
        Text(ref.watch(l10nProvider).kaderCarkiTitle,
          style: AppTextStyles.screenTitle),
        const Spacer(),
        const SizedBox(width: 36),
      ]),
    );
  }
}

// ─── Çark CustomPainter ───────────────────────────────────────────────────────

Color _shade(Color c, double t) => Color.lerp(c, t >= 0 ? Colors.white : Colors.black, t.abs())!;

/// Çarkın zemine düşen gölgesi (Grok: çarkın gölgesi yok). Dönmez → ayrı katmanda bir kez.
class _WheelShadowPainter extends CustomPainter {
  const _WheelShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rim = min(cx, cy) * 0.075;
    final r = min(cx, cy) - rim - 6;
    canvas.drawCircle(
      Offset(cx, cy) + Offset(0, rim * 1.4),
      r + rim,
      Paint()
        ..color = const Color(0x8C000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rim * 2.2),
    );
  }

  @override
  bool shouldRepaint(_WheelShadowPainter old) => false;
}

class _WheelPainter extends CustomPainter {
  final double            angle;
  final List<_Bolme>      bolmeler;
  final Map<String, ui.Image?> ikonler;
  final Color             haloColor;
  final double            speedFraction;
  final int               winner;  // -1: yok
  final double            winGlow; // 0 … 1 (nabız)

  const _WheelPainter({
    required this.angle,
    required this.bolmeler,
    required this.ikonler,
    required this.haloColor,
    required this.speedFraction,
    this.winner = -1,
    this.winGlow = 0,
  });

  static const _goldDark = Color(0xFF7A5A16);
  static const _gold = Color(0xFFD9B04A);
  static const _goldLight = Color(0xFFFFF0B0);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final rim = min(cx, cy) * 0.075;          // altın kasnak kalınlığı
    final r  = min(cx, cy) - rim - 6;          // dilim yarıçapı
    final center = Offset(cx, cy);

    // -1. Gölge: _WheelShadowPainter (ayrı, sabit katman).

    // 0. Dış hale (gerçek hıza göre; durgunken sakin)
    canvas.drawCircle(
      center, r + rim,
      Paint()
        ..color       = haloColor.withValues(alpha: 0.20 + speedFraction * 0.45)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter  = MaskFilter.blur(BlurStyle.outer, 10 + speedFraction * 18),
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final segAngle = 2 * pi / bolmeler.length;
    final disk = Rect.fromCircle(center: Offset.zero, radius: r);

    for (int i = 0; i < bolmeler.length; i++) {
      final bolme = bolmeler[i];
      final start = -pi / 2 + i * segAngle;
      final win = i == winner;
      // Derinlik: merkez açık → kenar koyu (radyal), kazananda parlaklık nabzı.
      // Durunca kazanan parlar, diğerleri hafifçe kararır (göz kazanana gider).
      final lift = winner < 0 ? 0.0 : (win ? 0.10 + 0.22 * winGlow : -0.38);
      canvas.drawArc(
        disk, start, segAngle, true,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _shade(bolme.renk, 0.32 + lift),
              _shade(bolme.renk, lift),
              _shade(bolme.renk, -0.45 + lift),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(disk),
      );
      // Kazanan dilim: içten ışıyan altın kenar.
      if (win) {
        canvas.drawArc(
          disk.deflate(2), start, segAngle, true,
          Paint()
            ..color = _goldLight.withValues(alpha: 0.55 + 0.45 * winGlow)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2 + 6 * winGlow),
        );
      }

      // İkon — dilim ortasında, dışa doğru
      final ikon = ikonler[bolme.key];
      final midAngle = start + segAngle / 2;
      final imgDist  = r * 0.66;
      final imgSize  = r * 0.17;
      if (ikon != null) {
        canvas.save();
        canvas.translate(imgDist * cos(midAngle), imgDist * sin(midAngle));
        canvas.rotate(midAngle);
        final src = Rect.fromLTWH(0, 0, ikon.width.toDouble(), ikon.height.toDouble());
        final dst = Rect.fromCenter(center: Offset.zero, width: imgSize * 2.4, height: imgSize * 2.4);
        // Hafif gölge + ikon
        canvas.drawImageRect(ikon, src, dst.shift(const Offset(1.5, 1.5)),
            Paint()..colorFilter = const ColorFilter.mode(Color(0x66000000), BlendMode.srcIn));
        canvas.drawImageRect(ikon, src, dst, Paint()..filterQuality = FilterQuality.medium);
        canvas.restore();
      }
    }

    // Üstten hafif cam parlaması (dönmeyen ışık hissi için tersine döndürülerek)
    canvas.save();
    canvas.rotate(-angle);
    canvas.drawCircle(
      Offset.zero, r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF), Color(0x24000000)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(disk),
    );
    canvas.restore();

    // Dilim ayraçları: altın çizgi + kenarda çivi (ok bunlara takılır)
    for (int i = 0; i < bolmeler.length; i++) {
      final a = -pi / 2 + i * segAngle;
      final dir = Offset(cos(a), sin(a));
      canvas.drawLine(
        dir * (r * 0.17), dir * r,
        Paint()
          ..shader = LinearGradient(colors: const [_goldDark, _goldLight, _gold])
              .createShader(Rect.fromPoints(dir * (r * 0.17), dir * r))
          ..strokeWidth = 2.2,
      );
    }
    canvas.restore();

    // 1. Altın kasnak (dönmez: ışık sabit kalır)
    final rimRect = Rect.fromCircle(center: center, radius: r + rim / 2);
    canvas.drawCircle(
      center, r + rim / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim
        ..shader = const SweepGradient(
          colors: [_goldDark, _goldLight, _gold, _goldDark, _gold, _goldLight, _goldDark],
          stops: [0.0, 0.12, 0.3, 0.5, 0.68, 0.85, 1.0],
        ).createShader(rimRect),
    );
    // kasnağın iç ve dış ince çizgileri
    for (final rr in [r, r + rim]) {
      canvas.drawCircle(center, rr,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x99000000));
    }

    // 2. Çiviler: dilim sınırlarında, kasnak üstünde (çarkla döner)
    for (int i = 0; i < bolmeler.length; i++) {
      final a = angle - pi / 2 + i * segAngle;
      final p = center + Offset(cos(a), sin(a)) * (r + rim / 2);
      final pr = rim * 0.42;
      canvas.drawCircle(p + const Offset(1, 1.5), pr, Paint()..color = const Color(0x88000000));
      canvas.drawCircle(
        p, pr,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: const [_goldLight, _gold, _goldDark],
          ).createShader(Rect.fromCircle(center: p, radius: pr)),
      );
    }

    // 3. Göbek: altın disk + mor mücevher
    final hub = r * 0.17;
    canvas.drawCircle(center + const Offset(0, 2), hub, Paint()..color = const Color(0x99000000));
    canvas.drawCircle(
      center, hub,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: const [_goldLight, _gold, _goldDark],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: hub)),
    );
    final gem = hub * 0.48;
    canvas.drawCircle(
      center, gem,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: const [Color(0xFFFFB3FF), Color(0xFFB026C9), Color(0xFF4A0A5C)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: gem)),
    );
    canvas.drawCircle(center + Offset(-gem * 0.35, -gem * 0.38), gem * 0.22,
        Paint()..color = const Color(0xCCFFFFFF));

    // 4. Kazanınca kıvılcımlar
    _sparks(canvas, center, r + rim);
  }

  /// Kazanınca okun çevresinde nabızla parlayan dört köşeli yıldız kıvılcımlar.
  void _sparks(Canvas canvas, Offset center, double r) {
    if (winner < 0) return;
    final pts = [
      Offset(-r * 0.30, r * 0.93), Offset(r * 0.27, r * 0.95),
      Offset(-r * 0.12, r * 0.80), Offset(r * 0.10, r * 1.07),
    ];
    for (var i = 0; i < pts.length; i++) {
      final g = ((winGlow + i * 0.27) % 1.0);
      final a = (0.35 + 0.65 * g).clamp(0.0, 1.0);
      final sz = r * (0.035 + 0.03 * g);
      final c = center + pts[i];
      final star = Path()
        ..moveTo(c.dx, c.dy - sz)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + sz, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + sz)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - sz, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - sz)
        ..close();
      canvas.drawPath(star,
          Paint()
            ..color = _goldLight.withValues(alpha: a * 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawPath(star, Paint()..color = Colors.white.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.angle != angle || old.ikonler != ikonler ||
      old.haloColor != haloColor || old.speedFraction != speedFraction ||
      old.winner != winner || old.winGlow != winGlow;
}

// ─── Ok işareti (pointer): altta, yukarı bakan altın gösterge ─────────────────

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w * 0.82, h * 0.42, w * 0.78, h * 0.72)
      ..quadraticBezierTo(w * 0.5, h * 0.98, w * 0.22, h * 0.72)
      ..quadraticBezierTo(w * 0.18, h * 0.42, w / 2, 0)
      ..close();
    canvas.drawPath(path.shift(const Offset(1.5, 2)), Paint()..color = const Color(0x99000000));
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0B0), Color(0xFFD9B04A), Color(0xFF7A5A16)],
        ).createShader(Offset.zero & size),
    );
    // ortada küçük mücevher
    final c = Offset(w / 2, h * 0.66);
    canvas.drawCircle(c, w * 0.16,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [Color(0xFFFFB3FF), Color(0xFFB026C9), Color(0xFF4A0A5C)],
          ).createShader(Rect.fromCircle(center: c, radius: w * 0.16)));
    canvas.drawPath(path,
        Paint()..color = const Color(0x66000000)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_ArrowPainter _) => false;
}
