// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Numeroloji\Rapor
// JSON:   assets/data/numeroloji.json
//
// Erişim mantığı (home'dan badge/limit yok, kontrol ekran içinden):
//   Genel   → ömür boyu 1 kez oluşturulur, tekrar açılınca cache'ten gösterilir
//   Yıl     → yıl başında yenilenır; aynı yıl içinde cache'ten gösterilir
//   Bugüne  → günde 1 kez; o gün alındıysa buton pasif
//
// Yeni rapor akışı: animasyonlu kum saati + "Lütfen bekle..." 3 sn →
//   context.pop('hazirlanıyor') → home'da "Numeroloji raporun hazırlanıyor..." balonu
//   + gelen kutusuna 3 dk kilitli InboxItem eklenir
//
// Cache'ten gösterme akışı: doğrudan ekranda açılır, inbox/bekleme yok.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/numeroloji_hesap.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';

// ─── Rapor türü ───────────────────────────────────────────────────────────────

enum _RaporTur { genel, bugun, yil }

extension _RaporTurExt on _RaporTur {
  String get jsonKey => ['genel', 'bugun', 'yil'][index];
  String get label   => ['Genel Rapor', 'Bugüne Dair', 'Bu Yıla Dair'][index];
  String get desc    => [
    'Kalıcı sayılarınla oluşturulan kişilik raporu',
    'Bugünün enerjisini şekillendiren sayılar',
    'Bu yıl seni bekleyen döngüler ve fırsatlar',
  ][index];
  IconData get icon  => [
    Icons.auto_awesome,
    Icons.wb_sunny_outlined,
    Icons.calendar_today_outlined,
  ][index];
}

// ─── Ekran ───────────────────────────────────────────────────────────────────

class NumerologiScreen extends ConsumerStatefulWidget {
  const NumerologiScreen({super.key});

  @override
  ConsumerState<NumerologiScreen> createState() => _NumerologiScreenState();
}

class _NumerologiScreenState extends ConsumerState<NumerologiScreen>
    with SingleTickerProviderStateMixin {

  // ── JSON ──────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _json;

  // ── Durum: seçim/yükleme/sonuç ──────────────────────────────────────────
  _RaporTur? _secilen;
  String?    _cachedMetin;  // sadece cache'ten gösteriliyorsa dolu
  bool       _loading = false;

  // ── Cache/kullanım durumu ────────────────────────────────────────────────
  bool _genelDone    = false;
  bool _yilDone      = false;
  bool _bugunDone    = false;

  // Inbox'ta hâlâ kilitliyse true → buton pasif, "Hazırlanıyor..." gösterilir
  bool _genelLocked  = false;
  bool _yilLocked    = false;
  bool _bugunLocked  = false;

  String? _genelMetin;
  String? _yilMetin;
  String? _bugunMetin;

  // ── Kum saati animasyonu ─────────────────────────────────────────────────
  late AnimationController _hgCtrl;
  late Animation<double> _flipAnim;
  late Animation<double> _scaleAnim;

  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _hgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 0→0.35 flip 0→π, 0.35→0.55 duraklama, 0.55→0.90 flip π→2π, 0.90→1.0 duraklama
    _flipAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: pi).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween(pi), weight: 20),
      TweenSequenceItem(
        tween: Tween(begin: pi, end: 2 * pi).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween(2 * pi), weight: 10),
    ]).animate(_hgCtrl);

    // Hafif nabız efekti
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
    ]).animate(_hgCtrl);

    _init();
  }

  @override
  void dispose() {
    _hgCtrl.dispose();
    super.dispose();
  }

  // ─── Başlangıç yükleme ────────────────────────────────────────────────────

  Future<void> _init() async {
    final raw = await rootBundle.loadString('assets/data/numeroloji.json');
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final year  = DateTime.now().year.toString();

    _genelDone  = prefs.getBool('num_genel_done') ?? false;
    _genelMetin = prefs.getString('num_genel_metin');
    _yilDone    = (prefs.getString('num_yil_done') ?? '') == year;
    _yilMetin   = prefs.getString('num_yil_metin_$year');
    _bugunDone  = (prefs.getString('num_bugun_tarih') ?? '') == today;
    _bugunMetin = _bugunDone ? prefs.getString('num_bugun_metin') : null;

    // Inbox'ta hâlâ kilitli mi? unlock zamanı geçmediyse pasif tut
    _genelLocked = _isStillLocked(prefs.getString('num_genel_unlock'));
    _yilLocked   = _isStillLocked(prefs.getString('num_yil_unlock_$year'));
    _bugunLocked = _isStillLocked(prefs.getString('num_bugun_unlock'));

    if (!mounted) return;
    setState(() => _json = jsonDecode(raw) as Map<String, dynamic>);
  }

  String _todayStr() => DateTime.now().toIso8601String().substring(0, 10);

  bool _isStillLocked(String? unlockIso) {
    if (unlockIso == null) return false;
    try { return DateTime.now().isBefore(DateTime.parse(unlockIso)); }
    catch (_) { return false; }
  }

  // ─── Metin üret (JSON'dan) ────────────────────────────────────────────────

  String _buildMetin(_RaporTur tur) {
    final profile  = ref.read(userProfileProvider);
    final turData  = _json![tur.jsonKey] as Map<String, dynamic>;

    List<(String, int)> bolumler;

    if (tur == _RaporTur.bugun) {
      // Günlük kişisel sayı — tüm bölümler için aynı
      final s = NumerologiHesap.bugunSayisi(profile);
      bolumler = [
        ('ifadesayisi', s), ('ruhsayisi', s), ('yasamyolusayisi', s),
        ('sessizbenliksayisi', s), ('olgunluksayisi', s),
        ('dogumgunusayisi', s), ('karmikborc', s),
      ];
    } else if (tur == _RaporTur.yil) {
      // Yıllık kişisel sayı — tüm bölümler için aynı
      final s = NumerologiHesap.yilSayisi(profile);
      bolumler = [
        ('ifadesayisi', s), ('ruhsayisi', s), ('yasamyolusayisi', s),
        ('sessizbenliksayisi', s), ('olgunluksayisi', s),
        ('dogumgunusayisi', s), ('karmikborc', s),
      ];
    } else {
      // Genel: her bölüm kendi kişisel sayısını kullanır
      final n = NumerologiHesap.hesapla(profile);
      bolumler = [
        ('ifadesayisi',        n.ifade),
        ('ruhsayisi',          n.ruh),
        ('yasamyolusayisi',    n.yasamYolu),
        ('sessizbenliksayisi', n.sessizBenlik),
        ('olgunluksayisi',     n.olgunluk),
        ('dogumgunusayisi',    n.dogumGunu),
        ('karmikborc',         n.karmikBorc),
      ];
    }

    final parcalar = <String>[];
    for (final (key, sayi) in bolumler) {
      final bolum = turData[key] as Map<String, dynamic>?;
      if (bolum == null) continue;
      final metin = bolum['$sayi'] as String? ?? bolum['1'] as String? ?? '';
      if (metin.isNotEmpty) parcalar.add(metin);
    }

    final combined = parcalar.join('\n\n');
    final varMap   = ref.read(userProfileProvider).toVariableMap();
    return VariableReplacer.replace(combined, varMap);
  }

  // ─── Seçim işlemi ─────────────────────────────────────────────────────────

  Future<void> _onTur(_RaporTur tur) async {
    if (_json == null) return;

    // Cache'ten göster
    if (tur == _RaporTur.genel && _genelDone && _genelMetin != null) {
      setState(() { _secilen = tur; _cachedMetin = _genelMetin; });
      return;
    }
    if (tur == _RaporTur.yil && _yilDone && _yilMetin != null) {
      setState(() { _secilen = tur; _cachedMetin = _yilMetin; });
      return;
    }
    if (tur == _RaporTur.bugun && _bugunDone && _bugunMetin != null) {
      setState(() { _secilen = tur; _cachedMetin = _bugunMetin; });
      return;
    }

    // Yeni rapor: loading göster
    setState(() { _secilen = tur; _loading = true; _cachedMetin = null; });

    final metin = _buildMetin(tur);
    final prefs = await SharedPreferences.getInstance();
    final year  = DateTime.now().year.toString();

    // Gelen kutusuna ekle (3 dk kilitli)
    final unlockAt  = DateTime.now().add(const Duration(minutes: 3));
    final unlockIso = unlockAt.toIso8601String();

    // Cache'e kaydet + unlock zamanını sakla
    if (tur == _RaporTur.genel) {
      await prefs.setBool('num_genel_done', true);
      await prefs.setString('num_genel_metin', metin);
      await prefs.setString('num_genel_unlock', unlockIso);
    } else if (tur == _RaporTur.yil) {
      await prefs.setString('num_yil_done', year);
      await prefs.setString('num_yil_metin_$year', metin);
      await prefs.setString('num_yil_unlock_$year', unlockIso);
    } else {
      await prefs.setString('num_bugun_tarih', _todayStr());
      await prefs.setString('num_bugun_metin', metin);
      await prefs.setString('num_bugun_unlock', unlockIso);
    }
    await ref.read(inboxProvider.notifier).addItem(InboxItem(
      id:             _uuid.v4(),
      title:          'Numeroloji — ${tur.label}',
      text:           metin,
      date:           DateTime.now().toIso8601String(),
      fortuneTypeKey: 'numeroloji',
      unlockAt:       unlockAt.toIso8601String(),
    ));

    // 3 saniye bekle, sonra geri dön
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    context.pop('hazirlanıyor');
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/numeroloji_bg.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050020)),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x88000000), Color(0xCC000000)],
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12, topPad + 10, 12, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_secilen != null && _cachedMetin != null) {
                          setState(() { _secilen = null; _cachedMetin = null; });
                        } else if (!_loading) {
                          context.pop();
                        }
                      },
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25), width: 1),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'NUMEROLOJİ',
                          style: GoogleFonts.cinzel(
                            fontSize: 18, fontWeight: FontWeight.bold,
                            color: Colors.white, letterSpacing: 4,
                            shadows: const [Shadow(color: Color(0xAA6655FF), blurRadius: 14)],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(bottomPad)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double bottomPad) {
    if (_json == null) {
      return const Center(child: CircularProgressIndicator(
        color: Color(0xFF9977FF), strokeWidth: 2));
    }
    if (_loading) return _buildLoading();
    if (_cachedMetin != null) return _buildSonuc(bottomPad);
    return _buildSecim(bottomPad);
  }

  // ─── Kum saati yükleme ekranı ─────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _hgCtrl,
            builder: (_, __) {
              final angle = _flipAnim.value;
              // π'yi geçince alt ikon göster
              final icon = (angle % (2 * pi)) > pi * 0.5 && (angle % (2 * pi)) < pi * 1.5
                  ? Icons.hourglass_bottom_rounded
                  : Icons.hourglass_top_rounded;
              return Transform.scale(
                scale: _scaleAnim.value,
                child: Transform.rotate(
                  angle: angle,
                  child: Icon(icon, color: const Color(0xFFBBAAFF), size: 64),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Hesaplamalar başladı, lütfen bekle...',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.80),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Seçim ekranı ─────────────────────────────────────────────────────────

  Widget _buildSecim(double bottomPad) {
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Numeroloji raporunu hangisi için istersin?',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 15, color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 1, height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final tur in _RaporTur.values)
                _buildTurKart(tur),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 16),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 2),
                  Text(
                    'Geri Git',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTurKart(_RaporTur tur) {
    final locked = switch (tur) {
      _RaporTur.genel  => _genelLocked,
      _RaporTur.yil    => _yilLocked,
      _RaporTur.bugun  => _bugunLocked,
    };
    final disabled = locked;
    final hasCached = !locked &&
        ((tur == _RaporTur.genel && _genelDone) ||
         (tur == _RaporTur.yil   && _yilDone)  ||
         (tur == _RaporTur.bugun && _bugunDone));

    return GestureDetector(
      onTap: disabled ? null : () => _onTur(tur),
      child: Opacity(
        opacity: disabled ? 0.70 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: disabled ? 0.30 : 0.50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF9977FF).withValues(alpha: disabled ? 0.20 : 0.50),
              width: 1.2,
            ),
            boxShadow: disabled ? [] : [
              BoxShadow(
                color: const Color(0xFF6644FF).withValues(alpha: 0.15),
                blurRadius: 18, spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6644FF).withValues(alpha: disabled ? 0.10 : 0.20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9977FF).withValues(alpha: 0.40)),
                ),
                child: Icon(tur.icon,
                  color: disabled
                    ? const Color(0xFF9977FF).withValues(alpha: 0.40)
                    : const Color(0xFFBBAAFF),
                  size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tur.label,
                      style: GoogleFonts.cinzel(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: disabled ? Colors.white38 : Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locked
                        ? 'Hazırlanıyor, biraz bekle...'
                        : hasCached
                          ? 'Raporuna tekrar bak →'
                          : tur.desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: disabled
                          ? Colors.white24
                          : hasCached
                            ? const Color(0xFFBBAAFF)
                            : Colors.white.withValues(alpha: 0.60),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                disabled ? Icons.block_rounded : Icons.chevron_right_rounded,
                color: disabled
                  ? Colors.white24
                  : const Color(0xFF9977FF).withValues(alpha: 0.70),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sonuç (cache'ten) ekranı ─────────────────────────────────────────────

  Widget _buildSonuc(double bottomPad) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 24),
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF6644FF).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9977FF).withValues(alpha: 0.50)),
            ),
            child: Text(
              _secilen!.label,
              style: GoogleFonts.cinzel(
                fontSize: 13, color: const Color(0xFFBBAAFF), letterSpacing: 2),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF9977FF).withValues(alpha: 0.35), width: 1),
          ),
          child: RichTextParser.build(
            _cachedMetin ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.80),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() { _secilen = null; _cachedMetin = null; }),
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
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
