// C:/src/magnus_app/lib/presentation/kehanet/yana_screen.dart
// Yana kehanet ekranı - Bana Dair / Yaşama Dair seçimi
//
// JSON kaynağı: assets/data/yana.json
//   Üst anahtarlar: "bana_dair" ve "yasama_dair"
//   Her entry: { "id", "tur", "metin", "kosullar": [...] }
//   Koşul eşleşme mantığı → _matchesProfile() fonksiyonu

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/providers.dart';
import '../../data/models/user_profile.dart';

class YanaScreen extends ConsumerStatefulWidget {
  const YanaScreen({super.key});

  @override
  ConsumerState<YanaScreen> createState() => _YanaScreenState();
}

// Adımlar:
//  secim         → seçim ekranı (görsel + iki buton)
//  gorselKayiyor → görsel merkeze'den tepeye kayıyor (700 ms)
//  odaklanma     → "Kehanetine odaklanıyorum..." + ElegantHourglass (5.5 s)
//  yagmur        → karakterler aşağı dökülüp kayboluyor (4.5 s)
//  icerik        → üst yarı görsel, alt yarı kehanet yazısı
enum _YanaAdim { secim, gorselKayiyor, odaklanma, yagmur, icerik }

class _YanaScreenState extends ConsumerState<YanaScreen>
    with TickerProviderStateMixin {
  _YanaAdim _adim = _YanaAdim.secim;
  String    _metin = '';
  Timer?    _odakTimer;

  // ── Animasyon controller'ları ─────────────────────────────────────────────
  late AnimationController _glowCtrl;   // aurora çerçeve (4 s, tekrar)
  late AnimationController _slideCtrl;  // görsel yukarı kayma (2100 ms)
  late Animation<double>   _slideAnim;  // 0 → 1, easeOutCubic
  late AnimationController _rainCtrl;   // harf yağmuru (4500 ms)
  late AnimationController _fadeCtrl;   // kehanet yazısı belirme (1400 ms)
  late Animation<double>   _fadeAnim;   // 0 → 1, easeIn

  // ── Yağmur verisi ─────────────────────────────────────────────────────────
  final List<String> _rainChars  = [];
  final List<double> _rainDelays = [];
  final List<double> _rainDrifts = [];

  static const double _imgSize = 180.0;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4000))..repeat();

    _slideCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2100));
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

  // ── Yağmur: sadece metin karakterleri (kum saati artık ayrı widget) ───────
  void _prepareRainChars() {
    final rng = Random();
    _rainChars.clear(); _rainDelays.clear(); _rainDrifts.clear();
    const text = 'Kehanetine odaklanıyorum...';
    for (int i = 0; i < text.length; i++) {
      _rainChars.add(text[i]);
      _rainDelays.add(rng.nextDouble() * 0.68);
      _rainDrifts.add((rng.nextDouble() - 0.5) * 80.0);
    }
  }

  // ── Seçim yapıldı ─────────────────────────────────────────────────────────
  Future<void> _onSecim(String tur) async {
    setState(() => _adim = _YanaAdim.gorselKayiyor);
    await _slideCtrl.forward();
    if (!mounted) return;

    _prepareRainChars();
    setState(() => _adim = _YanaAdim.odaklanma);
    final dataFuture = _loadData(tur);

    _odakTimer = Timer(const Duration(milliseconds: 5500), () async {
      await dataFuture;
      if (!mounted) return;
      setState(() => _adim = _YanaAdim.yagmur);
      await _rainCtrl.forward();
      if (!mounted) return;
      setState(() => _adim = _YanaAdim.icerik);
      _fadeCtrl.forward();
    });
  }

  // ── Veri yükleme — bana_dair veya yasama_dair, koşul filtreli ────────────
  Future<void> _loadData(String tur) async {
    final str  = await rootBundle.loadString('assets/data/yana.json');
    final data = jsonDecode(str) as Map<String, dynamic>;

    final String jsonKey = tur == 'bana' ? 'bana_dair' : 'yasama_dair';
    final List all = data[jsonKey] ?? [];

    final profile = ref.read(userProfileProvider);
    final prefs   = await SharedPreferences.getInstance();
    final key     = 'yana_${tur}_gosterilen';
    var shown     = prefs.getStringList(key) ?? [];

    // Kullanıcı profiline uygun metinleri filtrele
    var eligible = all
        .where((e) =>
            _matchesProfile(e as Map<String, dynamic>, profile) &&
            !shown.contains(e['id'].toString()))
        .toList();

    // Tümü gösterildi → sıfırla (son gösterilen tekrar gelmesin)
    if (eligible.isEmpty) {
      final lastId = shown.isNotEmpty ? shown.last : null;
      final resetShown = lastId != null ? [lastId] : <String>[];
      await prefs.setStringList(key, resetShown);
      shown = resetShown;
      eligible = all
          .where((e) =>
              _matchesProfile(e as Map<String, dynamic>, profile) &&
              e['id'].toString() != lastId)
          .toList();
      if (eligible.isEmpty) {
        eligible = all.where((e) => _matchesProfile(e as Map<String, dynamic>, profile)).toList();
      }
    }

    if (eligible.isEmpty) {
      _metin = 'Kehanet hazırlanıyor...';
      return;
    }

    eligible.shuffle(Random());
    final selected = eligible.first as Map<String, dynamic>;
    _metin = selected['metin'] as String? ?? '';
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());

    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);
  }

  // ── Profil koşul eşleşmesi ────────────────────────────────────────────────
  // kosullar listesi: AND semantiği farklı degisken'ler arasında,
  //                   OR semantiği aynı degisken'in birden fazla değeri arasında.
  bool _matchesProfile(Map<String, dynamic> item, UserProfile profile) {
    final kosullar = (item['kosullar'] as List?) ?? [];
    if (kosullar.isEmpty) return true;

    // Aynı degisken için değerleri grupla
    final groups = <String, List<dynamic>>{};
    for (final k in kosullar) {
      final kMap = k as Map<String, dynamic>;
      final dg = kMap['degisken'] as String;
      groups.putIfAbsent(dg, () => []).add(kMap['deger']);
    }

    // Her grup AND; grup içi OR
    for (final entry in groups.entries) {
      bool groupPass = false;
      for (final deger in entry.value) {
        if (_checkCondition(entry.key, deger, profile)) {
          groupPass = true;
          break;
        }
      }
      if (!groupPass) return false;
    }
    return true;
  }

  bool _checkCondition(String degisken, dynamic deger, UserProfile profile) {
    final val = deger.toString().toLowerCase().replaceAll('_', ' ');
    switch (degisken) {
      case 'cinsiyet':
        // Profile: 'erkek' | 'kadin' | 'lgbt'
        // Asset:   'erkek' | 'kadın' | 'lgbt'
        final pg = profile.gender.toLowerCase();
        if (val == 'kadın' || val == 'kadin') return pg == 'kadin';
        if (val == 'erkek') return pg == 'erkek';
        return pg == val;

      case 'medeni_durum':
        // Profile internal keys (with underscores) vs asset Turkish values
        return _medeniBool(val, profile.maritalStatus);

      case 'yasmax':
        final maxAge = deger is int ? deger : int.tryParse(deger.toString()) ?? 999;
        return profile.age <= maxAge;

      case 'yasmin':
        final minAge = deger is int ? deger : int.tryParse(deger.toString()) ?? 0;
        return profile.age >= minAge;

      case 'meslek':
        return _meslekBool(val, profile.job);

      default:
        return true; // bilinmeyen koşul → göster
    }
  }

  bool _medeniBool(String kondisyon, String profileKey) {
    // kondisyon: asset'ten gelen Turkish string (lowercase)
    // profileKey: dahili key (örn. 'iliskisi_yok', 'evli', ...)
    switch (kondisyon) {
      case 'evli':            return profileKey == 'evli';
      case 'nişanlı':
      case 'nisanli':         return profileKey == 'nisanli';
      case 'ilişkisi var':
      case 'iliski var':
      case 'flört halinde':   return profileKey == 'iliski_var';
      case 'ilişkisi yok':
      case 'iliski yok':
      case 'platonik':        return profileKey == 'iliskisi_yok';
      case 'yeni ayrılmış':
      case 'yeni ayrilmis':   return profileKey == 'yeni_ayrilmis';
      case 'boşanmış':
      case 'bosanmis':        return profileKey == 'bosanmis';
      case 'dul':             return profileKey == 'dul';
      case 'karmaşık':        return profileKey == 'iliski_var' || profileKey == 'yeni_ayrilmis';
      default:                return profileKey.replaceAll('_', ' ') == kondisyon;
    }
  }

  bool _meslekBool(String kondisyon, String profileJob) {
    switch (kondisyon) {
      case 'öğrenci':
      case 'ogrenci':                 return profileJob == 'ogrenci';
      case 'kamu sektörü':
      case 'kamu sektoru':            return profileJob == 'kamusektoru';
      case 'özel sektör':
      case 'ozel sektor':             return profileJob == 'ozelsektoru';
      case 'serbest':
      case 'kendi işini yapıyor':
      case 'kendi isini yapiyor':     return profileJob == 'serbest';
      case 'emekli':                  return profileJob == 'emekli';
      case 'ev hanımı':
      case 'ev hanimi':               return profileJob == 'evhanimi';
      case 'akademisyen':             return profileJob == 'kamusektoru' || profileJob == 'ozelsektoru';
      default:                        return profileJob.replaceAll('_', ' ') == kondisyon;
    }
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
  // Widget builders
  // ─────────────────────────────────────────────────────────────────────────

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

  Widget _buildRainChar(int i) {
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
      child: Text(_rainChars[i],
          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6)),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: double.infinity, height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
            SizedBox(width: 2),
            Text('Geri Git',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _secimBtn(String label, String tur) {
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
                GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 2),
                        Text('Geri Git',
                          style: TextStyle(color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Expanded(child: Text('YANA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.bold, letterSpacing: 1.2))),
                const SizedBox(width: 80), // dengeleyici
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
                        _secimBtn('Bana Dair', 'bana'),
                        const SizedBox(height: 16),
                        _secimBtn('Yaşama Dair', 'yasama'),
                      ]),
                    ),
                  ],
                ),
              )

            // ── gorselKayiyor / odaklanma / yagmur / icerik ─────────────
            else
              Expanded(
                child: LayoutBuilder(builder: (ctx, bc) {
                  final h = bc.maxHeight;
                  final imgTop    = 0.09 * (h - _imgSize);
                  final imgBottom = imgTop + _imgSize;
                  final lowerMid  = imgBottom + (h - imgBottom) / 2;

                  return Stack(children: [

                    // Görsel: merkez → tepe animasyonu — tüm adımlarda sabit
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

                    // odaklanma: metin + ElegantHourglass
                    if (_adim == _YanaAdim.odaklanma)
                      Positioned(
                        top: lowerMid - 70,
                        left: 0, right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Kehanetine odaklanıyorum...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const ElegantHourglass(size: 56, color: Colors.white),
                          ],
                        ),
                      ),

                    // yagmur: karakterler düşüyor
                    if (_adim == _YanaAdim.yagmur)
                      Positioned(
                        top: lowerMid - 60,
                        left: 0, right: 0,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            for (int i = 0; i < _rainChars.length; i++)
                              _buildRainChar(i),
                          ],
                        ),
                      ),

                    // icerik: görsel yerinde sabit kalır, altında kehanet metni belirir
                    if (_adim == _YanaAdim.icerik)
                      Positioned(
                        top: imgBottom + 12,
                        left: 0, right: 0, bottom: 0,
                        child: AnimatedBuilder(
                          animation: _fadeAnim,
                          builder: (ctx, child) =>
                              Opacity(opacity: _fadeAnim.value, child: child),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFFF55FF).withValues(alpha: 0.30),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: RichTextParser.build(
                                      _metin,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.7,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                child: _buildCloseButton(),
                              ),
                            ],
                          ),
                        ),
                      ),

                  ]);
                }),
              ),
          ],
        ),
      ),
    );
  }
}
