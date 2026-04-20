// C:/src/magnus_app/lib/presentation/kehanet/yana_screen.dart
// Yana kehanet ekranı - Bana Dair / Yaşama Dair seçimi

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

class YanaScreen extends ConsumerStatefulWidget {
  const YanaScreen({super.key});

  @override
  ConsumerState<YanaScreen> createState() => _YanaScreenState();
}

// Adımlar:
//  secim         → seçim ekranı (görsel + iki buton)
//  gorselKayiyor → görsel merkeze'den tepeye kayıyor (700 ms)
//  odaklanma     → "Kehanetine odaklanıyorum..." + ⏳ (5.5 s)
//  yagmur        → karakterler aşağı dökülüp kayboluyor (4.5 s)
//  icerik        → kehanet yazısı fade-in
enum _YanaAdim { secim, gorselKayiyor, odaklanma, yagmur, icerik }

class _YanaScreenState extends ConsumerState<YanaScreen>
    with TickerProviderStateMixin {
  _YanaAdim _adim = _YanaAdim.secim;
  String    _metin = '';
  Timer?    _odakTimer;

  // ── Animasyon controller'ları ─────────────────────────────────────────────
  late AnimationController _glowCtrl;   // aurora çerçeve (4 s, tekrar)
  late AnimationController _slideCtrl;  // görsel yukarı kayma (700 ms)
  late Animation<double>   _slideAnim;  // 0 → 1, easeOutCubic
  late AnimationController _rainCtrl;   // harf yağmuru (4500 ms)
  late AnimationController _fadeCtrl;   // kehanet yazısı belirme (1400 ms)
  late Animation<double>   _fadeAnim;   // 0 → 1, easeIn

  // ── Yağmur verisi ─────────────────────────────────────────────────────────
  final List<String> _rainChars  = [];
  final List<double> _rainDelays = [];  // her karakter için 0.0-0.70 gecikme
  final List<double> _rainDrifts = [];  // yatay sürüklenme (px)

  // Görsel boyutu (build'de sabit)
  static const double _imgSize = 180.0;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4000))..repeat();

    _slideCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2100)); // 3× yavaş
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl, curve: Curves.easeOutCubic);

    _rainCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4500));

    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _odakTimer?.cancel();
    _glowCtrl.dispose();
    _slideCtrl.dispose();
    _rainCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Yağmur karakter listesini hazırla ─────────────────────────────────────
  void _prepareRainChars() {
    final rng = Random();
    _rainChars.clear(); _rainDelays.clear(); _rainDrifts.clear();
    const text = 'Kehanetine odaklanıyorum...';
    for (int i = 0; i < text.length; i++) {
      _rainChars.add(text[i]);
      _rainDelays.add(rng.nextDouble() * 0.68);
      _rainDrifts.add((rng.nextDouble() - 0.5) * 80.0);
    }
    // Kum saati ayrı eleman
    _rainChars.add('⏳');
    _rainDelays.add(rng.nextDouble() * 0.50);
    _rainDrifts.add((rng.nextDouble() - 0.5) * 40.0);
  }

  // ── Seçim yapıldı ─────────────────────────────────────────────────────────
  Future<void> _onSecim(String tur) async {
    // 1. Görseli yukarı kaydır
    setState(() => _adim = _YanaAdim.gorselKayiyor);
    await _slideCtrl.forward();
    if (!mounted) return;

    // 2. "Odaklanıyorum" ekranı — veri yüklemesi arka planda başlıyor
    _prepareRainChars();
    setState(() => _adim = _YanaAdim.odaklanma);
    final dataFuture = _loadData(tur);

    _odakTimer = Timer(const Duration(milliseconds: 5500), () async {
      await dataFuture;
      if (!mounted) return;
      // 3. Yağmur animasyonu
      setState(() => _adim = _YanaAdim.yagmur);
      await _rainCtrl.forward();
      if (!mounted) return;
      // 4. Kehanet yazısı
      setState(() => _adim = _YanaAdim.icerik);
      _fadeCtrl.forward();
    });
  }

  Future<void> _loadData(String tur) async {
    final str  = await rootBundle.loadString('assets/data/yana.json');
    final data = jsonDecode(str);
    final List all = data['yana'] ?? [];

    final prefs = await SharedPreferences.getInstance();
    final key   = 'yana_${tur}_gosterilen';
    var shown   = prefs.getStringList(key) ?? [];

    var eligible = all.where((e) =>
        e['tur'] == tur &&
        (e['kosullar'] as List? ?? []).isEmpty &&
        !shown.contains(e['id'].toString())).toList();

    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown    = [];
      eligible = all.where((e) =>
          e['tur'] == tur &&
          (e['kosullar'] as List? ?? []).isEmpty).toList();
    }

    eligible.shuffle(Random());
    final selected = eligible.first;
    _metin = selected['metin'] ?? '';
    final profile = ref.read(userProfileProvider);
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());
    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);
  }

  // ── Geri tuşu ─────────────────────────────────────────────────────────────
  void _goBack() {
    _odakTimer?.cancel();
    if (_adim == _YanaAdim.secim) {
      context.pop();
    } else {
      _slideCtrl.reset(); _rainCtrl.reset(); _fadeCtrl.reset();
      setState(() { _adim = _YanaAdim.secim; _metin = ''; });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Widget'lar
  // ─────────────────────────────────────────────────────────────────────────

  // Aurora prizmatik çerçeveli görsel
  Widget _buildGlowImage() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (ctx, child) {
        final h1 = _glowCtrl.value * 360;
        final h2 = (h1 + 80)  % 360;
        final h3 = (h1 + 180) % 360;
        final c1 = HSVColor.fromAHSV(1, h1, 0.85, 1.0).toColor();
        final c2 = HSVColor.fromAHSV(1, h2, 0.90, 1.0).toColor();
        final c3 = HSVColor.fromAHSV(1, h3, 0.80, 1.0).toColor();
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c1.withValues(alpha: 0.85), width: 2.0),
            boxShadow: [
              BoxShadow(color: c1.withValues(alpha: 0.55),
                  blurRadius: 10, spreadRadius: 1),
              BoxShadow(color: c2.withValues(alpha: 0.30),
                  blurRadius: 22, spreadRadius: 4),
              BoxShadow(color: c3.withValues(alpha: 0.18),
                  blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/kehanet/yana.png',
          width: _imgSize, height: _imgSize, fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Tek yağmur karakteri: kendi gecikmesiyle düşüp Solar out.
  // ⏳ (son eleman) odaklanma adımındaki görünümüyle eşleşsin diye büyük font.
  Widget _buildRainChar(int i) {
    final isHourglass = i == _rainChars.length - 1;
    final style = isHourglass
        ? const TextStyle(fontSize: 48)
        : const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6);

    return AnimatedBuilder(
      animation: _rainCtrl,
      builder: (ctx, child) {
        final t     = _rainCtrl.value;
        final delay = _rainDelays[i];
        if (t <= delay) return child!;
        final local = ((t - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final eased = Curves.easeIn.transform(local);
        return Transform.translate(
          offset: Offset(_rainDrifts[i] * eased, eased * 650),
          child: Opacity(opacity: (1.0 - eased).clamp(0.0, 1.0), child: child),
        );
      },
      child: Text(_rainChars[i], style: style),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: double.infinity, height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)]),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.80), width: 1.5),
        ),
        child: const Center(child: Text('Kapat',
          style: TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _secimBtn(BuildContext context, String label, String tur) {
    return GestureDetector(
      onTap: () => _onSecim(tur),
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)]),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.80), width: 1.5),
        ),
        child: Center(child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.bold))),
      ),
    );
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
            // ── Başlık ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: _goBack,
                ),
                const Expanded(child: Text('YANA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.bold, letterSpacing: 1.2))),
                const SizedBox(width: 48),
              ]),
            ),

            // ── secim ────────────────────────────────────────────────────
            if (_adim == _YanaAdim.secim)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGlowImage(),
                    const SizedBox(height: 28),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text('Ne hakkında kehanet istersin?',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(children: [
                        _secimBtn(context, 'Bana Dair', 'bana'),
                        const SizedBox(height: 16),
                        _secimBtn(context, 'Yaşama Dair', 'yasama'),
                      ]),
                    ),
                  ],
                ),
              )

            // ── animasyon adımları (gorselKayiyor / odaklanma / yagmur / icerik) ──
            else
              Expanded(
                child: LayoutBuilder(builder: (ctx, bc) {
                  final h = bc.maxHeight;
                  // Görsel Alignment(0, -0.82) ile Stack içinde nerede biter:
                  //   top  = ((-0.82+1)/2) * (h - _imgSize)  = 0.09 * (h - 180)
                  //   bottom = top + _imgSize
                  final imgTop    = 0.09 * (h - _imgSize);
                  final imgBottom = imgTop + _imgSize;
                  // Alt içerik (odaklanma/yağmur) dikey ortası: görsel altı ile ekran altı arası
                  final lowerMid  = imgBottom + (h - imgBottom) / 2;

                  return Stack(children: [

                    // ── Görsel: merkez → tepe animasyonu ─────────────────
                    AnimatedBuilder(
                      animation: _slideAnim,
                      builder: (ctx, child) => Align(
                        alignment: Alignment.lerp(
                          Alignment.center,
                          const Alignment(0, -0.82),
                          _slideAnim.value,
                        )!,
                        child: child,
                      ),
                      child: _buildGlowImage(),
                    ),

                    // ── odaklanma + yagmur: AYNI widget ağacı ────────────
                    // _rainCtrl.value = 0 iken _buildRainChar statik görünür
                    // → geçişte hiç görsel değişim olmaz, yağmur doğal başlar.
                    if (_adim == _YanaAdim.odaklanma ||
                        _adim == _YanaAdim.yagmur)
                      Positioned(
                        top: lowerMid - 60,
                        left: 0, right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Metin — bireysel karakterler olarak
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                for (int i = 0; i < _rainChars.length - 1; i++)
                                  _buildRainChar(i),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Kum saati — ayrı satırda, büyük font
                            _buildRainChar(_rainChars.length - 1),
                          ],
                        ),
                      ),

                    // ── icerik: kehanet yazısı + kapat butonu ─────────────
                    if (_adim == _YanaAdim.icerik) ...[
                      Positioned(
                        top:    imgBottom + 24,
                        bottom: 72,
                        left:   24, right: 24,
                        child: AnimatedBuilder(
                          animation: _fadeAnim,
                          builder: (ctx, child) =>
                              Opacity(opacity: _fadeAnim.value, child: child),
                          // ConstrainedBox + Center: metin kısa ise dikeyde ortalanır,
                          // uzunsa scroll edilebilir
                          child: LayoutBuilder(
                            builder: (ctx, bc) => SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(minHeight: bc.maxHeight),
                                child: Center(
                                  child: Text(_metin,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.7,
                                    ),   // TextStyle
                                  ),     // Text
                                ),       // Center
                              ),         // ConstrainedBox
                            ),           // SingleChildScrollView / builder
                          ),             // LayoutBuilder
                        ),               // AnimatedBuilder
                      ),                 // Positioned (icerik metin)
                      Positioned(
                        bottom: 16, left: 20, right: 20,
                        child: _buildCloseButton(),
                      ),
                    ],

                  ]);
                }),
              ),
          ],
        ),
      ),
    );
  }
}
