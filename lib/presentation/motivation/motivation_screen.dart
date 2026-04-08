import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// ── Motivasyon Metinleri ──────────────────────────────────────────────────────
// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Motivasyon\Motivasyonlar\
// Her .asset dosyasındaki Türkçe "aciklama" alanından derlendi.
// gerekliDegiskenler: sadece "mod: motivasyon" içeriyor → kosullar: [] (herkese açık)
// Günlük limit: 1. Tüm metinler gösterilince liste sıfırlanır.

class _MotivasyonEntry {
  final int id;
  final String metin;
  const _MotivasyonEntry({required this.id, required this.metin});
}

class MotivationScreen extends ConsumerStatefulWidget {
  const MotivationScreen({super.key});

  @override
  ConsumerState<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends ConsumerState<MotivationScreen>
    with SingleTickerProviderStateMixin {
  static const _prefKeyGosterilen = 'motivasyon_gosterilen_idler';
  static const _prefKeyBugunTarih = 'motivasyon_bugun_tarih';
  static const _prefKeyBugunId    = 'motivasyon_bugun_id';

  final _rng = Random();

  _MotivasyonEntry? _bugunEntry;
  bool _loading = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final bugunStr = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

    // JSON yükle
    final jsonStr = await rootBundle.loadString('assets/data/motivasyonlar.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tumListe = (data['motivasyonlar'] as List<dynamic>)
        .map((e) => _MotivasyonEntry(
              id: (e as Map<String, dynamic>)['id'] as int,
              metin: e['metin'] as String,
            ))
        .toList();

    // Gösterilen ID'leri yükle
    List<String> gosterilenIdler = prefs.getStringList(_prefKeyGosterilen) ?? [];

    // Gösterilmeyenleri filtrele
    var kalan = tumListe.where((m) => !gosterilenIdler.contains('${m.id}')).toList();

    // Hepsi gösterildiyse sıfırla
    if (kalan.isEmpty) {
      gosterilenIdler = [];
      await prefs.setStringList(_prefKeyGosterilen, []);
      kalan = List.from(tumListe);
    }

    // Karıştır ve ilkini seç
    kalan.shuffle(_rng);
    final secilen = kalan.first;

    // Kaydet
    gosterilenIdler.add('${secilen.id}');
    await prefs.setStringList(_prefKeyGosterilen, gosterilenIdler);
    await prefs.setString(_prefKeyBugunTarih, bugunStr);
    await prefs.setInt(_prefKeyBugunId, secilen.id);

    if (!mounted) return;
    setState(() {
      _bugunEntry = secilen;
      _loading = false;
    });
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: const Text('Motivasyon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: _buildContent(profile),
            ),
    );
  }

  Widget _buildContent(profile) {
    final entry = _bugunEntry;
    if (entry == null) return const SizedBox.shrink();

    final vars = profile.toVariableMap();
    final text = VariableReplacer.replace(entry.metin, vars);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF140D46), Color(0xFF0D0A20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.bubble3.first.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.bubble3.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💫', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardText.copyWith(
                fontSize: text.length > 300 ? 13 : (text.length > 150 ? 15 : 17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
