// Kaynak: assets/data/acigercekler.json
// Akış: Kum saati (5sn hazırlık) → Acı gerçek (typewriter animasyonu)
// Günlük limit: günde 1 kez (acigercekler_bugun_tarih)
// Tekrar gösterilmeme: acigercekler_gosterilen (tüm ID'ler görülünce sıfırla)
// Koşul filtrelemesi: kosullar listesi (cinsiyet, medeni_durum, meslek vb.)

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

enum _Adim { yukleniyor, icerik, limit }

class AciGerceklerScreen extends ConsumerStatefulWidget {
  const AciGerceklerScreen({super.key});

  @override
  ConsumerState<AciGerceklerScreen> createState() =>
      _AciGerceklerScreenState();
}

class _AciGerceklerScreenState extends ConsumerState<AciGerceklerScreen>
    with TickerProviderStateMixin {

  // ── Pref anahtarları ────────────────────────────────────────────────────────
  static const _prefGosterilen = 'acigercekler_gosterilen';
  static const _prefBugun      = 'acigercekler_bugun_tarih';

  // ── Durum ───────────────────────────────────────────────────────────────────
  _Adim   _adim        = _Adim.yukleniyor;
  String  _metin       = '';
  bool    _veriYuklendi = false;

  Timer? _gecisTimer;

  String get _bugun => DateTime.now().toIso8601String().substring(0, 10);

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _gecisTimer?.cancel();
    super.dispose();
  }

  // ── Veri yükleme ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Günlük limit kontrolü
    if (prefs.getString(_prefBugun) == _bugun) {
      if (mounted) setState(() { _adim = _Adim.limit; _veriYuklendi = true; });
      return;
    }

    // JSON yükle
    final jsonStr = await rootBundle.loadString('assets/data/acigercekler.json');
    final raw     = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tumListe = (raw['acigercekler'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Koşul filtresi
    final profile = ref.read(userProfileProvider);
    final uygunlar = tumListe.where((e) {
      final kosullar = e['kosullar'] as List<dynamic>? ?? [];
      return _kosullarUygun(kosullar, profile);
    }).toList();

    // Gösterilen ID'leri yükle
    List<String> gosterilenIds = prefs.getStringList(_prefGosterilen) ?? [];

    // Gösterilmeyenleri filtrele
    var kalan = uygunlar
        .where((e) => !gosterilenIds.contains(e['id'] as String))
        .toList();

    // Hepsi bittiyse sıfırla
    if (kalan.isEmpty) {
      final lastId = gosterilenIds.isNotEmpty ? gosterilenIds.last : null;
      gosterilenIds = lastId != null ? [lastId] : [];
      await prefs.setStringList(_prefGosterilen, gosterilenIds);
      kalan = uygunlar
          .where((e) => e['id'] != lastId)
          .toList();
      if (kalan.isEmpty) kalan = List.from(uygunlar);
    }

    // Karıştır ve seç
    kalan.shuffle(Random());
    final secilen = kalan.first;

    // {{isim}} vb. değiştir (dile göre metin_en / metin)
    final isEn = ref.read(localeProvider) == 'en';
    final secilenMetin = (isEn && (secilen['metin_en'] as String?)?.isNotEmpty == true)
        ? secilen['metin_en'] as String
        : secilen['metin'] as String;
    final metin = VariableReplacer.replace(
      secilenMetin,
      profile.toVariableMap(),
    );

    // Kaydet
    gosterilenIds.add(secilen['id'] as String);
    await prefs.setStringList(_prefGosterilen, gosterilenIds);
    await prefs.setString(_prefBugun, _bugun);

    if (!mounted) return;
    setState(() {
      _metin       = metin;
      _veriYuklendi = true;
    });

    // Kum saati animasyonunu başlat
    _baslatKumSaati();
  }

  // ── Koşul filtresi ───────────────────────────────────────────────────────────

  bool _kosullarUygun(List<dynamic> kosullar, UserProfile profile) {
    if (kosullar.isEmpty) return true;
    for (final k in kosullar) {
      final m = k as Map;
      if (_profilDegeri(m['degisken'] as String? ?? '', profile)
          != (m['deger'] as String? ?? '')) {
        return false;
      }
    }
    return true;
  }

  String _profilDegeri(String deg, UserProfile p) {
    switch (deg) {
      case 'cinsiyet':     return p.gender;
      case 'medeni_durum': return p.maritalStatus;
      case 'meslek':       return p.job;
      default:             return '';
    }
  }

  // ── Kum saati ────────────────────────────────────────────────────────────────

  void _baslatKumSaati() {
    // Kum saatini 1.2sn aralıkla döndür
    // 5 saniye sonra içerik ekranına geç
    _gecisTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _adim = _Adim.icerik);
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: !_veriYuklendi
            ? const Center(child: CircularProgressIndicator(
                color: Color(0xFFAA88FF), strokeWidth: 2))
            : switch (_adim) {
                _Adim.yukleniyor => _buildYukleniyor(),
                _Adim.icerik     => _buildIcerik(),
                _Adim.limit      => _buildLimit(),
              },
      ),
    );
  }

  // ── Üst bar ───────────────────────────────────────────────────────────────────

  Widget _buildBaslikBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              ref.watch(l10nProvider).bitterTruthsTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Sağ tarafta geri buton ile dengeli boşluk
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Yükleniyor (kum saati) ────────────────────────────────────────────────────

  Widget _buildYukleniyor() {
    return Column(
      children: [
        _buildBaslikBar(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ElegantHourglass(size: 72, color: Color(0xFFCC44FF)),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Sana acı ama gerçek bir şeyler anlatmaya hazırlanıyorum...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── İçerik ekranı ─────────────────────────────────────────────────────────────

  Widget _buildIcerik() {
    return Column(
      children: [
        _buildBaslikBar(),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dekoratif alev ikonu
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 16),
                  // Typewriter metin
                  _TypewriterText(
                    text: _metin,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.65,
                    ),
                    textAlign: TextAlign.center,
                    msPerChar: 30,
                  ),
                  const SizedBox(height: 24),
                  // İnce ayırıcı
                  Container(
                    height: 1,
                    width: 60,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Kapat butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: _buildKapatButonu(),
        ),
      ],
    );
  }

  Widget _buildKapatButonu() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFAA00CC), Color(0xFF7700AA)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Text(
            'Kapat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── Limit ekranı ──────────────────────────────────────────────────────────────

  Widget _buildLimit() {
    return Column(
      children: [
        _buildBaslikBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 20),
                  const Text(
                    'Bugün gerçeklerle yüzleştin.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Yarın daha fazlası için tekrar gel.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildKapatButonu(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typewriter widget
// ─────────────────────────────────────────────────────────────────────────────

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int msPerChar;

  const _TypewriterText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.msPerChar = 30,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(_TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _timer?.cancel();
      _displayed = '';
      _index = 0;
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    final chars = widget.text.characters.toList();
    _timer = Timer.periodic(
      Duration(milliseconds: widget.msPerChar),
      (t) {
        if (!mounted) { t.cancel(); return; }
        if (_index >= chars.length) {
          t.cancel();
          return;
        }
        setState(() {
          _displayed += chars[_index];
          _index++;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
