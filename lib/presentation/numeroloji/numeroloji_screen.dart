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
import '../../core/widgets/floating_bar_spacer.dart';
import '../../core/widgets/stagger_in.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../core/widgets/swipe_back.dart';
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
  // ChatGPT'ye üretilen mistik numeroloji ikonları (yoksa Material ikon yedeği).
  String get iconAsset => [
    'assets/images/numeroloji_konu/ngenel.png',
    'assets/images/numeroloji_konu/nbugun.png',
    'assets/images/numeroloji_konu/nyil.png',
  ][index];
}

// ─── Ekran ───────────────────────────────────────────────────────────────────

class NumerologiScreen extends ConsumerStatefulWidget {
  const NumerologiScreen({super.key});

  @override
  ConsumerState<NumerologiScreen> createState() => _NumerologiScreenState();
}

class _NumerologiScreenState extends ConsumerState<NumerologiScreen> {

  // ── JSON ──────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _json;

  // ── Durum: seçim/yükleme/sonuç ──────────────────────────────────────────
  _RaporTur? _secilen;
  String?    _cachedMetin;  // sadece cache'ten gösteriliyorsa dolu
  bool       _loading = false;
  // Bekleme anında gösterilen hesaplanmış sayılar (2026-11-06: hesaplanıp hiç
  // gösterilmiyordu). (etiket, sayı)
  List<(String, int)> _sayilar = const [];
  DateTime _sayiAni = DateTime.now();

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

  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _init();
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
    final isEn     = ref.read(localeProvider) == 'en';
    final dataKey  = isEn && _json!.containsKey('${tur.jsonKey}_en')
        ? '${tur.jsonKey}_en'
        : tur.jsonKey;
    final turData  = _json![dataKey] as Map<String, dynamic>;

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

    // Yeni rapor: loading göster (hesaplanan sayılarla)
    final profile = ref.read(userProfileProvider);
    final isEn = ref.read(localeProvider) == 'en';
    final List<(String, int)> sayilar;
    if (tur == _RaporTur.bugun) {
      sayilar = [(isEn ? 'Day Number' : 'Günün Sayısı', NumerologiHesap.bugunSayisi(profile))];
    } else if (tur == _RaporTur.yil) {
      sayilar = [(isEn ? 'Year Number' : 'Yılın Sayısı', NumerologiHesap.yilSayisi(profile))];
    } else {
      final n = NumerologiHesap.hesapla(profile);
      sayilar = [
        (isEn ? 'Life Path' : 'Yaşam Yolu', n.yasamYolu),
        (isEn ? 'Expression' : 'İfade', n.ifade),
        (isEn ? 'Soul' : 'Ruh', n.ruh),
      ];
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _secilen = tur;
      _loading = true;
      _cachedMetin = null;
      _sayilar = sayilar;
      _sayiAni = DateTime.now();
    });

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

    return PopScope(
      // Sonuç görünürken Android geri tuşu seçime döner; seçimde ekrandan çıkar.
      canPop: !(_secilen != null && _cachedMetin != null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() { _secilen = null; _cachedMetin = null; });
      },
      child: SwipeBack(
      onSwipeBack: () {
        if (_secilen != null && _cachedMetin != null) {
          setState(() { _secilen = null; _cachedMetin = null; });
        } else if (!_loading) {
          context.pop();
        }
      },
      child: Scaffold(
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
                          ref.watch(l10nProvider).numerologyTitle,
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
              Expanded(child: _buildBody()),
            ],
          ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildBody() {
    if (_json == null) {
      return const Center(child: CircularProgressIndicator(
        color: Color(0xFF9977FF), strokeWidth: 2));
    }
    if (_loading) return _buildLoading();
    if (_cachedMetin != null) return _buildSonuc();
    return _buildSecim();
  }

  // ─── Kum saati yükleme ekranı ─────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hesaplanan sayılar sırayla, büyük ve parlayan rakamlarla belirir.
          if (_sayilar.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _sayilar.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: StaggerIn(
                      index: i,
                      since: _sayiAni,
                      step: const Duration(milliseconds: 380),
                      child: _SayiKarti(etiket: _sayilar[i].$1, sayi: _sayilar[i].$2),
                    ),
                  ),
              ],
            )
          else
            const SpinningHourglass(size: 64, color: Color(0xFFBBAAFF)),
          const SizedBox(height: 24),
          Text(
            ref.watch(l10nProvider).numCalculating,
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

  Widget _buildSecim() {
    // Kartlar dikey; ikon üstte, yazı altta (Anıl). Sığdığında ortalı, sığmazsa kaydırılır.
    return LayoutBuilder(builder: (context, box) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  ref.watch(l10nProvider).numReportPrompt,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 15, color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1, height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (final tur in _RaporTur.values)
                      _buildTurKart(tur),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const FloatingBarSpacer(),
            ],
          ),
        ),
      );
    });
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
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
          // İkon ÜSTTE, yazı ALTTA (ortalı) — Anıl, 2026-11-06.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF6644FF).withValues(alpha: disabled ? 0.10 : 0.20),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF9977FF).withValues(alpha: 0.40)),
                ),
                alignment: Alignment.center,
                child: _turIcon(tur, disabled),
              ),
              const SizedBox(height: 12),
              Text(
                ref.watch(l10nProvider).numLabel(tur.index),
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: disabled ? Colors.white38 : Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                locked
                  ? ref.watch(l10nProvider).numPreparing
                  : hasCached
                    ? ref.watch(l10nProvider).numReadAgain
                    : ref.watch(l10nProvider).numDesc(tur.index),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
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
      ),
    );
  }

  /// Kart ikonu: ChatGPT'ye üretilen mistik PNG varsa onu, yoksa Material ikon yedeğini
  /// gösterir (ikonlar eklenince pubspec'te `assets/images/numeroloji_konu/` tanımlanır).
  Widget _turIcon(_RaporTur tur, bool disabled) {
    return Image.asset(
      tur.iconAsset,
      width: 46, height: 46,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        tur.icon,
        color: disabled
            ? const Color(0xFF9977FF).withValues(alpha: 0.40)
            : const Color(0xFFBBAAFF),
        size: 30,
      ),
    );
  }

  // ─── Sonuç (cache'ten) ekranı ─────────────────────────────────────────────

  Widget _buildSonuc() {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, floatingBarInset(context)),
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
              ref.watch(l10nProvider).numLabel(_secilen!.index),
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
      ],
    );
  }
}

/// Hesaplanan numeroloji sayısı: büyük, altın parıltılı rakam + etiket.
class _SayiKarti extends StatelessWidget {
  const _SayiKarti({required this.etiket, required this.sayi});
  final String etiket;
  final int sayi;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 78,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0x66BBAAFF), Color(0x00BBAAFF)],
            ),
            border: Border.all(color: const Color(0xAABBAAFF), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x55BBAAFF), blurRadius: 22, spreadRadius: 1),
            ],
          ),
          child: Text(
            '$sayi',
            style: GoogleFonts.cinzel(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFF0B0),
              shadows: const [Shadow(color: Color(0xCCD4AF37), blurRadius: 14)],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          etiket,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
