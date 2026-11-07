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
import '../../core/widgets/burning_paper.dart';
import '../../core/widgets/focus_ripple.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../core/widgets/swipe_back.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';
import '../../core/constants/app_text_styles.dart';

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

  // Kül kağıttaki altın-sarısı yazı stili (GoldenScriptText yedek + maske metriği).
  static const _goldStyle = TextStyle(
    color: Color(0xFFEBC973), // altın sarısı
    fontSize: 17.5,
    height: 1.78,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    shadows: [
      Shadow(color: Color(0xDDFFC24D), blurRadius: 11), // iç sıcak hale
      Shadow(color: Color(0x88FF8A1E), blurRadius: 26), // çatlaktan sızan ışık
    ],
  );

  // ── Durum ───────────────────────────────────────────────────────────────────
  _Adim   _adim        = _Adim.yukleniyor;
  String  _metin       = '';
  bool    _veriYuklendi = false;
  bool    _yandi        = false; // kağıt küle döndü mü → altın yazı belirsin
  final double _seed    = (Random().nextDouble() * 50) + 1; // her açılışta farklı çatlak/alev

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
      if (_profilDegeri('${m['degisken'] ?? ''}', profile)
          != '${m['deger'] ?? ''}') {
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
    // Kısa nabız gözü, sonra yanan kağıt sahnesi (kağıt yanar → altın yazı belirir).
    _gecisTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _adim = _Adim.icerik);
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SwipeBack(
      onSwipeBack: () => context.pop(),
      child: Scaffold(
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
              style: AppTextStyles.screenTitle,
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
                const FocusRipple(color: Color(0xFFCC44FF)),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    ref.watch(l10nProvider).bitterTruthsPreparing,
                    style: const TextStyle(
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
        const FloatingBarSpacer(),
      ],
    );
  }

  // ── İçerik ekranı ─────────────────────────────────────────────────────────────

  Widget _buildIcerik() {
    // Reduced-motion: yazı anında (son kare) belirsin.
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final revealDur = Duration(milliseconds: reduced ? 0 : 1100);
    return Column(
      children: [
        _buildBaslikBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Papirüs sağ alt köşeden tutuşur → alev/köz/duman sarar → kara kağıt.
                  BurningPaper(
                    seed: _seed,
                    onBurnComplete: () {
                      if (!mounted) return;
                      HapticFeedback.lightImpact();
                      setState(() => _yandi = true);
                    },
                  ),
                  // Kara kağıtta altın-sarısı yazı belirir; ışık harflerin İÇİNDEN geçer.
                  IgnorePointer(
                    ignoring: !_yandi,
                    child: AnimatedSlide(
                      offset: _yandi ? Offset.zero : const Offset(0, 0.035),
                      duration: revealDur,
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _yandi ? 1 : 0,
                        duration: revealDur,
                        curve: Curves.easeOutCubic,
                        child: GoldenScriptText(
                          text: _metin,
                          style: _goldStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const FloatingBarSpacer(),
      ],
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
                  Text(
                    ref.watch(l10nProvider).bitterTruthsLimitTitle,
                    style: AppTextStyles.screenTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ref.watch(l10nProvider).bitterTruthsLimitSub,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const FloatingBarSpacer(),
      ],
    );
  }
}

// (Typewriter widget kaldırıldı — Acı Gerçekler artık yanan kağıt + altın yazı ile açılır.)
