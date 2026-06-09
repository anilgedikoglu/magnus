// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Olumlama\
// JSON:   assets/data/olumlamalar.json
// Arka plan: assets/images/olumlamaIntrobg.jpg
//
// ⚠️ METIN MOTORU NOTU: Unity .asset dosyalarında `aciklama:` bir YAML listesidir.
// Tek dosyada birden fazla `- "..."` maddesi olabilir → her biri ayrı JSON girdisi!
// JSON yeniden üretilirken extract_all_aciklama() tipi bir parser kullan.
// Bkz. CLAUDE.md → "Kaynak Yapısı" bölümü.
//
// EKRAN YAPISI:
//   - Tam ekran arka plan (olumlamaIntrobg.jpg) + koyu overlay
//   - Başlık: "OLUMLAMA" (üst orta)
//   - Metin: tam ortalı, sol/sağ geçiş animasyonuyla
//   - Altta: ← (önceki) ve → (sonraki) iki ok butonu
//   - Günlük limit yok; tüm uygun olumlamalar gezinebilir

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ad_service.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

// ─── Veri modeli ──────────────────────────────────────────────────────────────

class _OlumlamaEntry {
  final int id;
  final String metin;
  final List<Map<String, String>> kosullar;
  const _OlumlamaEntry({
    required this.id,
    required this.metin,
    required this.kosullar,
  });
}

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class OlumlamaScreen extends ConsumerStatefulWidget {
  const OlumlamaScreen({super.key});

  @override
  ConsumerState<OlumlamaScreen> createState() => _OlumlamaScreenState();
}

class _OlumlamaScreenState extends ConsumerState<OlumlamaScreen>
    with SingleTickerProviderStateMixin {

  List<_OlumlamaEntry> _entries = [];
  int _index = 0;
  int _direction = 1; // +1 = ileri (sağ), -1 = geri (sol)
  bool _loading = true;
  int _nextCount = 0; // ileri basma sayacı — her 5'te reklam

  // Arka plan görselleri (38 adet, olumlama_bgs/ klasöründe)
  static const List<String> _bgFiles = [
    '1.jpg','2.jpg','3.jpg','4.jpg','5.jpg','6.jpg','8.jpg','9.jpg',
    '10.jpg','11.jpg','12.jpg','13.jpg','14.jpg','15.jpg','16.jpg',
    '17.jpg','18.jpg','19.jpg','20.jpg','21.jpg','23.jpg','24.jpg',
    '25.jpg','26.jpg','27.jpg','28.jpg','29.jpg','31.jpg','32.jpg',
    '33.jpg','34.jpg','35.jpg','36.jpg','37.jpg','38.jpg','39.jpg',
    '40.jpg','41.jpg',
  ];
  // Her entry'nin hangi bg'yi göstereceği (shuffle ile atanır, geri gidince aynı bg)
  List<int> _bgMap = []; // index → _bgFiles index

  // BG geçiş: alt katman daima %100, üst katman yeni görsel (0→1 fade)
  late AnimationController _bgCtrl;
  String? _bgBottom;
  String? _bgTop;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _bgBottom = _bgTop;
          _bgTop    = null;
          _bgCtrl.reset();
        });
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _startBgTransition(String? newBg) {
    if (newBg == null || newBg == _bgBottom) return;
    _bgCtrl.stop();
    setState(() {
      if (_bgTop != null) _bgBottom = _bgTop;
      _bgTop = newBg;
      _bgCtrl.value = 0;
    });
    _bgCtrl.forward();
  }

  // ─── Koşul eşleştirme ─────────────────────────────────────────────────────

  bool _kosullarUygun(List<Map<String, String>> kosullar, UserProfile profile) {
    if (kosullar.isEmpty) return true;
    for (final k in kosullar) {
      final degisken = k['degisken'] ?? '';
      final beklenen = k['deger'] ?? '';
      final gercek   = _profilDegeri(degisken, profile);
      if (gercek != beklenen) return false;
    }
    return true;
  }

  String _profilDegeri(String degisken, UserProfile profile) {
    switch (degisken) {
      case 'cinsiyet':      return profile.gender;
      case 'medeni_durum':  return profile.maritalStatus;
      case 'meslek':        return profile.job;
      case 'iliski_durumu':
        const varOlanlar = {
          'iliski_var', 'evli', 'nisanli', 'flort', 'karisik', 'ayri_yasiyor'
        };
        return varOlanlar.contains(profile.maritalStatus) ? 'var' : 'yok';
      default: return '';
    }
  }

  // ─── Veri yükleme ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final jsonStr = await rootBundle.loadString('assets/data/olumlamalar.json');
    final data    = jsonDecode(jsonStr) as Map<String, dynamic>;

    final tumListe = (data['olumlamalar'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return _OlumlamaEntry(
        id: m['id'] as int,
        metin: m['metin'] as String,
        kosullar: (m['kosullar'] as List<dynamic>)
            .map((k) => Map<String, String>.from(k as Map))
            .toList(),
      );
    }).toList();

    final profile    = ref.read(userProfileProvider);
    final uygunListe = tumListe
        .where((e) => _kosullarUygun(e.kosullar, profile))
        .toList();

    final prefs   = await SharedPreferences.getInstance();
    final rng     = Random();
    final uygunIds = uygunListe.map((e) => e.id).toSet();

    // ── Karıştırılmış sıralamayı yükle ya da oluştur ─────────────────────────
    final savedOrder = prefs.getStringList('olumlama_siralama');
    List<int> orderedIds;
    int cursor;

    final orderValid = savedOrder != null &&
        savedOrder.length == uygunIds.length &&
        savedOrder.map(int.parse).toSet().containsAll(uygunIds);

    if (orderValid) {
      orderedIds = savedOrder.map(int.parse).toList();
      cursor = prefs.getInt('olumlama_cursor') ?? 0;
      if (cursor >= orderedIds.length) {
        // Tüm metinler gösterildi → yeniden karıştır
        orderedIds.shuffle(rng);
        cursor = 0;
        await prefs.setStringList(
            'olumlama_siralama', orderedIds.map((e) => '$e').toList());
      }
    } else {
      // İlk çalıştırma ya da uygun liste değişti → sıfırdan karıştır
      orderedIds = uygunIds.toList()..shuffle(rng);
      cursor = 0;
      await prefs.setStringList(
          'olumlama_siralama', orderedIds.map((e) => '$e').toList());
    }

    // Bir sonraki açılışta farklı metinden başlaması için cursor'ı ilerlet
    await prefs.setInt('olumlama_cursor', cursor + 1);

    // Entry listesini karıştırılmış sıraya göre oluştur
    final idToEntry = {for (final e in uygunListe) e.id: e};
    final orderedEntries = orderedIds
        .map((id) => idToEntry[id])
        .whereType<_OlumlamaEntry>()
        .toList();

    // ── Arka plan haritası: her entry ID'sine sabit bir bg ata ───────────────
    // Kaydedilmişse yükle, yoksa yeni ata
    final bgSaved = prefs.getString('olumlama_bg_json');
    Map<int, int> bgById = {};
    if (bgSaved != null) {
      try {
        final decoded = jsonDecode(bgSaved) as Map<String, dynamic>;
        bgById = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
      } catch (_) {}
    }
    // Eksik ID'lere bg ata
    final bgBase = List<int>.generate(_bgFiles.length, (i) => i)..shuffle(rng);
    int bgCursor = 0;
    bool bgChanged = false;
    for (final id in orderedIds) {
      if (!bgById.containsKey(id)) {
        bgById[id] = bgBase[bgCursor % bgBase.length];
        bgCursor++;
        bgChanged = true;
      }
    }
    if (bgChanged) {
      await prefs.setString('olumlama_bg_json',
          jsonEncode(bgById.map((k, v) => MapEntry('$k', v))));
    }

    // _bgMap: orderedEntries sırasına göre bg index listesi
    final bgMap = orderedEntries.map((e) => bgById[e.id] ?? 0).toList();

    if (!mounted) return;
    final startIdx = cursor % orderedEntries.length;
    String? initialBg;
    if (bgMap.isNotEmpty) {
      final bgIdx = bgMap[startIdx % bgMap.length];
      initialBg = 'assets/images/olumlama_bgs/${_bgFiles[bgIdx % _bgFiles.length]}';
    }
    setState(() {
      _entries  = orderedEntries;
      _bgMap    = bgMap;
      _index    = startIdx;
      _bgBottom = initialBg;
      _bgTop    = null;
      _loading  = false;
    });
  }

  String? _bgPath(int idx) {
    if (_bgMap.isEmpty || _entries.isEmpty) return null;
    final bgIdx = _bgMap[idx % _bgMap.length];
    return 'assets/images/olumlama_bgs/${_bgFiles[bgIdx % _bgFiles.length]}';
  }

  // ─── Navigasyon ───────────────────────────────────────────────────────────

  void _next() {
    if (_entries.isEmpty) return;
    setState(() {
      _direction = 1;
      _index = (_index + 1) % _entries.length;
    });
    _startBgTransition(_bgPath(_index));
    _nextCount++;
  }

  void _prev() {
    if (_entries.isEmpty) return;
    setState(() {
      _direction = -1;
      _index = (_index - 1 + _entries.length) % _entries.length;
    });
    _startBgTransition(_bgPath(_index));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -200) _next();
          if (details.primaryVelocity! >  200) _prev();
        },
        child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Arka plan: alt %100 opak, üst yeni görsel fade-in ────────────
          if (_bgBottom != null)
            Image.asset(_bgBottom!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF0D0A20)),
            )
          else
            const ColoredBox(color: Color(0xFF0D0A20)),
          if (_bgTop != null)
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, child) =>
                  Opacity(opacity: _bgCtrl.value, child: child!),
              child: Image.asset(_bgTop!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF0D0A20)),
              ),
            ),
          // ── Koyu overlay — hafif tutuldu (görseli bozmamak için) ──────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000), // üst: %60
                  Color(0x44000000), // orta: %27 — görsel görünsün
                  Color(0x99000000), // alt: %60
                ],
              ),
            ),
          ),
          // ── İçerik ────────────────────────────────────────────────────────
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFBB88FF),
                      strokeWidth: 2,
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(context),
                      Expanded(child: _buildTextArea()),
                      _buildNavButtons(),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
        ],
        ),
      ),
    );
  }

  // ─── Başlık ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => context.pop(),
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
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          // Başlık
          Expanded(
            child: Center(
              child: Text(
                'OLUMLAMA',
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 5,
                  shadows: const [
                    Shadow(color: Color(0xAABB88FF), blurRadius: 14),
                  ],
                ),
              ),
            ),
          ),
          // Simetri için boşluk
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ─── Metin alanı — yönlü eş zamanlı slide geçişi ────────────────────────
  //
  // Sağa gidince: eskisi SOLA çıkar, yenisi SAĞDAN girer (aynı anda).
  // Sola gidince: eskisi SAĞA çıkar, yenisi SOLDAN girer (aynı anda).
  //
  // AnimatedSwitcher'da transitionBuilder hem gelen hem giden çocuğu sarar.
  // Gelen: animation 0→1, giden: animation 1→0.
  // child.key == ValueKey(_index) ise gelen, değilse giden.

  Widget _buildTextArea() {
    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'Olumlama bulunamadı.',
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ),
      );
    }

    final entry = _entries[_index];
    final metin = VariableReplacer.replace(
      entry.metin,
      ref.read(userProfileProvider).toVariableMap(),
    );

    // Build anındaki yönü kapat — closure'da _direction mutasyonu yakalanmasın
    final dir    = _direction;
    final curKey = ValueKey(_index);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRect( // taşan widget'ları kes
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          // switchInCurve / switchOutCurve yerine transitionBuilder içinde yönetiyoruz
          transitionBuilder: (child, animation) {
            final isIncoming = child.key == curKey;

            // Gelen: Offset(±1,0) → Offset(0,0)   (animation 0→1)
            // Giden: Offset(0,0) → Offset(∓1,0)   (animation 1→0)
            //   ama Tween her zaman begin→end × t hesaplar.
            //   Giden için animation=1 merkez, animation=0 dışarı olmalı:
            //     begin = Offset(∓1,0), end = Offset(0,0)  ← doğru yön

            final Offset begin;
            if (isIncoming) {
              begin = Offset(dir > 0 ? 1.0 : -1.0, 0); // sağdan veya soldan girer
            } else {
              begin = Offset(dir > 0 ? -1.0 : 1.0, 0); // sola veya sağa çıkar
            }

            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
              ),
              child: child,
            );
          },
          // Her iki çocuğu üst üste yığ, yenisi üstte
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          child: SizedBox.expand(
            key: curKey,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                  child: Center(
                    child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: RichTextParser.build(
                    metin,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.75,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.4,
                    ),
                  ),  // Container
                  ),  // Center
                ),  // ConstrainedBox
              ),  // SingleChildScrollView
            ),  // LayoutBuilder
          ),  // SizedBox.expand
        ),  // AnimatedSwitcher
      ),  // ClipRect
    ),  // Padding child
  );
  }

  // ─── Sol / Sağ navigasyon butonları ──────────────────────────────────────

  Widget _buildNavButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavBtn(icon: Icons.chevron_left_rounded,  onTap: _prev),
          // Çıkış butonu — ortada, ikon yok
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'Çıkış',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: _next),
        ],
      ),
    );
  }
}

// ─── Ok butonu ────────────────────────────────────────────────────────────────

class _NavBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: _pressed ? 0.7 : 0.35),
            width: 1.5,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: const Color(0xFFBB88FF).withValues(alpha: 0.4),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
