// lib/presentation/kehanet/el_fali_screen.dart
// El Falı — fotoğraf çekme/seçme, el analizi ve fal ekranı.
// Kaynak metinler: assets/data/elfali.json

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/providers.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/floating_bar_spacer.dart';
enum _EFAdim { secim, analiz, sonuc }

class ElFaliScreen extends ConsumerStatefulWidget {
  const ElFaliScreen({super.key});

  @override
  ConsumerState<ElFaliScreen> createState() => _ElFaliScreenState();
}

class _ElFaliScreenState extends ConsumerState<ElFaliScreen>
    with SingleTickerProviderStateMixin {
  _EFAdim _adim = _EFAdim.secim;
  File?   _foto;
  bool    _gunlukDoldu = false;

  // Parsed result
  String _genelMetin = '';
  List<Map<String, dynamic>> _hatlar = [];

  @override
  void initState() {
    super.initState();
    _kontrolEt();
  }

  Future<void> _kontrolEt() async {
    final prefs    = await SharedPreferences.getInstance();
    final today    = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final saved    = prefs.getString('elfali_bugun_tarih') ?? '';
    if (mounted && saved == todayStr) {
      setState(() => _gunlukDoldu = true);
    }
  }

  /// TR/EN metin (ekranda İngilizcesi eksikti).
  String _t(String tr, String en) => ref.read(localeProvider) == 'en' ? en : tr;

  // ── [DEBUG] Test görseli yükle ───────────────────────────────────────────
  Future<void> _testGorseliYukle() async {
    try {
      final bytes = await rootBundle.load('assets/images/test/elfali_test.jpg');
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/elfali_test.jpg');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (!mounted) return;
      setState(() {
        _foto = file;
        _adim = _EFAdim.analiz;
      });
      final prefs    = await SharedPreferences.getInstance();
      final today    = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      await prefs.setString('elfali_bugun_tarih', todayStr);
      await _analizEt();
    } catch (e) {
      if (mounted) setState(() => _adim = _EFAdim.secim);
    }
  }

  // ── Fotoğraf seç / çek ────────────────────────────────────────────────────
  Future<void> _secimiYap(ImageSource source) async {
    try {
      final xFile = await ImagePicker().pickImage(
        source:       source,
        maxWidth:     512,
        maxHeight:    512,
        imageQuality: 75,
      );
      if (xFile == null || !mounted) return;

      setState(() {
        _foto = File(xFile.path);
        _adim = _EFAdim.analiz;
      });

      // Günlük hakkı işaretle
      final prefs    = await SharedPreferences.getInstance();
      final today    = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      await prefs.setString('elfali_bugun_tarih', todayStr);

      await _analizEt();
    } catch (e) {
      if (mounted) setState(() => _adim = _EFAdim.secim);
    }
  }

  // ── Fal üretimi ───────────────────────────────────────────────────────────
  Future<void> _analizEt() async {
    try {
      // API kontrolü yok — fotoğraf alındıktan sonra direkt fal üretilir
      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;

      // Fal üret
      final fortuneService = ref.read(fortuneServiceProvider);
      final profile        = ref.read(userProfileProvider);
      final item           = await fortuneService.generateElFali(profile: profile);

      // Inbox'a kaydet
      await ref.read(inboxProvider.notifier).addItem(item);

      // Ana menüye dön, balon göster
      if (!mounted) return;
      ref.read(elFaliSentProvider.notifier).state = true;
      context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _adim = _EFAdim.secim);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060812),
      body: SafeArea(
        child: Column(
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    ref.watch(l10nProvider).palmReadingTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle,
                  ),
                ),
                const SizedBox(width: 48),
              ]),
            ),

            Expanded(
              child: switch (_adim) {
                _EFAdim.secim  => _buildSecim(),
                _EFAdim.analiz => _buildAnaliz(),
                _EFAdim.sonuc  => _buildSonuc(),
              },
            ),
            const FloatingBarSpacer(),
          ],
        ),
      ),
    );
  }

  // ── Ortak fotoğraf alanı ──────────────────────────────────────────────────
  Widget _buildFotoAlan({double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.40),
          width: 1.5,
        ),
        color: const Color(0xFF0D0A1E),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: _foto != null
            ? SizedBox.expand(child: Image.file(_foto!, fit: BoxFit.cover))
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.back_hand_rounded,
                      color: Colors.white.withValues(alpha: 0.18),
                      size: 80,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _t('Avucunu göster', 'Show your palm'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.28),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Durum: secim ─────────────────────────────────────────────────────────
  Widget _buildSecim() {
    if (_gunlukDoldu) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35), width: 1.5),
              ),
              child: const Center(child: Text('🔒', style: TextStyle(fontSize: 38))),
            ),
            const SizedBox(height: 28),
            Text(
              _t('Günlük hakkın doldu', "You've used today's reading"),
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _t('El falı günde 1 kez bakılabilir.\nYarın tekrar gel.',
                  'Palm reading is available once a day.\nCome back tomorrow.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15, height: 1.6),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _t('Avucunu kameraya aç, çizgiler net görünsün.',
                'Open your palm to the camera so the lines are clear.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB8A8D8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _buildFotoAlan(),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, kDebugMode ? 8 : 24),
          child: Row(
            children: [
              Expanded(
                child: _FotoButon(
                  icon: Icons.camera_alt_rounded,
                  label: _t('Fotoğraf Çek', 'Take Photo'),
                  onTap: () => _secimiYap(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FotoButon(
                  icon: Icons.photo_library_rounded,
                  label: _t('Telefondan Seç', 'Choose from Phone'),
                  onTap: () => _secimiYap(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
        // [DEBUG] Test butonu — sadece debug modunda görünür
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GestureDetector(
              onTap: _testGorseliYukle,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.orange.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.40)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🧪', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 5),
                    Text(
                      'TEST — Örnek El Görseli',
                      style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Durum: analiz ─────────────────────────────────────────────────────────
  Widget _buildAnaliz() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            // Okuma ritüeli: avuç çizgileri fotoğrafın üstüne sırayla, ışıyarak çizilir
            // (2026-11-06, Grok/Codex: avuç fotoğrafında hiçbir efekt yoktu).
            child: Stack(fit: StackFit.expand, children: [
              _buildFotoAlan(),
              const IgnorePointer(child: AvucCizgileri()),
            ]),
          ),
        ),
        const Spacer(),
        Text(
          _t('El çizgilerin okunuyor...', 'Reading the lines of your hand...'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ── Durum: sonuc ─────────────────────────────────────────────────────────
  Widget _buildSonuc() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genel değerlendirme
                if (_genelMetin.isNotEmpty) ...[
                  Text(
                    _t('Genel Değerlendirme', 'Overall Reading'),
                    style: TextStyle(
                      color: Color(0xFFD8B4FE),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _genelMetin,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.75,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                ],
                // Hatlar
                ..._hatlar.map((hat) => _buildHatRow(hat)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Text(
                _t('El falın gelen kutuna kaydedildi.', 'Your palm reading was saved to your inbox.'),
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildGradientButton(
                label: _t('Kapat', 'Close'),
                onTap: () => context.pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHatRow(Map<String, dynamic> hat) {
    final ad    = hat['ad'] as String;
    final renk  = hat['renk'] as String;
    final yuzde = hat['yuzde'] as int;
    final metin = hat['metin'] as String;
    final color = _hatRengi(renk);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hat adı + yüzde
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ad,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '%$yuzde',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: yuzde / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          // Açıklama metni
          Text(
            metin,
            style: const TextStyle(
              color: Color(0xFFE2D9F3),
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  static Color _hatRengi(String renk) {
    switch (renk.toLowerCase()) {
      case 'red':        return const Color(0xFFEF4444);
      case 'darkgreen':  return const Color(0xFF22C55E);
      case 'green':      return const Color(0xFF4ADE80);
      case 'blue':       return const Color(0xFF60A5FA);
      case 'orange':     return const Color(0xFFFB923C);
      case 'brown':      return const Color(0xFFD97706);
      case 'yellow':     return const Color(0xFFFBBF24);
      case 'pink':       return const Color(0xFFF472B6);
      case 'magenta':    return const Color(0xFFA855F7);
      case 'cyan':       return const Color(0xFF22D3EE);
      default:           return const Color(0xFF818CF8);
    }
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.80),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fotoğraf seçim butonu ─────────────────────────────────────────────────────
class _FotoButon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FotoButon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1035), Color(0xFF2A1A55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avuç çizgileri: kalp, akıl, hayat, kader ve güneş çizgisi (fotoğraf alanına göre normalize
/// eğriler) sırayla ~0,35 sn'de çizilir; ucu parlar, her çizgi bitince hafif tık. Sonra
/// çizgiler yavaşça nefes alır. Tarama ışığı yukarıdan aşağı süzülür.
@visibleForTesting
class AvucCizgileri extends StatefulWidget {
  const AvucCizgileri({super.key});
  @override
  State<AvucCizgileri> createState() => _AvucCizgileriState();
}

class _AvucCizgileriState extends State<AvucCizgileri> with SingleTickerProviderStateMixin {
  // Çizgiler ilk ~2,4 sn'de çizilir; sonra [_dongu, _toplam] aralığı sonsuz döner: tarama
  // (2,4 sn) ve nefes (1,8 sn) 7,2 sn'de birlikte başa döner → dikişsiz (analiz uzun sürerse
  // ekran donmuş görünmesin; inceleme bulgusu).
  static const _toplam = 9800.0;
  static const _dongu = 2600.0;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: _toplam.toInt()));
  int _bitenler = 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final n = (_c.value * _toplam / 420).floor().clamp(0, 5);
      if (n > _bitenler) {
        _bitenler = n;
        HapticFeedback.selectionClick();
      }
    });
    final reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduce) {
      _c.value = 1;
    } else {
      _c.forward().then((_) {
        if (mounted) _c.repeat(min: _dongu / _toplam, max: 1);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _AvucPainter(_c.value * _toplam)),
      );
}

class _AvucPainter extends CustomPainter {
  _AvucPainter(this.ms);
  final double ms;

  // (başlangıç, kontrol1, kontrol2, bitiş) — alan oranında
  static const _cizgiler = <List<Offset>>[
    [Offset(0.18, 0.40), Offset(0.36, 0.33), Offset(0.58, 0.33), Offset(0.84, 0.38)], // kalp
    [Offset(0.20, 0.50), Offset(0.38, 0.47), Offset(0.56, 0.52), Offset(0.76, 0.58)], // akıl
    [Offset(0.30, 0.42), Offset(0.22, 0.58), Offset(0.26, 0.74), Offset(0.42, 0.90)], // hayat
    [Offset(0.52, 0.90), Offset(0.52, 0.76), Offset(0.50, 0.60), Offset(0.52, 0.44)], // kader
    [Offset(0.66, 0.86), Offset(0.66, 0.76), Offset(0.67, 0.66), Offset(0.68, 0.56)], // güneş
  ];
  static const _renkler = [
    Color(0xFFFF55FF), Color(0xFF00CCFF), Color(0xFF44FF88), Color(0xFFFFD27A), Color(0xFFFF8A5B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(Offset o) => Offset(o.dx * size.width, o.dy * size.height);
    // Tarama ışığı (yukarıdan aşağı, 2,4 sn döngü)
    final scan = (ms % 2400) / 2400;
    final y = size.height * scan;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 40, size.width, 80),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x0000CCFF),
            const Color(0xFF00CCFF).withValues(alpha: 0.18),
            const Color(0x0000CCFF),
          ],
        ).createShader(Rect.fromLTWH(0, y - 40, size.width, 80)),
    );
    final nefes = 0.75 + 0.25 * sin(ms / 1000 * 2 * pi / 1.8);
    for (var i = 0; i < _cizgiler.length; i++) {
      final p = ((ms - 300 - i * 420) / 380).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final c = _cizgiler[i];
      final path = Path()
        ..moveTo(at(c[0]).dx, at(c[0]).dy)
        ..cubicTo(at(c[1]).dx, at(c[1]).dy, at(c[2]).dx, at(c[2]).dy, at(c[3]).dx, at(c[3]).dy);
      final m = path.computeMetrics().first;
      final part = m.extractPath(0, m.length * Curves.easeInOutSine.transform(p));
      final renk = _renkler[i];
      final a = p < 1 ? 1.0 : nefes;
      canvas.drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 7
            ..color = renk.withValues(alpha: 0.35 * a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.2
            ..color = Color.lerp(renk, Colors.white, 0.35)!.withValues(alpha: 0.95 * a));
      if (p < 1) {
        final uc = m.getTangentForOffset(m.length * Curves.easeInOutSine.transform(p))?.position;
        if (uc != null) {
          canvas.drawCircle(uc, 6, Paint()..color = Colors.white.withValues(alpha: 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AvucPainter old) => old.ms != ms;
}
