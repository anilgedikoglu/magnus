// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Ozlusoz\
// JSON:   assets/data/ozlusozler.json
// Arka plan: assets/images/ozlusoz_bgs/

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../data/providers.dart';

class _OzluSozEntry {
  final int id;
  final String metin;
  final String metinEn;
  final String yazar;
  const _OzluSozEntry({required this.id, required this.metin, this.metinEn = '', required this.yazar});
  String metinFor(bool isEn) => (isEn && metinEn.isNotEmpty) ? metinEn : metin;
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
    '08.jpeg', '010.jpeg', '011.jpeg', '013.jpeg', '015.jpeg',
    '016.jpeg', '017.jpeg', '018.jpeg', '041.jpeg', '042.jpeg',
  ];

  final _rng = Random();

  List<_OzluSozEntry> _sessionEntries = [];
  List<int>           _sessionBgs     = [];
  int  _index        = 0;
  int  _direction    = 1;
  bool _loading      = true;
  bool _limitVisible = false;
  int  _nextCount    = 0; // ileri basma sayacı — her 5'te reklam
  Timer? _limitTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    super.dispose();
  }

  String? get _currentBg {
    if (_sessionBgs.isEmpty || _sessionEntries.isEmpty) return null;
    final bgIdx = _sessionBgs[_index % _sessionBgs.length];
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
        metinEn: (m['metin_en'] as String?) ?? '',
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
        _loading        = false;
      });
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
      _loading        = false;
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
      });
      return;
    }
    setState(() { _direction = 1; _index++; });
    _nextCount++;
  }

  void _prev() {
    if (_index <= 0) return;
    setState(() { _direction = -1; _index--; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
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
            // ── Arka plan — yükleme öncesi de ilk görsel anında çıkar ──────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: GrimoireBackdrop(
                key: ValueKey(_currentBg ?? '__default__'),
                asset: _currentBg ?? 'assets/images/ozlusoz_bgs/${_bgFiles[0]}',
                child: const SizedBox.shrink(),
              ),
            ),

            // ── İçerik ────────────────────────────────────────────────────────
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: AppColors.gold, strokeWidth: 2))
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
              color: AppColors.glassTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.rim, width: 0.9),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.bone, size: 18),
          ),
        ),
        Expanded(child: Center(child: Text(ref.watch(l10nProvider).quotesTitle,
          style: AppTextStyles.screenTitle))),
        const SizedBox(width: 38),
      ]),
    );
  }

  Widget _buildTextArea() {
    if (_sessionEntries.isEmpty) {
      return Center(child: Text(
          ref.watch(l10nProvider).quoteNotFound,
          style: AppTextStyles.meta.copyWith(fontSize: 15)));
    }

    final entry  = _sessionEntries[_index];
    final metin  = VariableReplacer.replace(
        entry.metinFor(ref.watch(localeProvider) == 'en'),
        ref.read(userProfileProvider).toVariableMap());
    final dir    = _direction;
    final curKey = _limitVisible ? const ValueKey('limit') : ValueKey(_index);
    const accent = AppColors.gold;

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
              ? Center(key: curKey, child: SizedBox(
                  width: 220, height: 220,
                  child: GlassPanel(
                  variant: GlassVariant.reading,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 52, height: 52,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(
                              color: accent.withValues(alpha: 0.6), width: 1)),
                        child: Center(child: Text('!',
                            style: AppTextStyles.ritualTitle.copyWith(
                                color: accent, fontSize: 26)))),
                      const SizedBox(height: 16),
                      Text(
                        ref.watch(l10nProvider).quotesLimitReached,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.uiLabel.copyWith(
                            fontSize: 16, height: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                          ref.watch(l10nProvider).quotesRestarting, textAlign: TextAlign.center,
                        style: AppTextStyles.meta),
                    ]),
                )))
              : SizedBox.expand(key: curKey, child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                    child: Center(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassPanel(
                    variant: GlassVariant.reading,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: SizedBox(width: double.infinity, child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.format_quote_rounded, size: 34,
                          color: accent.withValues(alpha: 0.75)),
                      const SizedBox(height: 8),
                      RichTextParser.build(metin, textAlign: TextAlign.center,
                        style: AppTextStyles.reading.copyWith(
                            fontSize: metin.length > 200 ? 16 : 18, height: 1.7)),
                      if (entry.yazar.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(height: 1, color: accent.withValues(alpha: 0.25)),
                        const SizedBox(height: 10),
                        Text('— ${entry.yazar}', textAlign: TextAlign.center,
                          style: AppTextStyles.uiLabel.copyWith(
                              fontSize: 13, color: accent, letterSpacing: 0.5)),
                      ],
                    ])),
                  ))),  // GlassPanel + Padding + Center
                ),     // ConstrainedBox
              ),       // SingleChildScrollView
            )),        // LayoutBuilder + SizedBox.expand
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
              color: AppColors.glassTint,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.rim, width: 0.9),
            ),
            child: Center(child: Text(
                ref.watch(l10nProvider).exit, style: AppTextStyles.uiLabel)),
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
          color: _pressed ? AppColors.glassTintSelected : AppColors.glassTint,
          shape: BoxShape.circle,
          border: Border.all(
              color: _pressed ? AppColors.gold.withValues(alpha: 0.62) : AppColors.rim,
              width: 0.9),
        ),
        child: Icon(widget.icon, color: AppColors.bone, size: 30),
      ),
    );
  }
}
