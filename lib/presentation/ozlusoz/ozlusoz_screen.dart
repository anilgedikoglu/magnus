// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Ozlusoz\
// JSON:   assets/data/ozlusozler.json
// Arka plan: assets/images/ozlusoz_bgs/ (20 seçilmiş görsel, başlangıçta tümü bellekte)
//
// BG GEÇİŞİ: Alt katman daima %100 opak. Yeni görsel üstüne AnimatedOpacity ile
// fade-in yapar (0→1). Geçiş boyunca siyah zemin hiç görünmez → kararma yok.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

class _OzluSozEntry {
  final int id;
  final String metin;
  final String yazar;
  const _OzluSozEntry({required this.id, required this.metin, required this.yazar});
}

class OzluSozScreen extends ConsumerStatefulWidget {
  const OzluSozScreen({super.key});
  @override
  ConsumerState<OzluSozScreen> createState() => _OzluSozScreenState();
}

class _OzluSozScreenState extends ConsumerState<OzluSozScreen> {

  static const _prefSessionTarih = 'ozlusoz_session_tarih';
  static const _prefSessionIds   = 'ozlusoz_session_ids';
  static const _prefSessionBgs   = 'ozlusoz_session_bgs';
  static const _prefGosterilen   = 'ozlusoz_gosterilen_idler';
  static const _gunlukLimit      = 10;

  static const List<String> _bgFiles = [
    '01.jpeg',  '05.jpeg',  '09.jpeg',  '011.jpeg', '015.jpeg',
    '019.jpeg', '022.jpeg', '030.jpeg', '035.jpeg', '042.jpeg',
    '048.jpeg', '054.jpeg', '060.jpeg', '066.jpeg', '072.jpeg',
    '079.jpeg', '082.jpeg', '089.jpeg', '095.jpeg', '099.jpeg',
  ];

  final _rng = Random();

  List<_OzluSozEntry> _sessionEntries = [];
  List<int>           _sessionBgs     = [];
  int  _index        = 0;
  int  _direction    = 1;
  bool _loading      = true;
  bool _limitVisible = false;
  Timer? _limitTimer;

  // ── BG geçiş katmanları ──────────────────────────────────────────────────────
  String? _bgBottom;      // alt katman — daima %100 opak
  String? _bgTop;         // üst katman — fade-in olan yeni görsel
  bool    _bgTopVisible = false;
  Timer?  _bgTransTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    _bgTransTimer?.cancel();
    super.dispose();
  }

  // ── Yeni bg'yi alt katman üzerine fade-in ile getir ───────────────────────────
  void _changeBg(String? newBg) {
    if (newBg == null || newBg == _bgBottom) return;
    _bgTransTimer?.cancel();
    setState(() {
      if (_bgTop != null) _bgBottom = _bgTop; // önceki geçiş yarıdaysa snap
      _bgTop       = newBg;
      _bgTopVisible = false;                  // önce 0 opacity ile ağaca ekle
    });
    // Bir kare sonra opacity 1'e çek → AnimatedOpacity animasyonu başlar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _bgTopVisible = true);
      // Animasyon bitince alt katmana taşı
      _bgTransTimer = Timer(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          _bgBottom    = _bgTop;
          _bgTop       = null;
          _bgTopVisible = false;
        });
      });
    });
  }

  String? _bgForIndex(int idx, List<int> bgs) {
    if (bgs.isEmpty) return null;
    final bgIdx = bgs[idx % bgs.length];
    return 'assets/images/ozlusoz_bgs/${_bgFiles[bgIdx % _bgFiles.length]}';
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final jsonStr  = await rootBundle.loadString('assets/data/ozlusozler.json');
    final data     = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tumListe = (data['ozlusozler'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return _OzluSozEntry(
        id:    m['id'] as int,
        metin: m['metin'] as String,
        yazar: (m['yazar'] as String?) ?? '',
      );
    }).toList();

    final idMap = {for (final e in tumListe) e.id: e};

    final sessionTarih = prefs.getString(_prefSessionTarih);
    if (sessionTarih == today) {
      final savedIds = prefs.getStringList(_prefSessionIds) ?? [];
      final savedBgs = prefs.getStringList(_prefSessionBgs) ?? [];
      final entries  = savedIds.map((id) => idMap[int.tryParse(id)])
          .whereType<_OzluSozEntry>().toList();
      final bgs      = savedBgs.map((b) => int.tryParse(b) ?? 0).toList();

      if (!mounted) return;
      setState(() {
        _sessionEntries = entries;
        _sessionBgs     = bgs;
        _bgBottom       = _bgForIndex(0, bgs);
        _bgTop          = null;
        _loading        = false;
      });
      _precacheAll();
      return;
    }

    List<String> gosterilen = prefs.getStringList(_prefGosterilen) ?? [];
    var kalan = tumListe.where((e) => !gosterilen.contains('${e.id}')).toList();

    if (kalan.length < _gunlukLimit) {
      final koruma = gosterilen.length > _gunlukLimit
          ? gosterilen.sublist(gosterilen.length - _gunlukLimit)
          : gosterilen;
      gosterilen = List.from(koruma);
      await prefs.setStringList(_prefGosterilen, gosterilen);
      kalan = tumListe.where((e) => !gosterilen.contains('${e.id}')).toList();
      if (kalan.isEmpty) kalan = List.from(tumListe);
    }

    kalan.shuffle(_rng);
    final session    = kalan.take(_gunlukLimit).toList();
    final bgPool     = List<int>.generate(_bgFiles.length, (i) => i)..shuffle(_rng);
    final sessionBgs = List<int>.generate(
        session.length, (i) => bgPool[i % bgPool.length]);

    gosterilen.addAll(session.map((e) => '${e.id}'));
    await prefs.setStringList(_prefGosterilen, gosterilen);
    await prefs.setString(_prefSessionTarih, today);
    await prefs.setStringList(_prefSessionIds, session.map((e) => '${e.id}').toList());
    await prefs.setStringList(_prefSessionBgs, sessionBgs.map((b) => '$b').toList());

    if (!mounted) return;
    setState(() {
      _sessionEntries = session;
      _sessionBgs     = sessionBgs;
      _bgBottom       = _bgForIndex(0, sessionBgs);
      _bgTop          = null;
      _loading        = false;
    });
    _precacheAll();
  }

  void _precacheAll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final file in _bgFiles) {
        precacheImage(AssetImage('assets/images/ozlusoz_bgs/$file'), context);
      }
    });
  }

  void _next() {
    if (_sessionEntries.isEmpty) return;
    if (_index >= _sessionEntries.length - 1) {
      setState(() => _limitVisible = true);
      _limitTimer?.cancel();
      _limitTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() { _limitVisible = false; _direction = 1; _index = 0; });
        _changeBg(_bgForIndex(0, _sessionBgs));
      });
      return;
    }
    setState(() { _direction = 1; _index++; });
    _changeBg(_bgForIndex(_index, _sessionBgs));
  }

  void _prev() {
    if (_index <= 0) return;
    setState(() { _direction = -1; _index--; });
    _changeBg(_bgForIndex(_index, _sessionBgs));
  }

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
            // ── Alt katman: daima %100 opak ────────────────────────────────────
            if (_bgBottom != null)
              Image.asset(_bgBottom!,
                fit: BoxFit.cover, width: double.infinity,
                height: double.infinity, alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF0D0A20)),
              )
            else
              const ColoredBox(color: Color(0xFF0D0A20)),

            // ── Üst katman: yeni görsel fade-in ────────────────────────────────
            if (_bgTop != null)
              AnimatedOpacity(
                opacity: _bgTopVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                child: Image.asset(_bgTop!,
                  fit: BoxFit.cover, width: double.infinity,
                  height: double.infinity, alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF0D0A20)),
                ),
              ),

            // ── Overlay ────────────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x88000000), Color(0x33000000), Color(0x88000000)],
                ),
              ),
            ),

            // ── İçerik ────────────────────────────────────────────────────────
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFFBB88FF), strokeWidth: 2))
                  : Column(children: [
                      _buildHeader(),
                      Expanded(child: _buildTextArea()),
                      _buildNavButtons(),
                      const SizedBox(height: 12),
                    ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        Expanded(child: Center(child: Text('ÖZLÜ SÖZLER',
          style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold,
            color: Colors.white, letterSpacing: 5,
            shadows: const [Shadow(color: Color(0xAABB88FF), blurRadius: 14)])))),
        const SizedBox(width: 38),
      ]),
    );
  }

  Widget _buildTextArea() {
    if (_sessionEntries.isEmpty) {
      return const Center(child: Text('Özlü söz bulunamadı.',
          style: TextStyle(color: Colors.white54, fontSize: 15)));
    }

    final entry  = _sessionEntries[_index];
    final metin  = VariableReplacer.replace(
        entry.metin, ref.read(userProfileProvider).toVariableMap());
    final dir    = _direction;
    final curKey = _limitVisible ? const ValueKey('limit') : ValueKey(_index);
    const accent = Color(0xFFBB88FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 620),
          transitionBuilder: (child, animation) {
            final isIncoming = child.key == curKey;
            final begin = Offset(isIncoming
                ? (dir > 0 ? 1.0 : -1.0) : (dir > 0 ? -1.0 : 1.0), 0);
            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeInOutCubic)),
              child: child,
            );
          },
          layoutBuilder: (cur, prev) => Stack(alignment: Alignment.center,
              children: [...prev, if (cur != null) cur]),
          child: _limitVisible
              ? Center(key: curKey, child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.30), width: 1),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 52, height: 52,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.55), width: 2)),
                        child: const Center(child: Text('!',
                            style: TextStyle(color: Color(0xFFBB88FF),
                                fontSize: 26, fontWeight: FontWeight.bold)))),
                      const SizedBox(height: 16),
                      const Text('Günlük özlü söz\nhakkın doldu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w500, height: 1.5)),
                      const SizedBox(height: 8),
                      Text('Baştan başlıyoruz...', textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12)),
                    ]),
                ))
              : Center(key: curKey, child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.30), width: 1),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('❝', style: TextStyle(fontSize: 38,
                        color: accent.withValues(alpha: 0.75), height: 1)),
                    const SizedBox(height: 14),
                    Text(metin, textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white,
                          fontSize: metin.length > 200 ? 15 : 17,
                          height: 1.75, fontWeight: FontWeight.w300,
                          letterSpacing: 0.3)),
                    Text('❞', style: TextStyle(fontSize: 38,
                        color: accent.withValues(alpha: 0.75), height: 1)),
                    if (entry.yazar.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(height: 1, color: accent.withValues(alpha: 0.2)),
                      const SizedBox(height: 10),
                      Text('— ${entry.yazar}', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13,
                            color: accent.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                    ],
                  ]),
                )),
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _NavBtn(icon: Icons.chevron_left_rounded,  onTap: _prev),
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            height: 56, padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 1),
            ),
            child: const Center(child: Text('Çıkış',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w500))),
          ),
        ),
        _NavBtn(icon: Icons.chevron_right_rounded, onTap: _next),
      ]),
    );
  }
}

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
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: _pressed ? 0.7 : 0.35),
              width: 1.5),
          boxShadow: _pressed ? [BoxShadow(
              color: const Color(0xFFBB88FF).withValues(alpha: 0.4),
              blurRadius: 12)] : null,
        ),
        child: Icon(widget.icon, color: Colors.white, size: 30),
      ),
    );
  }
}
