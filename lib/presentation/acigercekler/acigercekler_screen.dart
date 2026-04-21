// Kaynak: assets/data/acigercekler.json
// Akış: Kum saati (5sn hazırlık) → Acı gerçek (typewriter animasyonu, soldan sağa)
// Günlük limit: günde 1 kez (acigercekler_bugun_tarih); 2. ziyarette son içerik tekrar gösterilir
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
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

enum _Adim { yukleniyor, icerik }

class AciGerceklerScreen extends ConsumerStatefulWidget {
  const AciGerceklerScreen({super.key});

  @override
  ConsumerState<AciGerceklerScreen> createState() =>
      _AciGerceklerScreenState();
}

class _AciGerceklerScreenState extends ConsumerState<AciGerceklerScreen>
    with TickerProviderStateMixin {

  static const _prefGosterilen = 'acigercekler_gosterilen';
  static const _prefBugun      = 'acigercekler_bugun_tarih';
  static const _prefSonMetin   = 'acigercekler_son_metin';

  static const _scrollThreshold = 280;

  _Adim   _adim         = _Adim.yukleniyor;
  String  _metin        = '';
  bool    _veriYuklendi = false;
  bool    _textAtBottom = false;

  bool   _saatUst   = true;
  Timer? _saatToggle;
  Timer? _gecisTimer;

  final _textScrollCtrl = ScrollController();

  String get _bugun => DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _textScrollCtrl.addListener(_onTextScroll);
    _loadData();
  }

  @override
  void dispose() {
    _saatToggle?.cancel();
    _gecisTimer?.cancel();
    _textScrollCtrl.removeListener(_onTextScroll);
    _textScrollCtrl.dispose();
    super.dispose();
  }

  void _onTextScroll() {
    if (!_textScrollCtrl.hasClients) return;
    final atBottom = _textScrollCtrl.position.pixels >=
        _textScrollCtrl.position.maxScrollExtent - 4;
    if (atBottom != _textAtBottom) setState(() => _textAtBottom = atBottom);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Aynı gün ikinci ziyaret: son içeriği direkt göster
    if (prefs.getString(_prefBugun) == _bugun) {
      final sonMetin = prefs.getString(_prefSonMetin) ?? '';
      if (mounted) {
        setState(() {
          _metin        = sonMetin;
          _adim         = _Adim.icerik;
          _veriYuklendi = true;
        });
      }
      return;
    }

    final jsonStr  = await rootBundle.loadString('assets/data/acigercekler.json');
    final raw      = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tumListe = (raw['acigercekler'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final profile  = ref.read(userProfileProvider);
    final uygunlar = tumListe.where((e) {
      final kosullar = e['kosullar'] as List<dynamic>? ?? [];
      return _kosullarUygun(kosullar, profile);
    }).toList();

    List<String> gosterilenIds = prefs.getStringList(_prefGosterilen) ?? [];
    var kalan = uygunlar
        .where((e) => !gosterilenIds.contains(e['id'] as String))
        .toList();

    if (kalan.isEmpty) {
      final lastId = gosterilenIds.isNotEmpty ? gosterilenIds.last : null;
      gosterilenIds = lastId != null ? [lastId] : [];
      await prefs.setStringList(_prefGosterilen, gosterilenIds);
      kalan = uygunlar.where((e) => e['id'] != lastId).toList();
      if (kalan.isEmpty) kalan = List.from(uygunlar);
    }

    kalan.shuffle(Random());
    final secilen = kalan.first;
    final metin   = VariableReplacer.replace(
      secilen['metin'] as String,
      profile.toVariableMap(),
    );

    gosterilenIds.add(secilen['id'] as String);
    await prefs.setStringList(_prefGosterilen, gosterilenIds);
    await prefs.setString(_prefBugun, _bugun);
    await prefs.setString(_prefSonMetin, metin);

    if (!mounted) return;
    setState(() {
      _metin        = metin;
      _veriYuklendi = true;
    });

    _baslatKumSaati();
  }

  bool _kosullarUygun(List<dynamic> kosullar, UserProfile profile) {
    if (kosullar.isEmpty) return true;
    for (final k in kosullar) {
      final m = k as Map;
      if (_profilDegeri(m['degisken'] as String? ?? '', profile)
          != (m['deger'] as String? ?? '')) { return false; }
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

  void _baslatKumSaati() {
    _saatToggle = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (mounted) setState(() => _saatUst = !_saatUst);
    });
    _gecisTimer = Timer(const Duration(seconds: 5), () {
      _saatToggle?.cancel();
      if (mounted) setState(() => _adim = _Adim.icerik);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan görseli
          Image.asset(
            'assets/images/acigercekler_bg.jpeg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF0A0718)),
          ),
          // Koyu overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xAA000000), Color(0x55000000), Color(0xAA000000)],
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: !_veriYuklendi
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFFAA88FF), strokeWidth: 2))
                : switch (_adim) {
                    _Adim.yukleniyor => _buildYukleniyor(),
                    _Adim.icerik     => _buildIcerik(),
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildBaslikBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
        ),
        const Expanded(
          child: Text('ACI GERÇEKLER',
            style: TextStyle(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.bold, letterSpacing: 1.2),
            textAlign: TextAlign.center),
        ),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildYukleniyor() {
    return Column(children: [
      _buildBaslikBar(),
      Expanded(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFAA00FF), Color(0xFFFF44AA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: AnimatedRotation(
                turns: _saatUst ? 0.0 : 0.5,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                child: const Icon(Icons.hourglass_bottom_rounded,
                    size: 72, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Sana acı ama gerçek bir şeyler anlatmaya hazırlanıyorum...',
                style: TextStyle(color: Colors.white70, fontSize: 15,
                    fontStyle: FontStyle.italic, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildIcerik() {
    const accent = Color(0xFFAA44FF);
    return Column(children: [
      _buildBaslikBar(),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: accent.withValues(alpha: 0.30), width: 1),
              ),
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('🔥', style: TextStyle(fontSize: 26)),
                const SizedBox(height: 14),
                // Kaydırılabilir typewriter metni
                Flexible(
                  child: ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor: WidgetStatePropertyAll(
                          const Color(0xFFFF88CC).withValues(alpha: 0.75)),
                      thickness: const WidgetStatePropertyAll(3),
                      radius: const Radius.circular(4),
                      minThumbLength: 28,
                      thumbVisibility: const WidgetStatePropertyAll(true),
                      crossAxisMargin: -5,
                      mainAxisMargin: 24,
                    ),
                    child: Scrollbar(
                      controller: _textScrollCtrl,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _textScrollCtrl,
                        padding: const EdgeInsets.only(right: 14),
                        child: _TypewriterText(
                          text: _metin,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.65,
                          ),
                          textAlign: TextAlign.start,
                          msPerChar: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Uzun metinde aşağı ok
                Center(
                  child: _metin.length > _scrollThreshold && !_textAtBottom
                      ? Icon(Icons.keyboard_arrow_down_rounded,
                          color: accent.withValues(alpha: 0.75), size: 36)
                      : const SizedBox(height: 36),
                ),
              ]),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: _buildKapatButonu(),
      ),
    ]);
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
              color: const Color(0xFFFF55FF).withValues(alpha: 0.8), width: 1.5),
        ),
        child: const Center(
          child: Text('Kapat',
            style: TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typewriter widget — soldan sağa yazar
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
  int    _index     = 0;

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
      _index     = 0;
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
        if (_index >= chars.length) { t.cancel(); return; }
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
