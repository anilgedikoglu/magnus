// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\KaderKitabı\Tefeul
// JSON:   assets/data/kaderkitabi.json
// Arka plan: assets/images/ozlusoz_bg.png
//
// Metin motoru kuralları:
//   • Koşullu filtreleme (cinsiyet, medeni_durum, meslek, iliski_durumu, yasmin/yasmax)
//   • No-repeat + üst üste aynı metin yasağı
//   • Günlük 1 hak: aynı gün aynı metin; 2. ziyarette son metin tekrar gösterilir
//   • VariableReplacer ile render

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';
import '../../data/models/user_profile.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class _KitapEntry {
  final int id;
  final String metin;
  final List<Map<String, String>> kosullar;
  const _KitapEntry({required this.id, required this.metin, required this.kosullar});
}

// ─── Ana ekran ───────────────────────────────────────────────────────────────

class KaderKitabiScreen extends ConsumerStatefulWidget {
  const KaderKitabiScreen({super.key});

  @override
  ConsumerState<KaderKitabiScreen> createState() => _KaderKitabiScreenState();
}

class _KaderKitabiScreenState extends ConsumerState<KaderKitabiScreen> {

  static const _prefKeyGosterilen = 'kaderkitabi_gosterilen';
  static const _prefKeyBugunTarih = 'kaderkitabi_bugun_tarih';
  static const _prefKeyBugunId    = 'kaderkitabi_bugun_id';
  static const _prefKeySonMetin   = 'kaderkitabi_son_metin';

  String? _metin;
  bool    _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── Koşul eşleştirme ────────────────────────────────────────────────────

  bool _tumKosullarUygun(List<Map<String, String>> kosullar, UserProfile profile) {
    int? yasMin, yasMax;
    for (final k in kosullar) {
      if (k['degisken'] == 'yasmin') yasMin = int.tryParse(k['deger'] ?? '');
      if (k['degisken'] == 'yasmax') yasMax = int.tryParse(k['deger'] ?? '');
    }
    if (yasMin != null && profile.age < yasMin) return false;
    if (yasMax != null && profile.age > yasMax) return false;

    for (final k in kosullar) {
      final deg = k['degisken'] ?? '';
      if (deg == 'yasmin' || deg == 'yasmax') continue;
      final bek = k['deger'] ?? '';
      final grc = _profileDegeri(deg, profile);
      if (grc != bek) return false;
    }
    return true;
  }

  String _profileDegeri(String deg, UserProfile profile) {
    switch (deg) {
      case 'cinsiyet':      return profile.gender;
      case 'medeni_durum':  return profile.maritalStatus;
      case 'meslek':        return profile.job;
      case 'iliski_durumu':
        const varOlanlar = {'iliski_var','evli','nisanli','karisik','flort','ayri_yasiyor'};
        return varOlanlar.contains(profile.maritalStatus) ? 'var' : 'yok';
      default: return '';
    }
  }

  // ─── Veri yükle ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs    = await SharedPreferences.getInstance();
    final bugunStr = DateTime.now().toIso8601String().substring(0, 10);
    final profile  = ref.read(userProfileProvider);

    // Aynı gün ve daha önce içerik gösterildiyse tekrar göster
    final sonMetin = prefs.getString(_prefKeySonMetin) ?? '';
    if ((prefs.getString(_prefKeyBugunTarih) ?? '') == bugunStr && sonMetin.isNotEmpty) {
      if (!mounted) return;
      setState(() { _metin = sonMetin; _loading = false; });
      return;
    }

    final raw      = await rootBundle.loadString('assets/data/kaderkitabi.json');
    final data     = jsonDecode(raw) as Map<String, dynamic>;
    final tumListe = (data['kaderkitabi'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return _KitapEntry(
        id: m['id'] as int,
        metin: m['metin'] as String,
        kosullar: (m['kosullar'] as List)
            .map((k) => Map<String, String>.from(k as Map))
            .toList(),
      );
    }).toList();

    final uygunListe = tumListe
        .where((e) => _tumKosullarUygun(e.kosullar, profile))
        .toList();

    // No-repeat seçim
    List<String> gosterilen = prefs.getStringList(_prefKeyGosterilen) ?? [];
    var kalan = uygunListe.where((e) => !gosterilen.contains('${e.id}')).toList();

    if (kalan.isEmpty) {
      final lastId = gosterilen.isNotEmpty ? gosterilen.last : null;
      gosterilen = lastId != null ? [lastId] : [];
      await prefs.setStringList(_prefKeyGosterilen, gosterilen);
      kalan = uygunListe.where((e) => '${e.id}' != lastId).toList();
      if (kalan.isEmpty) kalan = List.from(uygunListe);
    }

    kalan.shuffle(Random());
    final secilen = kalan.first;
    gosterilen.add('${secilen.id}');
    await prefs.setStringList(_prefKeyGosterilen, gosterilen);
    await prefs.setString(_prefKeyBugunTarih, bugunStr);
    await prefs.setInt(_prefKeyBugunId, secilen.id);

    final rendered = VariableReplacer.replace(secilen.metin, profile.toVariableMap());
    await prefs.setString(_prefKeySonMetin, rendered);

    if (!mounted) return;
    setState(() { _metin = rendered; _loading = false; });
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/ozlusoz_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D0A1A)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xAA000000), Color(0x55000000), Color(0xAA000000)],
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(
                        color: Color(0xFFD4AF37), strokeWidth: 2))
                    : _buildContent(context),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Başlık ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFD4AF37), size: 18),
          ),
        ),
        Expanded(
          child: Center(
            child: Text('KADER KİTABI',
              style: GoogleFonts.cinzel(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: const Color(0xFFD4AF37), letterSpacing: 4,
                shadows: const [Shadow(color: Color(0xAAD4AF37), blurRadius: 16)],
              )),
          ),
        ),
        const SizedBox(width: 38),
      ]),
    );
  }

  // ─── Metin içeriği ────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final metin = _metin ?? '';
    return Column(children: [
      // Kitap kutusu — dikey orta
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF5ECD7), Color(0xFFEDD9A3)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                    blurRadius: 30, spreadRadius: 4, offset: const Offset(0, 6)),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20, offset: const Offset(0, 10)),
                ],
                border: Border.all(
                  color: const Color(0xFFB8960C).withValues(alpha: 0.6), width: 1.5),
              ),
              child: Stack(children: [
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(
                    width: 18,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 28, 26, 36),
                  child: Text(metin,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      color: Color(0xFF2C1A0A), fontSize: 15,
                      height: 1.85, fontWeight: FontWeight.w400, letterSpacing: 0.2,
                    )),
                ),
                Positioned(
                  bottom: 10, left: 0, right: 0,
                  child: Center(
                    child: Text('✦',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8B6914).withValues(alpha: 0.7))),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      // Kapat butonu — ekranın altında sabit
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8960C), Color(0xFF8B6914)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 1.5),
            ),
            child: const Center(
              child: Text('Kapat',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
          ),
        ),
      ),
    ]);
  }
}
