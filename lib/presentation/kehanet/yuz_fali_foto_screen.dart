// lib/presentation/kehanet/yuz_fali_foto_screen.dart
// Yüz Falı — fotoğraf çekme/seçme, analiz ve fal metni ekranı.

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/occult_button.dart';
import '../../core/utils/rich_text_parser.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';
import '../../data/services/claude_vision_service.dart';
import 'package:uuid/uuid.dart';

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
      final prefs    = await SharedPreferences.getInstance();
      final today    = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      await prefs.setString('yuzfali_bugun_tarih', todayStr);
      _scanCtrl.repeat(reverse: true);
      await _analizEt();
      _scanCtrl.stop();
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

      // Günlük hakkı işaretle
      final prefs    = await SharedPreferences.getInstance();
      final today    = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      await prefs.setString('yuzfali_bugun_tarih', todayStr);

      _scanCtrl.repeat(reverse: true);
      await _analizEt();
      _scanCtrl.stop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hataMetni = 'Fotoğraf alınamadı. Lütfen tekrar dene.';
          _adim      = _YFAdim.hatali;
        });
      }
    }
  }

  // ── Claude Vision API + metin oluşturma ───────────────────────────────────
  Future<void> _analizEt() async {
    try {
      // API çağrısı ve minimum 12 saniyelik bekleme eş zamanlı
      final sonuclar = await Future.wait<dynamic>([
        ClaudeVisionService.analiz(_foto!.path),
        Future.delayed(const Duration(seconds: 12)),
      ]);

      if (!mounted) return;

      final analiz = sonuclar[0] as YuzAnalizi;

      if (!analiz.isHuman) {
        setState(() {
          _hataMetni = 'Lütfen gerçek bir insan fotoğrafı gönder.';
          _adim      = _YFAdim.hatali;
        });
        return;
      }

      // JSON yükle
      final jsonKey = widget.kimin == 'kullanici'
          ? 'assets/data/yuzfali_kullanici.json'
          : 'assets/data/yuzfali_baskasi.json';
      final jsonStr = await rootBundle.loadString(jsonKey);
      final data    = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Cinsiyet → tam fal seçimi
      final profile  = ref.read(userProfileProvider);
      final cinsiyet = widget.kimin == 'kullanici'
          ? profile.gender        // kullanıcının kendi profil cinsiyeti
          : analiz.cinsiyet;      // fotoğraftaki kişinin Claude'dan gelen cinsiyeti
      final tamKey = cinsiyet == 'erkek' ? 'yuzfalitame' : 'yuzfalitamkl';

      // Fal parçalarını sıraya diz
      final parcalar = <String>[];

      String sec(List<dynamic>? liste) {
        if (liste == null || liste.isEmpty) return '';
        final item = liste[_rng.nextInt(liste.length)] as Map<String, dynamic>;
        return (item['metin'] as String? ?? '').trim();
      }

      String kategori(String cat, String variant) {
        final m = data[cat] as Map<String, dynamic>?;
        if (m == null) return '';
        return sec(m[variant] as List<dynamic>?);
      }

      // 1. Tam fal
      final t = sec(data[tamKey] as List<dynamic>?);
      if (t.isNotEmpty) parcalar.add(t);

      // 2–8. Özellik metinleri (kullanıcı sırası)
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

      // {{isim}} değiştirme
      final varMap = profile.toVariableMap();
      _falMetni = parcalar
          .map((p) => VariableReplacer.replace(p, varMap))
          .join('\n\n');

      // Inbox'a kaydet — 6 dakika sonra açılır
      if (!mounted) return;
      final now      = DateTime.now();
      final unlockAt = now.add(const Duration(minutes: 6)).toIso8601String();
      final inboxItem = InboxItem(
        id:             const Uuid().v4(),
        title:          'Yüz Falın Hazır',
        text:           _falMetni,
        date:           now.toIso8601String(),
        fortuneTypeKey: 'yuzfali',
        iconAsset:      'assets/images/inbox_icons/elfali.png',
        unlockAt:       unlockAt,
      );
      await ref.read(inboxProvider.notifier).addItem(inboxItem);

      // Ana menüye dön, balon göster
      if (!mounted) return;
      ref.read(yuzFaliSentProvider.notifier).state = true;
      context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _hataMetni =
              'Analiz sırasında bir hata oluştu. İnternet bağlantını kontrol et.';
          _adim = _YFAdim.hatali;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: GrimoireBackdrop(child: SafeArea(
        child: Column(
          children: [
            // ── Başlık ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.bone),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    widget.kimin == 'kullanici' ? ref.watch(l10nProvider).faceFortuneTilte : ref.watch(l10nProvider).faceFortuneTilte,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle,
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
          ],
        ),
      )),
    );
  }

  // ── Fotoğraf alanı (ortak widget) ─────────────────────────────────────────
  Widget _buildFotoAlan({double? height}) {
    return Container(
      width: double.infinity,
      height: height,

      child: GlassPanel(child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: _foto != null
            ? SizedBox.expand(child: Image.file(_foto!, fit: BoxFit.cover))
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.face_retouching_natural,
                        color: AppColors.bone.withValues(alpha: 0.2), size: 72),
                    const SizedBox(height: 14),
                    Text(
                      'Fotoğraf seç veya çek',
                      style: TextStyle(
                        color: AppColors.bone.withValues(alpha: 0.3),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ));
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
                  label: 'Fotoğraf Çek',
                  onTap: () => _secimlYap(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FotoButon(
                  icon: Icons.photo_library_rounded,
                  label: 'Telefondan Seç',
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
                  color: AppColors.ash.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.ash.withValues(alpha: 0.40)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.science_outlined, color: AppColors.gold, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'TEST — Örnek Yüz Görseli',
                      style: TextStyle(color: AppColors.ash, fontSize: 12, fontWeight: FontWeight.w600),
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
                                        AppColors.gold.withValues(alpha: 0.10),
                                        AppColors.gold.withValues(alpha: 0.75),
                                        AppColors.bone.withValues(alpha: 0.90),
                                        AppColors.gold.withValues(alpha: 0.75),
                                        AppColors.gold.withValues(alpha: 0.10),
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
                                        color: Colors.black.withValues(alpha: 0.12),
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
        const Text(
          'Analiz ediliyor...',
          style: TextStyle(
            color: AppColors.bone,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),

        // Animasyonlu kum saati
        const ElegantHourglass(size: 56, color: AppColors.gold),
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
          const Icon(Icons.warning_amber_outlined, color: AppColors.gold, size: 56),
          const SizedBox(height: 24),
          Text(
            _hataMetni,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.bone,
              fontSize: 17,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          _buildGradientButton(
            label: 'Tekrar Dene',
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
            child: GlassPanel(variant: GlassVariant.reading, padding: const EdgeInsets.all(18), child: RichTextParser.build(_falMetni, style: AppTextStyles.reading)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: _buildGradientButton(
            label: 'Kapat',
            onTap: () => context.pop(),
          ),
        ),
      ],
    );
  }

  // ── Gradient buton (ortak) ────────────────────────────────────────────────
  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return OccultButton(label: label, onTap: onTap);
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
    return OccultButton.secondary(label: label, icon: icon, onTap: onTap);
  }
}
