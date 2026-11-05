// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\IChing\Metinler
// JSON:   assets/data/iching.json
// Arka plan: assets/images/falbg/ichingbg.png
//
// Akış:
//   1. Ekran açılır → "Zarlar atılıyor, lütfen bekle..." + kum saati (5s)
//   2. Metin no-repeat ile seçilir, inbox'a eklenir (unlockAt = +2 dakika)
//   3. ichingSentProvider = true → ana menüye dön

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

class IChingScreen extends ConsumerStatefulWidget {
  const IChingScreen({super.key});

  @override
  ConsumerState<IChingScreen> createState() => _IChingScreenState();
}

class _IChingScreenState extends ConsumerState<IChingScreen> {

  static const _prefKeyGosterilen = 'iching_gosterilen';

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
    ref.read(ichingSentProvider.notifier).state = true;
    context.go('/home');
  }

  Future<void> _generateAndSave() async {
    final prefs   = await SharedPreferences.getInstance();
    final profile = ref.read(userProfileProvider);
    final vars    = profile.toVariableMap();

    final raw  = await rootBundle.loadString('assets/data/iching.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final tumListe = (data['iching'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // Koşul filtresi (boş kosullar = herkese)
    final uygunlar = tumListe.where((e) {
      final kosullar = (e['kosullar'] as List?) ?? [];
      if (kosullar.isEmpty) return true;
      for (final k in kosullar) {
        final deg = '${(k as Map)['degisken'] ?? ''}';
        final bek = '${k['deger'] ?? ''}';
        final grc = _profileDegeri(deg, profile.toVariableMap());
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
      title:          'I-Ching Falın Hazır',
      text:           metin,
      date:           now.toIso8601String(),
      fortuneTypeKey: 'iching',
      iconAsset:      'assets/images/ichingikon.png',
      unlockAt:       unlockAt,
    );
    ref.read(inboxProvider.notifier).addItem(item);
  }

  String _profileDegeri(String deg, Map<String, String> vars) {
    return vars[deg] ?? '';
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
            'assets/images/falbg/ichingbg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050A0F)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x66000000),
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
                              color: const Color(0xFFB8941F).withValues(alpha: 0.5), width: 1),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFD4AF37),
                            size: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            ref.watch(l10nProvider).ichingTitle,
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD4AF37),
                              letterSpacing: 5,
                              shadows: const [
                                Shadow(color: Color(0xAAD4AF37), blurRadius: 18),
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
                // Kum saati + yazı
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bekleme bir ritüel: hexagram aşağıdan yukarı çizgi çizgi atılır (2026-11-06;
                    // eskiden "zarlar atılıyor" yazıp yalnız kum saati gösteriyordu).
                    const _HexagramCasting(),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080E18).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            ref.watch(l10nProvider).ichingRolling1,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              color: const Color(0xFFD4AF37),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ref.watch(l10nProvider).ichingRolling2,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              color: const Color(0xFFD4AF37),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Nokta animasyonu
                          _DotsIndicator(),
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

/// Hexagram atılışı: 6 çizgi (yin kesik / yang düz) alttan üste ~0,75 sn arayla belirir;
/// her çizgide altın parlama + hafif tık. Toplam ~4,6 sn (ekran 5 sn bekler).
class _HexagramCasting extends StatefulWidget {
  const _HexagramCasting();
  @override
  State<_HexagramCasting> createState() => _HexagramCastingState();
}

class _HexagramCastingState extends State<_HexagramCasting> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4600));
  final List<bool> _yang = List.generate(6, (_) => Random().nextBool());
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final n = (_c.value * 6.4).floor().clamp(0, 6);
      if (n > _shown) {
        _shown = n;
        HapticFeedback.selectionClick();
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
        width: 180,
        height: 150,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) =>
              CustomPaint(painter: _HexagramPainter(t: _c.value, yang: _yang)),
        ),
      );
}

class _HexagramPainter extends CustomPainter {
  _HexagramPainter({required this.t, required this.yang});
  final double t;
  final List<bool> yang;
  static const _gold = Color(0xFFD4AF37);

  @override
  void paint(Canvas canvas, Size size) {
    final lineH = size.height / 6 * 0.46;
    final gap = size.height / 6;
    for (var i = 0; i < 6; i++) {
      // i = 0 en alttaki çizgi
      final p = ((t * 6.4 - i) / 0.8).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final e = Curves.easeOutCubic.transform(p);
      final cy = size.height - gap * (i + 0.5);
      final half = size.width / 2 * e;
      final cx = size.width / 2;
      final glow = Paint()
        ..color = _gold.withValues(alpha: 0.55 * (1 - p) + 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 10 * (1 - p));
      final fill = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB8941F), Color(0xFFFFE9A3), Color(0xFFB8941F)],
        ).createShader(Rect.fromLTWH(0, cy - lineH / 2, size.width, lineH));
      final rects = <RRect>[];
      if (yang[i]) {
        rects.add(RRect.fromRectAndRadius(
            Rect.fromLTRB(cx - half, cy - lineH / 2, cx + half, cy + lineH / 2),
            Radius.circular(lineH / 2)));
      } else {
        final g = size.width * 0.07;
        if (half > g) {
          rects.add(RRect.fromRectAndRadius(
              Rect.fromLTRB(cx - half, cy - lineH / 2, cx - g, cy + lineH / 2),
              Radius.circular(lineH / 2)));
          rects.add(RRect.fromRectAndRadius(
              Rect.fromLTRB(cx + g, cy - lineH / 2, cx + half, cy + lineH / 2),
              Radius.circular(lineH / 2)));
        }
      }
      for (final r in rects) {
        canvas.drawRRect(r, glow);
        canvas.drawRRect(r, fill);
      }
      // Belirme parlaması (çizginin merkezinde genişleyen halka)
      if (p < 1) {
        canvas.drawCircle(
          Offset(cx, cy),
          8 + 40 * e,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = _gold.withValues(alpha: 0.6 * (1 - p)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HexagramPainter old) => old.t != t;
}

// Sıralı nokta animasyonu
class _DotsIndicator extends StatefulWidget {
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
                ? const Color(0xFFD4AF37)
                : const Color(0xFFD4AF37).withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}
