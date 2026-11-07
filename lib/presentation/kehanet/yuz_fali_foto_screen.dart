// lib/presentation/kehanet/yuz_fali_foto_screen.dart
// Yüz Falı — fotoğraf çekme/seçme, analiz ve fal metni ekranı.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';
import '../../data/services/face_analyzer.dart';
import '../../data/services/photo_subject_detector.dart';
import 'package:uuid/uuid.dart';
import '../../core/widgets/floating_bar_spacer.dart';

enum _YFAdim { secim, analiz, hatali, sonuc }

class YuzFaliFotoScreen extends ConsumerStatefulWidget {
  /// 'kullanici' veya 'baskasi'
  final String kimin;

  const YuzFaliFotoScreen({super.key, required this.kimin});

  @override
  ConsumerState<YuzFaliFotoScreen> createState() => _YuzFaliFotoScreenState();
}

class _YuzFaliFotoScreenState extends ConsumerState<YuzFaliFotoScreen>
    with SingleTickerProviderStateMixin {
  /// TR/EN metin (paralel İngilizce kuralı, 2026-11-06).
  String _t(String tr, String en) => ref.read(localeProvider) == 'en' ? en : tr;

  _YFAdim _adim = _YFAdim.secim;
  File?   _foto;
  String  _falMetni  = '';
  String  _hataMetni = '';

  final _rng = Random();

  // ── Tarama çizgisi animasyonu ─────────────────────────────────────────────
  late final AnimationController _scanCtrl;
  late final Animation<double>   _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scanAnim = CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  // ── [DEBUG] Test görseli yükle ───────────────────────────────────────────
  Future<void> _testGorseliYukle() async {
    try {
      final bytes = await rootBundle.load('assets/images/test/yuzfali_test.jpg');
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/yuzfali_test.jpg');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (!mounted) return;
      setState(() {
        _foto = file;
        _adim = _YFAdim.analiz;
      });
      _scanCtrl.repeat(reverse: true);
      await _analizEt();
      if (mounted) _scanCtrl.stop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hataMetni = 'Test görseli yüklenemedi: $e';
          _adim      = _YFAdim.hatali;
        });
      }
    }
  }

  // ── Fotoğraf seç / çek ────────────────────────────────────────────────────
  Future<void> _secimlYap(ImageSource source) async {
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
        _adim = _YFAdim.analiz;
      });

      // Günlük hak, ön kontrol GEÇİNCE _analizEt içinde işaretlenir (yanlış fotoda hak gitmesin).
      _scanCtrl.repeat(reverse: true);
      await _analizEt();
      if (mounted) _scanCtrl.stop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hataMetni = _t('Fotoğraf alınamadı. Lütfen tekrar dene.', "Couldn't get the photo. Please try again.");
          _adim      = _YFAdim.hatali;
        });
      }
    }
  }

  // ── Cihaz-içi (offline) analiz + metin oluşturma ──────────────────────────
  // Eskiden Claude Vision API'ye bağlıydı → internet hatasında çöküyordu (Anıl, 2026-11-06).
  // Artık `OnDeviceFaceAnalyzer` ile tamamen offline; hiç hata vermez.
  Future<void> _analizEt() async {
    final isSelf = widget.kimin == 'kullanici';
    final profileGender = ref.read(userProfileProvider).gender; // await ÖNCESİ

    // ── Ön kontrol: gönderilen foto gerçekten bir yüz mü? Değilse hak tüketmeden uyar.
    final uygun = await PhotoSubjectDetector.uygunMu(_foto!.path, FotoKonu.yuz);
    if (!mounted) return;
    if (!uygun) {
      _scanCtrl.stop();
      setState(() {
        _hataMetni = ref.read(l10nProvider).photoNotFace;
        _adim      = _YFAdim.hatali;
      });
      return;
    }

    // Fal üretimi + inbox + günlük hak TEK İŞ (Codex P1): 12 sn "analiz ediliyor" sırasında geri
    // çıksa bile arka planda tamamlanır → ne hak boşa gider ne fal kaybolur. Hak YALNIZ fal kaydedilince.
    final profile       = ref.read(userProfileProvider);
    final inboxNotifier = ref.read(inboxProvider.notifier);
    final prefs         = ref.read(sharedPrefsProvider);
    final fotoPath      = _foto!.path;
    final kimin         = widget.kimin;
    final today         = DateTime.now();
    final todayStr      = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final isEn          = ref.read(localeProvider) == 'en';
    Future<void>(() async {
      final analiz = await OnDeviceFaceAnalyzer.analiz(fotoPath, isSelf: isSelf, profileGender: profileGender);
      final jsonKey = kimin == 'kullanici'
          ? 'assets/data/yuzfali_kullanici.json'
          : 'assets/data/yuzfali_baskasi.json';
      final jsonStr = await rootBundle.loadString(jsonKey);
      final data    = jsonDecode(jsonStr) as Map<String, dynamic>;
      final cinsiyet = kimin == 'kullanici' ? profile.gender : analiz.cinsiyet;
      final tamKey = cinsiyet == 'erkek' ? 'yuzfalitame' : 'yuzfalitamkl';
      final parcalar = <String>[];
      // İngilizcesi varsa onu kullan (parallel İngilizce kuralı); yoksa Türkçe.
      String sec(List<dynamic>? liste) {
        if (liste == null || liste.isEmpty) return '';
        final item = liste[_rng.nextInt(liste.length)] as Map<String, dynamic>;
        final en = (item['metin_en'] as String?)?.trim();
        if (isEn && en != null && en.isNotEmpty) return en;
        return (item['metin'] as String? ?? '').trim();
      }
      String kategori(String cat, String variant) {
        final m = data[cat] as Map<String, dynamic>?;
        if (m == null) return '';
        return sec(m[variant] as List<dynamic>?);
      }
      final t = sec(data[tamKey] as List<dynamic>?);
      if (t.isNotEmpty) parcalar.add(t);
      final ozellikler = [
        ('yfmoral',    analiz.moral),
        ('yfsapka',    analiz.sapka),
        ('yfsacrengi', analiz.sacRengi),
        ('yfsacboyu',  analiz.sacBoyu),
        ('yfgozrengi', analiz.gozRengi),
        ('yfgozluk',   analiz.gozluk),
        ('yfsakal',    analiz.sakal),
      ];
      for (final (cat, variant) in ozellikler) {
        final p = kategori(cat, variant);
        if (p.isNotEmpty) parcalar.add(p);
      }
      final varMap = profile.toVariableMap();
      final falMetni = parcalar.map((p) => VariableReplacer.replace(p, varMap)).join('\n\n');
      final now = DateTime.now();
      final inboxItem = InboxItem(
        id:             const Uuid().v4(),
        title:          isEn ? 'Your Face Reading Is Ready' : 'Yüz Falın Hazır',
        text:           falMetni,
        date:           now.toIso8601String(),
        fortuneTypeKey: 'yuzfali',
        iconAsset:      'assets/images/inbox_icons/elfali.png',
        unlockAt:       now.add(const Duration(minutes: 6)).toIso8601String(),
        // Yüz fotoğrafı: detayda üst-orta gösterilsin (kahve falı foto yolu saklama deseniyle aynı).
        photoPath1:     fotoPath,
      );
      await inboxNotifier.addItem(inboxItem);
      await prefs.setString('yuzfali_bugun_tarih', todayStr);
    }).catchError((_) {/* üretilemezse hak yazılmaz */});

    // Ekranda 12 sn "analiz ediliyor", sonra ana menü.
    await Future.delayed(const Duration(seconds: 12));
    if (!mounted) return;
    ref.read(yuzFaliSentProvider.notifier).state = true;
    context.go('/home');
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
          children: [
            // ── Başlık ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    widget.kimin == 'kullanici' ? ref.watch(l10nProvider).faceFortuneTilte : ref.watch(l10nProvider).faceFortuneTilte,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ]),
            ),

            // ── Ana içerik ───────────────────────────────────────────────
            Expanded(
              child: switch (_adim) {
                _YFAdim.secim  => _buildSecim(),
                _YFAdim.analiz => _buildAnaliz(),
                _YFAdim.hatali => _buildHatali(),
                _YFAdim.sonuc  => _buildSonuc(),
              },
            ),
            const FloatingBarSpacer(),
          ],
        ),
      ),
    );
  }

  // ── Fotoğraf alanı (ortak widget) ─────────────────────────────────────────
  Widget _buildFotoAlan({double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF55FF).withValues(alpha: 0.35),
          width: 1.5,
        ),
        color: const Color(0xFF110430),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B00D3).withValues(alpha: 0.15),
            blurRadius: 16,
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
                    Icon(Icons.face_retouching_natural,
                        color: Colors.white.withValues(alpha: 0.2), size: 72),
                    const SizedBox(height: 14),
                    Text(
                      _t('Fotoğraf seç veya çek', 'Choose or take a photo'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Durum: secim ──────────────────────────────────────────────────────────
  Widget _buildSecim() {
    return Column(
      children: [
        // Fotoğraf alanı
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _buildFotoAlan(),
          ),
        ),
        // Butonlar
        Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, kDebugMode ? 8 : 24),
          child: Row(
            children: [
              Expanded(
                child: _FotoButon(
                  icon: Icons.camera_alt_rounded,
                  label: _t('Fotoğraf Çek', 'Take Photo'),
                  onTap: () => _secimlYap(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FotoButon(
                  icon: Icons.photo_library_rounded,
                  label: _t('Telefondan Seç', 'Choose from Phone'),
                  onTap: () => _secimlYap(ImageSource.gallery),
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
                      'TEST — Örnek Yüz Görseli',
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
        // Fotoğraf + tarama animasyonu
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              children: [
                // Fotoğraf
                _buildFotoAlan(),
                // Tarama çizgisi
                ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (context, _) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final h    = constraints.maxHeight;
                          const lineH = 60.0;
                          final top  = _scanAnim.value * (h - lineH);
                          return Stack(
                            children: [
                              Positioned(
                                top:   top,
                                left:  0,
                                right: 0,
                                height: lineH,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end:   Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF00CCFF).withValues(alpha: 0.10),
                                        const Color(0xFF00EEFF).withValues(alpha: 0.75),
                                        const Color(0xFFFFFFFF).withValues(alpha: 0.90),
                                        const Color(0xFF00EEFF).withValues(alpha: 0.75),
                                        const Color(0xFF00CCFF).withValues(alpha: 0.10),
                                        Colors.transparent,
                                      ],
                                      stops: const [0, 0.30, 0.46, 0.50, 0.54, 0.70, 1],
                                    ),
                                  ),
                                ),
                              ),
                              // Yatay parlak ışık sızıntısı (kenarlarda solar)
                              Positioned(
                                top:   top + lineH * 0.45,
                                left:  0,
                                right: 0,
                                height: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00EEFF).withValues(alpha: 0.70),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),

        // Yazı
        Text(
          _t('Analiz ediliyor...', 'Analyzing...'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),

        // Animasyonlu kum saati
        const ElegantHourglass(size: 56, color: Colors.white),
        const Spacer(),
      ],
    );
  }

  // ── Durum: hatali ─────────────────────────────────────────────────────────
  Widget _buildHatali() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 24),
          Text(
            _hataMetni,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          _buildGradientButton(
            label: _t('Tekrar Dene', 'Try Again'),
            onTap: () => setState(() {
              _foto      = null;
              _hataMetni = '';
              _adim      = _YFAdim.secim;
            }),
          ),
        ],
      ),
    );
  }

  // ── Durum: sonuc ──────────────────────────────────────────────────────────
  Widget _buildSonuc() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              _falMetni,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.85,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: _buildGradientButton(
            label: _t('Kapat', 'Close'),
            onTap: () => context.pop(),
          ),
        ),
      ],
    );
  }

  // ── Gradient buton (ortak) ────────────────────────────────────────────────
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
            colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)],
          ),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.80),
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
            colors: [Color(0xFF1A0640), Color(0xFF2A0860)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.40),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF55FF), size: 22),
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
