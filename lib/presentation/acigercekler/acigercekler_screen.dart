// Kaynak: assets/data/acigercekler.json
// Akış: Kum saati (5sn) → Acı gerçek (direkt metin, kırmızı flare animasyonu)
// Günlük limit: günde 1 kez; aynı gün 2. ziyarette son içerik tekrar açılır
// Tekrar gösterilmeme: acigercekler_gosterilen (tüm ID'ler görülünce sıfırla)

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

enum _Adim { yukleniyor, icerik }

class AciGerceklerScreen extends ConsumerStatefulWidget {
  const AciGerceklerScreen({super.key});

  @override
  ConsumerState<AciGerceklerScreen> createState() => _AciGerceklerScreenState();
}

class _AciGerceklerScreenState extends ConsumerState<AciGerceklerScreen>
    with TickerProviderStateMixin {

  static const _prefGosterilen = 'acigercekler_gosterilen';
  static const _prefBugun      = 'acigercekler_bugun_tarih';
  static const _prefSonMetin   = 'acigercekler_son_metin';
  static const _scrollThreshold = 280;

  _Adim  _adim         = _Adim.yukleniyor;
  String _metin        = '';
  bool   _veriYuklendi = false;
  bool   _textAtBottom = false;
  bool   _saatUst      = true;

  Timer? _saatToggle;
  Timer? _gecisTimer;

  final _textScrollCtrl = ScrollController();

  late AnimationController _flareCtrl;
  late Animation<double>   _flareAnim;

  String get _bugun => DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _flareCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _flareAnim = CurvedAnimation(parent: _flareCtrl, curve: Curves.easeInOut);
    _textScrollCtrl.addListener(_onTextScroll);
    _loadData();
  }

  @override
  void dispose() {
    _saatToggle?.cancel();
    _gecisTimer?.cancel();
    _flareCtrl.dispose();
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

    // Aynı gün ve daha önce içerik gösterildiyse tekrar göster
    final sonMetin = prefs.getString(_prefSonMetin) ?? '';
    if (prefs.getString(_prefBugun) == _bugun && sonMetin.isNotEmpty) {
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
          Image.asset(
            'assets/images/acigercekler_bg.jpeg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0A0718)),
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
      Expanded(child: Center(
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
      )),
    ]);
  }

  Widget _buildIcerik() {
    return Column(children: [
      _buildBaslikBar(),
      Expanded(child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedBuilder(
            animation: _flareAnim,
            builder: (context, child) {
              final t = _flareAnim.value;
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF2200).withValues(alpha: 0.25 + t * 0.50),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2200).withValues(alpha: 0.12 + t * 0.30),
                      blurRadius: 8 + t * 18,
                      spreadRadius: t * 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF7700).withValues(alpha: 0.07 + t * 0.18),
                      blurRadius: 22 + t * 32,
                      spreadRadius: t * 6,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Center(child: Text('🔥', style: TextStyle(fontSize: 26))),
                const SizedBox(height: 14),
                Flexible(
                  child: ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor: WidgetStatePropertyAll(
                          const Color(0xFFFF6644).withValues(alpha: 0.75)),
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
                        child: Text(
                          _metin,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.65,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: _metin.length > _scrollThreshold && !_textAtBottom
                      ? const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFFF4422), size: 36)
                      : const SizedBox(height: 36),
                ),
              ]),
            ),
          ),
        ),
      )),
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
