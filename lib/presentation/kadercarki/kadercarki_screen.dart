// Kaynak metinler: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\KaderCarki
// Görseller:      C:\Magnus\Assets\Resources\YerelDOSYALAR\Gorseller\Wheel
// Akış: Çarkı çevir → bölme seç → "Falın geliyor..." 4sn → metin göster

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
  _Bolme('alev',   'Alev',   'assets/images/wheel/alev.png',    Color(0xFFCC3300)),
  _Bolme('hayvan', 'Hayvan', 'assets/images/wheel/hayvan.png',  Color(0xFF336600)),
  _Bolme('kure',   'Küre',   'assets/images/wheel/kure.png',    Color(0xFF003399)),
  _Bolme('renk',   'Renkler','assets/images/wheel/renkler.png', Color(0xFF993399)),
  _Bolme('tas',    'Taş',    'assets/images/wheel/tas.png',     Color(0xFF996600)),
  _Bolme('zar',    'Zar',    'assets/images/wheel/zar.png',     Color(0xFF006666)),
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
  bool   _hazirlaniyor = false;
  bool   _metinGeldi   = false;
  int    _kazananIndex = -1;
  String _metin        = '';

  // Swipe takibi
  double _panStartAngle = 0;
  double _panPrevAngle  = 0;
  double _angularVelocity = 0;
  DateTime _lastPanTime = DateTime.now();
  double _currentAngle  = 0; // çarkın anlık açısı (radyan)

  // Görsel cache
  final Map<String, ui.Image?> _ikonCache = {};

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _spinCtrl.addListener(() {
      setState(() => _currentAngle = _spinAnim.value);
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
    if (_doniyor || _hazirlaniyor || _metinGeldi) return;
    _panStartAngle = _angleFromPosition(d.localPosition, size);
    _panPrevAngle  = _panStartAngle;
    _angularVelocity = 0;
    _lastPanTime = DateTime.now();
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_doniyor || _hazirlaniyor || _metinGeldi) return;
    final angle = _angleFromPosition(d.localPosition, size);
    final delta = _wrapAngle(angle - _panPrevAngle);
    final now   = DateTime.now();
    final dt    = now.difference(_lastPanTime).inMicroseconds / 1e6;
    if (dt > 0) _angularVelocity = delta / dt;
    _currentAngle += delta;
    _panPrevAngle  = angle;
    _lastPanTime   = now;
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    if (_doniyor || _hazirlaniyor || _metinGeldi) return;
    final speed = _angularVelocity.abs();
    if (speed < 0.5) return; // çok yavaş, başlatma
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

    // 10-15 tam tur + rastgele bir bölmeye gelecek şekilde hedef açı
    final turSayisi  = 10 + Random().nextInt(6); // 10-15
    final hedefBolme = Random().nextInt(_bolmeSayisi);
    // Pointer altta (6 saat = pi/2) — hangi açı bu bölmeyi oraya getirir?
    // Bölme hedefBolme'nin merkezi: currentAngle + hedefBolme * _bolmeAcisi + _bolmeAcisi/2
    // Bunu pi/2 (6 saat konumu) yapacak şekilde ilave tur hesapla
    final hedefMerkez = hedefBolme * _bolmeAcisi + _bolmeAcisi / 2;
    final fark = _wrapAngle((pi / 2 - hedefMerkez) - _currentAngle % (2 * pi));
    final toplamDelta = turSayisi * 2 * pi + fark;

    final baslangic = _currentAngle;
    final bitis     = baslangic + toplamDelta.abs() * (_angularVelocity >= 0 ? 1 : -1);

    _spinCtrl.duration = Duration(milliseconds: (3000 + (speed * 400)).round().clamp(3000, 7000));
    _spinAnim = Tween<double>(begin: baslangic, end: bitis)
        .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.decelerate));
    _spinCtrl.forward(from: 0);
    _kazananIndex = hedefBolme;
  }

  // ── Spin tamamlandı ──────────────────────────────────────────────────────────

  void _onSpinComplete() {
    setState(() { _doniyor = false; _hazirlaniyor = true; });
    Future.delayed(const Duration(seconds: 4), _metniGetir);
  }

  Future<void> _metniGetir() async {
    final profile = ref.read(userProfileProvider);
    final bolme   = _bolmeler[_kazananIndex];
    final metin   = await _rastgeleMetnAl(bolme.key, profile);
    if (!mounted) return;
    setState(() {
      _hazirlaniyor = false;
      _metinGeldi   = true;
      _metin        = metin;
    });
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
        final deg  = k['degisken'] as String;
        final deger= k['deger']    as String;
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
    kalan.shuffle();
    final secilen = kalan.first;
    gosterilen.add('${secilen['id']}');
    await prefs.setStringList(prefsKey, gosterilen);

    // {{isim}} değişken değiştir
    final vars = {
      'isim': profile.name,
      'cinsiyet':     profile.gender ?? '',
      'medeni_durum': profile.maritalStatus ?? '',
      'meslek':       profile.job ?? '',
    };
    return VariableReplacer.replace(secilen['metin'] as String, vars);
  }

  String _profilDeger(String deg, UserProfile p) {
    switch (deg) {
      case 'cinsiyet':      return p.gender;
      case 'medeni durum':  return p.maritalStatusLabel;
      case 'medeni_durum':  return p.maritalStatusLabel;
      case 'meslek':        return p.jobLabel;
      default:              return '';
    }
  }

  // ── Sıfırla ──────────────────────────────────────────────────────────────────

  void _sifirla() {
    _spinCtrl.reset();
    setState(() {
      _doniyor      = false;
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
          // Arka plan
          Image.asset(
            'assets/images/falbg/durugoru.png',
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
    if (_hazirlaniyor) return _buildHazirlaniyor();
    if (_metinGeldi)   return _buildMetin();
    return _buildCark();
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Çark + swipe detector
        GestureDetector(
          onPanStart:  (d) => _onPanStart(d, Size(size, size)),
          onPanUpdate: (d) => _onPanUpdate(d, Size(size, size)),
          onPanEnd:    _onPanEnd,
          child: SizedBox(
            width:  size,
            height: size,
            child: CustomPaint(
              painter: _WheelPainter(
                angle:    _currentAngle,
                bolmeler: _bolmeler,
                ikonler:  _ikonCache,
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
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Bölme başlığı
            Row(children: [
              Image.asset(bolme.ikonAsset, width: 36, height: 36,
                  errorBuilder: (_, __, ___) => const SizedBox()),
              const SizedBox(width: 10),
              Text(bolme.label,
                style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            // Metin
            RichTextParser.build(
              _metin,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.8),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
      // Tekrar çevir
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: GestureDetector(
          onTap: _sifirla,
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
                Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Tekrar Çevir', style: TextStyle(color: Colors.white,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              SizedBox(width: 2),
              Text('Geri Git', style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
        const Spacer(),
        const Text('Kader Çarkı',
          style: TextStyle(color: Colors.white, fontSize: 17,
              fontWeight: FontWeight.bold)),
        const Spacer(),
        const SizedBox(width: 80),
      ]),
    );
  }
}

// ─── Çark CustomPainter ───────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final double            angle;
  final List<_Bolme>      bolmeler;
  final Map<String, ui.Image?> ikonler;

  const _WheelPainter({
    required this.angle,
    required this.bolmeler,
    required this.ikonler,
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
      final bolme  = bolmeler[i];
      final start  = -pi / 2 + i * segAngle;

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

      // Görsel — segment merkezine yerleştir
      final ikon = ikonler[bolme.key];
      final midAngle = start + segAngle / 2;
      final imgDist  = r * 0.58;
      final imgX     = imgDist * cos(midAngle);
      final imgY     = imgDist * sin(midAngle);
      final imgSize  = r * 0.30;

      if (ikon != null) {
        canvas.save();
        canvas.translate(imgX, imgY);
        canvas.rotate(midAngle + pi / 2);
        final src  = Rect.fromLTWH(0, 0, ikon.width.toDouble(), ikon.height.toDouble());
        final dst  = Rect.fromCenter(center: Offset.zero, width: imgSize * 2, height: imgSize * 2);
        canvas.drawImageRect(ikon, src, dst, Paint());
        canvas.restore();
      }

      // Label
      canvas.save();
      canvas.translate(imgX * 0.42, imgY * 0.42);
      canvas.rotate(midAngle + pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: bolme.label,
          style: TextStyle(
            color:      Colors.white,
            fontSize:   r * 0.095,
            fontWeight: FontWeight.bold,
            shadows:    const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign:     TextAlign.center,
      )..layout(maxWidth: r * 0.45);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.restore();

    // Dış halka
    canvas.drawCircle(
      Offset(cx, cy), r + 3,
      Paint()
        ..color     = Colors.white.withValues(alpha: 0.30)
        ..style     = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.angle != angle || old.ikonler != ikonler;
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

