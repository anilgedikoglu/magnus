// Kaynak metinler: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\KaderCarki
// Görseller:      C:\Magnus\Assets\Resources\YerelDOSYALAR\Gorseller\Wheel
// Akış: Çarkı çevir → dur → 2s → fal adı → 2s → kum saati → metin göster

import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

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

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class KaderCarkiScreen extends ConsumerStatefulWidget {
  const KaderCarkiScreen({super.key});

  @override
  ConsumerState<KaderCarkiScreen> createState() => _KaderCarkiScreenState();
}

class _KaderCarkiScreenState extends ConsumerState<KaderCarkiScreen>
    with TickerProviderStateMixin {

  // Animasyon
  late AnimationController _spinCtrl;
  late Animation<double>    _spinAnim;

  // Durum
  bool   _doniyor      = false;
  bool   _falAdiGoster = false;
  bool   _hazirlaniyor = false;
  bool   _metinGeldi   = false;
  int    _kazananIndex = -1;
  String _metin        = '';

  // Swipe takibi
  double _panStartAngle   = 0;
  double _panPrevAngle    = 0;
  double _angularVelocity = 0;
  DateTime _lastPanTime   = DateTime.now();
  // pi/6 = yarım bölme offset → başlangıçta pointer tam bölme merkezinde
  double _currentAngle    = pi / 6;
  double _speedFraction   = 0.0; // 0=kırmızı, 1=yeşil

  // Görsel cache
  final Map<String, ui.Image?> _ikonCache = {};

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _spinCtrl.addListener(() {
      setState(() {
        _currentAngle  = _spinAnim.value;
        // Decelerate curve: hız başta max, sonda sıfır → (1 - progress)
        _speedFraction = (1.0 - _spinCtrl.value).clamp(0.0, 1.0);
      });
    });
    _spinCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onSpinComplete();
    });
    _preloadImages();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _preloadImages() async {
    for (final b in _bolmeler) {
      final data = await rootBundle.load(b.ikonAsset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _ikonCache[b.key] = frame.image);
    }
  }

  // ── Swipe işleme ────────────────────────────────────────────────────────────

  double _angleFromPosition(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    return atan2(dy, dx);
  }

  void _onPanStart(DragStartDetails d, Size size) {
    if (_doniyor || _falAdiGoster || _hazirlaniyor || _metinGeldi) return;
    _panStartAngle = _angleFromPosition(d.localPosition, size);
    _panPrevAngle  = _panStartAngle;
    _angularVelocity = 0;
    _lastPanTime = DateTime.now();
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_doniyor || _falAdiGoster || _hazirlaniyor || _metinGeldi) return;
    final angle = _angleFromPosition(d.localPosition, size);
    final delta = _wrapAngle(angle - _panPrevAngle);
    final now   = DateTime.now();
    final dt    = now.difference(_lastPanTime).inMicroseconds / 1e6;
    if (dt > 0) _angularVelocity = delta / dt;
    _currentAngle  += delta;
    _panPrevAngle   = angle;
    _lastPanTime    = now;
    _speedFraction  = (_angularVelocity.abs() / 8.0).clamp(0.0, 1.0);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    if (_doniyor || _falAdiGoster || _hazirlaniyor || _metinGeldi) return;
    final speed = _angularVelocity.abs();
    if (speed < 0.5) return;
    _startSpin(speed);
  }

  double _wrapAngle(double a) {
    while (a >  pi) a -= 2 * pi;
    while (a < -pi) a += 2 * pi;
    return a;
  }

  // ── Spin başlat ──────────────────────────────────────────────────────────────

  void _startSpin(double speed) {
    setState(() => _doniyor = true);

    final turSayisi  = 16 + Random().nextInt(8); // 16-23 tur
    final hedefBolme = Random().nextInt(_bolmeSayisi);
    final hedefMerkez = hedefBolme * _bolmeAcisi + _bolmeAcisi / 2;
    // Bölme merkezini alt noktaya (pi/2) getirmek için gereken açı:
    // screen_pos = angle + (-pi/2 + hedefMerkez) = pi/2 → angle = pi - hedefMerkez
    final fark = _wrapAngle((pi - hedefMerkez) - _currentAngle % (2 * pi));
    final toplamDelta = turSayisi * 2 * pi + fark;

    final baslangic = _currentAngle;
    final bitis     = baslangic + toplamDelta.abs() * (_angularVelocity >= 0 ? 1 : -1);

    _spinCtrl.duration = Duration(milliseconds: (6000 + (speed * 600)).round().clamp(6000, 14000));
    // Cubic(0.05, 0.9, 0.2, 1.0): hızlı başlar, çok uzun ve tatlı yavaşlama
    _spinAnim = Tween<double>(begin: baslangic, end: bitis)
        .animate(CurvedAnimation(parent: _spinCtrl,
            curve: const Cubic(0.05, 0.9, 0.2, 1.0)));
    _spinCtrl.forward(from: 0);
    _kazananIndex = hedefBolme;
  }

  // ── Spin tamamlandı: dur → 2s → fal adı → 2s → kum saati + metin fetch ──────

  Color get _haloColor => Color.lerp(
    const Color(0xFFFF1111),
    const Color(0xFF00FF44),
    _speedFraction,
  )!;

  void _onSpinComplete() {
    setState(() { _doniyor = false; _speedFraction = 0.0; });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _falAdiGoster = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() { _falAdiGoster = false; _hazirlaniyor = true; });
        _metniGetir();
      });
    });
  }

  Future<void> _metniGetir() async {
    try {
      final profile = ref.read(userProfileProvider);
      final bolme   = _bolmeler[_kazananIndex];
      // Metin fetch + 3s minimum bekleme aynı anda çalışır
      String metin = '';
      await Future.wait<void>([
        _rastgeleMetnAl(bolme.key, profile).then((m) => metin = m),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      if (!mounted) return;
      // Günlük kullanımı kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kadercarki_bugun_tarih',
          DateTime.now().toIso8601String().substring(0, 10));
      if (!mounted) return;
      setState(() {
        _hazirlaniyor = false;
        _metinGeldi   = true;
        _metin        = metin;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hazirlaniyor = false;
        _metinGeldi   = true;
        _metin        = 'Fal hazırlanırken bir sorun oluştu. Lütfen tekrar deneyin.';
      });
    }
  }

  // ── Metin motoru: no-repeat, koşul filtreli ──────────────────────────────────

  Future<String> _rastgeleMetnAl(String key, UserProfile profile) async {
    final jsonStr  = await rootBundle.loadString('assets/data/kadercarki_$key.json');
    final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
    final tumListe = (jsonData['kadercarki_$key'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // Koşul filtresi
    final uygun = tumListe.where((m) {
      final kosullar = (m['kosullar'] as List?) ?? [];
      for (final k in kosullar) {
        final deg   = k['degisken'] as String;
        final deger = k['deger']    as String;
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
      'cinsiyet':    profile.gender ?? '',
      'medeni_durum': profile.maritalStatus ?? '',
      'meslek':      profile.job ?? '',
    };
    return VariableReplacer.replace(secilen['metin'] as String, vars);
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

  // ── Sıfırla ──────────────────────────────────────────────────────────────────

  void _sifirla() {
    _spinCtrl.reset();
    setState(() {
      _doniyor      = false;
      _falAdiGoster = false;
      _hazirlaniyor = false;
      _metinGeldi   = false;
      _kazananIndex = -1;
      _metin        = '';
    });
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
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_falAdiGoster)  return _buildFalAdi();
    if (_hazirlaniyor)  return _buildHazirlaniyor();
    if (_metinGeldi)    return _buildMetin();
    return _buildCark();
  }

  // ── Fal adı ekranı (spin sonrası 2s gösterilir) ───────────────────────────────

  Widget _buildFalAdi() {
    final bolme = _bolmeler[_kazananIndex];
    return Column(children: [
      _buildHeader(),
      Expanded(child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(
            bolme.ikonAsset,
            width: 90,
            height: 90,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
          const SizedBox(height: 28),
          Text(
            '${bolme.label} Falı',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ]),
      )),
    ]);
  }

  // ── Çark ekranı ──────────────────────────────────────────────────────────────

  Widget _buildCark() {
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: Center(
          child: LayoutBuilder(builder: (ctx, constraints) {
            final size = min(constraints.maxWidth, constraints.maxHeight) * 0.82;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCarkWidget(size),
                const SizedBox(height: 16),
                Text(
                  _doniyor ? '' : 'Çarkı parmağınla çevir',
                  style: const TextStyle(color: Colors.white54, fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              ],
            );
          }),
        ),
      ),
      // Geri Git — dert ortağı standardı
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
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
                Text('Geri Git', style: TextStyle(color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildCarkWidget(double size) {
    final halo = _haloColor;
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onPanStart:  (d) => _onPanStart(d, Size(size, size)),
          onPanUpdate: (d) => _onPanUpdate(d, Size(size, size)),
          onPanEnd:    _onPanEnd,
          child: SizedBox(
            width:  size,
            height: size,
            child: CustomPaint(
              painter: _WheelPainter(
                angle:         _currentAngle,
                bolmeler:      _bolmeler,
                ikonler:       _ikonCache,
                haloColor:     halo,
                speedFraction: _speedFraction,
              ),
            ),
          ),
        ),
        // Ok işareti — altta, daire kenarında
        Positioned(
          bottom: 0,
          child: CustomPaint(
            size: const Size(24, 28),
            painter: _ArrowPainter(),
          ),
        ),
        // Merkez düğme
        Container(
          width:  44,
          height: 44,
          decoration: BoxDecoration(
            shape:     BoxShape.circle,
            color:     const Color(0xFF111122),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 8),
            ],
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Icon(Icons.autorenew_rounded, color: Colors.white60, size: 20),
        ),
      ],
    );
  }

  // ── Hazırlanıyor ekranı ───────────────────────────────────────────────────────

  Widget _buildHazirlaniyor() {
    final bolme = _bolmeler[_kazananIndex];
    return Column(children: [
      _buildHeader(),
      Expanded(child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(bolme.ikonAsset, width: 80, height: 80,
              errorBuilder: (_, __, ___) => const SizedBox()),
          const SizedBox(height: 24),
          _HourglassWidget(),
          const SizedBox(height: 20),
          Text('${bolme.label} Falın geliyor...',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 17,
                height: 1.5, fontWeight: FontWeight.w300)),
        ]),
      )),
    ]);
  }

  // ── Metin ekranı ──────────────────────────────────────────────────────────────

  Widget _buildMetin() {
    final bolme = _bolmeler[_kazananIndex];
    return Column(children: [
      _buildHeader(),
      const SizedBox(height: 20),

      // İkon — üst orta
      Image.asset(
        bolme.ikonAsset,
        width: 72, height: 72,
        errorBuilder: (_, __, ___) => const SizedBox(height: 72),
      ),
      const SizedBox(height: 10),

      // Fal adı — ortalı
      Text(
        '${bolme.label} Falı',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 16),

      // Çerçeveli metin kutusu — kalan alanı doldurur, içi scroll edilebilir
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1.2,
              ),
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
      const SizedBox(height: 12),

      // Çıkış
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
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
                Text('Çıkış', style: TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
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
        const Text('Kader Çarkı',
          style: TextStyle(color: Colors.white, fontSize: 17,
              fontWeight: FontWeight.bold)),
        const Spacer(),
        const SizedBox(width: 36),
      ]),
    );
  }
}

// ─── Çark CustomPainter ───────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final double            angle;
  final List<_Bolme>      bolmeler;
  final Map<String, ui.Image?> ikonler;
  final Color             haloColor;
  final double            speedFraction;

  const _WheelPainter({
    required this.angle,
    required this.bolmeler,
    required this.ikonler,
    required this.haloColor,
    required this.speedFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = min(cx, cy) - 4;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final segAngle = 2 * pi / bolmeler.length;

    for (int i = 0; i < bolmeler.length; i++) {
      final bolme = bolmeler[i];
      final start = -pi / 2 + i * segAngle;

      // Segment arka planı
      final paint = Paint()..color = bolme.renk.withValues(alpha: 0.85);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        start, segAngle, true, paint,
      );

      // Segment kenarlığı
      final borderPaint = Paint()
        ..color     = Colors.white.withValues(alpha: 0.25)
        ..style     = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        start, segAngle, true, borderPaint,
      );

      // Görsel — ağırlık merkezinden biraz daha dışa, 90° sola döndürülmüş
      final ikon = ikonler[bolme.key];
      final midAngle = start + segAngle / 2;
      final imgDist  = r * 0.72;
      final imgX     = imgDist * cos(midAngle);
      final imgY     = imgDist * sin(midAngle);
      final imgSize  = r * 0.15;

      if (ikon != null) {
        canvas.save();
        canvas.translate(imgX, imgY);
        canvas.rotate(midAngle + pi / 2);
        final src = Rect.fromLTWH(0, 0, ikon.width.toDouble(), ikon.height.toDouble());
        final dst = Rect.fromCenter(center: Offset.zero, width: imgSize * 2, height: imgSize * 2);
        canvas.drawImageRect(ikon, src, dst, Paint());
        canvas.restore();
      }
    }

    canvas.restore();

    final center = Offset(cx, cy);
    final rect   = Rect.fromCircle(center: center, radius: r + 3);

    // 1. Tam çevre — hafif eşit glow
    canvas.drawCircle(
      center, r + 3,
      Paint()
        ..color       = haloColor.withValues(alpha: 0.35 + speedFraction * 0.25)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter  = MaskFilter.blur(BlurStyle.outer, 8 + speedFraction * 12),
    );

    // 2. Alt yarım çevre — güçlü glow (alttan vuruyor etkisi)
    // 0 (sağ/3 saat) → pi (sol/9 saat), saat yönünde = alt yarı
    canvas.drawArc(
      rect, 0, pi, false,
      Paint()
        ..color       = haloColor.withValues(alpha: 0.65 + speedFraction * 0.30)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter  = MaskFilter.blur(BlurStyle.outer, 14 + speedFraction * 20),
    );

    // 3. Üstüne ince beyaz çerçeve
    canvas.drawCircle(
      center, r + 3,
      Paint()
        ..color       = Colors.white.withValues(alpha: 0.18)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.angle != angle || old.ikonler != ikonler ||
      old.haloColor != haloColor || old.speedFraction != speedFraction;
}

// ─── Ok işareti (pointer) ─────────────────────────────────────────────────────

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path  = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width,     size.height)
      ..lineTo(0,              size.height)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path,
        Paint()..color = Colors.black38..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_ArrowPainter _) => false;
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _top = !_top);
          _ctrl.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Icon(
        _top ? Icons.hourglass_top_rounded : Icons.hourglass_bottom_rounded,
        key: ValueKey(_top),
        color: const Color(0xFF4DBBCC),
        size: 52,
      ),
    );
  }
}
