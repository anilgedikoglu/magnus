// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\JaponFali\Metinler
// JSON:   assets/data/japonfali.json
// Arka plan: assets/images/falbg/omikujibg.png
//
// Akış:
//   1. Ekran açılır → "Japon Falı çalışılıyor..." + kum saati (5s)
//   2. Metin no-repeat ile seçilir, inbox'a eklenir (unlockAt = +2 dakika)
//   3. japonFaliSentProvider = true → ana menüye dön

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../data/providers.dart';
import '../../data/models/inbox_item.dart';

class JaponFaliScreen extends ConsumerStatefulWidget {
  const JaponFaliScreen({super.key});

  @override
  ConsumerState<JaponFaliScreen> createState() => _JaponFaliScreenState();
}

class _JaponFaliScreenState extends ConsumerState<JaponFaliScreen> {

  static const _prefKeyGosterilen = 'japonfali_gosterilen';

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // 5 saniye bekle
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    await _generateAndSave();
    if (!mounted) return;

    setState(() => _done = true);
    ref.read(japonFaliSentProvider.notifier).state = true;
    context.go('/home');
  }

  Future<void> _generateAndSave() async {
    final prefs   = await SharedPreferences.getInstance();
    final profile = ref.read(userProfileProvider);
    final vars    = profile.toVariableMap();

    final raw  = await rootBundle.loadString('assets/data/japonfali.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final tumListe = (data['japonfali'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // Koşul filtresi
    final uygunlar = tumListe.where((e) {
      final kosullar = (e['kosullar'] as List?) ?? [];
      if (kosullar.isEmpty) return true;
      for (final k in kosullar) {
        final deg = '${(k as Map)['degisken'] ?? ''}';
        final bek = '${k['deger'] ?? ''}';
        final grc = vars[deg] ?? '';
        if (grc != bek) return false;
      }
      return true;
    }).toList();

    if (uygunlar.isEmpty) return;

    // No-repeat seçim
    List<String> gosterilen = prefs.getStringList(_prefKeyGosterilen) ?? [];
    var kalan = uygunlar.where((e) => !gosterilen.contains('${e['id']}')).toList();

    if (kalan.isEmpty) {
      final lastId = gosterilen.isNotEmpty ? gosterilen.last : null;
      gosterilen = lastId != null ? [lastId] : [];
      await prefs.setStringList(_prefKeyGosterilen, gosterilen);
      kalan = uygunlar.where((e) => '${e['id']}' != lastId).toList();
      if (kalan.isEmpty) kalan = List.from(uygunlar);
    }

    kalan.shuffle(Random());
    final secilen = kalan.first;
    gosterilen.add('${secilen['id']}');
    await prefs.setStringList(_prefKeyGosterilen, gosterilen);

    final isEn = ref.read(localeProvider) == 'en';
    final secilenMetin = (isEn && (secilen['metin_en'] as String?)?.isNotEmpty == true)
        ? secilen['metin_en'] as String
        : secilen['metin'] as String;
    final metin = VariableReplacer.replace(secilenMetin, vars);

    // 2 dakika sonra açılır
    final now      = DateTime.now();
    final unlockAt = now.add(const Duration(minutes: 2)).toIso8601String();

    final item = InboxItem(
      id:             const Uuid().v4(),
      title:          'Japon Falın Hazır',
      text:           metin,
      date:           now.toIso8601String(),
      fortuneTypeKey: 'japonfali',
      iconAsset:      'assets/images/inbox_icons/japonfali.png',
      unlockAt:       unlockAt,
    );
    ref.read(inboxProvider.notifier).addItem(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/falbg/omikujibg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A0008)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x55000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Başlık
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _done ? null : () => context.pop(),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFCC2244).withValues(alpha: 0.5), width: 1),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFFF4466),
                            size: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            ref.watch(l10nProvider).japonFaliTitle,
                            style: GoogleFonts.cinzel(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF4466),
                              letterSpacing: 4,
                              shadows: const [
                                Shadow(color: Color(0xAAFF4466), blurRadius: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),
                const Spacer(),
                // Logo + kum saati + yazı
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Omikuji: kutu sallanır, sonunda içinden kehanet çubuğu çıkar (2026-11-06).
                    const _OmikujiShake(),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF180008).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFFF4466).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4466).withValues(alpha: 0.15),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            ref.watch(l10nProvider).japonFaliWorking,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: 15,
                              color: const Color(0xFFFF4466),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DotsIndicator(color: const Color(0xFFFF4466)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const FloatingBarSpacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Omikuji kutusu: ~3,2 sn sönümlenen sallantı (her vuruşta hafif tık), sonra tepedeki
/// delikten bambu çubuk yükselir (orta vuruş). Toplam ~4,4 sn.
class _OmikujiShake extends StatefulWidget {
  const _OmikujiShake();
  @override
  State<_OmikujiShake> createState() => _OmikujiShakeState();
}

class _OmikujiShakeState extends State<_OmikujiShake> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4400));
  int _lastSwing = -1;
  bool _stickHaptic = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final ms = _c.value * 4400;
      if (ms < 3200) {
        final swing = (ms / 160).floor(); // yaklaşık 6 Hz yön değişimi
        if (swing != _lastSwing && swing.isEven) HapticFeedback.selectionClick();
        _lastSwing = swing;
      } else if (!_stickHaptic && ms > 3500) {
        _stickHaptic = true;
        HapticFeedback.mediumImpact();
      }
    });
    final reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduce) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 120,
        height: 150,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(painter: _OmikujiPainter(_c.value * 4400)),
        ),
      );
}

class _OmikujiPainter extends CustomPainter {
  _OmikujiPainter(this.ms);
  final double ms;

  @override
  void paint(Canvas canvas, Size size) {
    final shake = ms < 3200 ? (1 - ms / 3200) : 0.0;
    final ang = sin(ms / 1000 * 2 * pi * 3.1) * 0.16 * shake;
    final bw = size.width * 0.62, bh = size.height * 0.62;
    final base = Offset(size.width / 2, size.height * 0.96);
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(ang);
    // Çubuk (kutudan yükselir)
    final rise = ((ms - 3300) / 900).clamp(0.0, 1.0);
    final stickLen = bh * 0.9;
    final stickTop = -bh - stickLen * Curves.easeOutBack.transform(rise) * 0.62;
    if (rise > 0) {
      final st = Rect.fromLTRB(-bw * 0.06, stickTop, bw * 0.06, -bh + 6);
      canvas.drawRRect(RRect.fromRectAndRadius(st, const Radius.circular(3)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFE8D29A), Color(0xFFF7EBC4), Color(0xFFC9A95E)],
            ).createShader(st));
      // çubuğun kırmızı ucu
      canvas.drawRect(Rect.fromLTRB(st.left, st.top, st.right, st.top + 10),
          Paint()..color = const Color(0xFFCC2244));
    }
    // Kutu: altıgen prizma görünümü (ön yüz + yan yüzler), kırmızı lake, altın bant
    final body = Rect.fromLTRB(-bw / 2, -bh, bw / 2, 0);
    canvas.drawRRect(RRect.fromRectAndRadius(body.shift(const Offset(3, 4)), const Radius.circular(6)),
        Paint()..color = const Color(0x88000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6E0F1E), Color(0xFFC0273B), Color(0xFF8A1426), Color(0xFF52091A)],
          stops: [0.0, 0.35, 0.7, 1.0],
        ).createShader(body),
    );
    for (final y in [-bh * 0.82, -bh * 0.18]) {
      canvas.drawRect(Rect.fromLTRB(-bw / 2, y - 3, bw / 2, y + 3),
          Paint()..color = const Color(0xFFD4AF37));
    }
    // yan yüz çizgileri (altıgen hissi)
    final edge = Paint()..color = const Color(0x55000000)..strokeWidth = 1.4;
    canvas.drawLine(Offset(-bw * 0.22, -bh), Offset(-bw * 0.22, 0), edge);
    canvas.drawLine(Offset(bw * 0.22, -bh), Offset(bw * 0.22, 0), edge);
    // tepedeki delik
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -bh), width: bw * 0.3, height: 7),
        Paint()..color = const Color(0xFF1A0408));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OmikujiPainter old) => old.ms != ms;
}

// Sıralı nokta animasyonu
class _DotsIndicator extends StatefulWidget {
  final Color color;
  const _DotsIndicator({required this.color});

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator> {
  int _step = 0;
  late final _timer = Stream.periodic(const Duration(milliseconds: 500))
      .listen((_) { if (mounted) setState(() => _step = (_step + 1) % 4); });

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i < _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? widget.color
                : widget.color.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}
