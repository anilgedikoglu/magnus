// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Kehanet\Durugoru
// JSON:   assets/data/durugoru_bno.json | durugoru_yno.json | durugoru_gno.json
// Akış:  3 soru seçimi → "Geleceğine odaklanıyorum..." → ana menü → 3dk sonra gelen kutusu

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/variable_replacer.dart';
import '../../data/models/inbox_item.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

// ─── Soru türleri ─────────────────────────────────────────────────────────────

enum _SoruTipi {
  bugun('bno', 'Bugün neler olacak?',    'Durugörü — Bugün',   'assets/data/durugoru_bno.json', 'durugoru_bno', 'assets/images/Yeniikonlar/bugun.png'),
  yarin('yno', 'Yarın neler olacak?',    'Durugörü — Yarın',   'assets/data/durugoru_yno.json', 'durugoru_yno', 'assets/images/Yeniikonlar/yarin.png'),
  gelecek('gno','Gelecekte neler olacak?','Durugörü — Gelecek','assets/data/durugoru_gno.json', 'durugoru_gno', 'assets/images/Yeniikonlar/gelecek.png');

  const _SoruTipi(this.key, this.soru, this.inboxBaslik, this.jsonAsset, this.prefPrefix, this.ikonAsset);
  final String key;
  final String soru;
  final String inboxBaslik;
  final String jsonAsset;
  final String prefPrefix;
  final String ikonAsset;

  String get tarihKey      => '${prefPrefix}_tarih';
  String get gosterilenKey => '${prefPrefix}_gosterilen';
}

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class DurugoruScreen extends ConsumerStatefulWidget {
  const DurugoruScreen({super.key});

  @override
  ConsumerState<DurugoruScreen> createState() => _DurugoruScreenState();
}

class _DurugoruScreenState extends ConsumerState<DurugoruScreen>
    with TickerProviderStateMixin {

  final Map<_SoruTipi, bool> _kullanildi = {
    _SoruTipi.bugun:   false,
    _SoruTipi.yarin:   false,
    _SoruTipi.gelecek: false,
  };

  bool   _odaklaniyor = false;
  bool   _saatUst     = true;
  Timer? _saatToggle;

  String get _bugun => DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  @override
  void dispose() {
    _saatToggle?.cancel();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final t in _SoruTipi.values) {
        _kullanildi[t] = (prefs.getString(t.tarihKey) ?? '') == _bugun;
      }
    });
  }

  // ── Koşul filtresi ────────────────────────────────────────────────────────

  // Aynı değişken adı → OR, farklı değişkenler → AND
  bool _uygun(Map<String, dynamic> e, UserProfile profile) {
    final kosullar = e['kosullar'] as List<dynamic>? ?? [];
    if (kosullar.isEmpty) return true;
    final vars = profile.toVariableMap();

    final Map<String, List<String>> groups = {};
    for (final k in kosullar) {
      final m  = k as Map;
      final dg = (m['degisken'] as String? ?? '').toLowerCase();
      final dg2 = m['deger'] as String? ?? '';
      groups.putIfAbsent(dg, () => []).add(dg2);
    }

    for (final entry in groups.entries) {
      final degisken = entry.key;
      final degerler = entry.value;

      if (degisken == 'yasmax' || degisken == 'yasmin') {
        final age = int.tryParse(vars['yas'] ?? '') ?? 0;
        final ok = degerler.any((d) {
          final lim = int.tryParse(d) ?? 0;
          return degisken == 'yasmax' ? age <= lim : age >= lim;
        });
        if (!ok) return false;
        continue;
      }

      final userVal = (vars[degisken] ?? '').toLowerCase();
      if (userVal.isEmpty) return false;
      if (!degerler.any((d) => userVal == d.toLowerCase())) return false;
    }
    return true;
  }

  // ── Soru seçimi ───────────────────────────────────────────────────────────

  Future<void> _soruyuSec(_SoruTipi tip) async {
    if (_kullanildi[tip] == true) return;

    setState(() => _odaklaniyor = true);

    // Kum saati animasyonu
    _saatToggle = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (mounted) setState(() => _saatUst = !_saatUst);
    });

    final prefs   = await SharedPreferences.getInstance();
    final profile = ref.read(userProfileProvider);

    // JSON yükle
    final raw     = await rootBundle.loadString(tip.jsonAsset);
    final data    = jsonDecode(raw) as Map<String, dynamic>;
    final key     = 'durugoru_${tip.key}';
    final tumListe = (data[key] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Koşul filtresi
    final uygunlar = tumListe.where((e) => _uygun(e, profile)).toList();
    if (uygunlar.isEmpty) {
      _saatToggle?.cancel();
      if (mounted) setState(() => _odaklaniyor = false);
      return;
    }

    // No-repeat seçim
    List<String> gosterilen = prefs.getStringList(tip.gosterilenKey) ?? [];
    var kalan = uygunlar.where((e) => !gosterilen.contains('${e['id']}')).toList();

    if (kalan.isEmpty) {
      final lastId = gosterilen.isNotEmpty ? gosterilen.last : null;
      gosterilen = lastId != null ? [lastId] : [];
      await prefs.setStringList(tip.gosterilenKey, gosterilen);
      kalan = uygunlar.where((e) => '${e['id']}' != lastId).toList();
      if (kalan.isEmpty) kalan = List.from(uygunlar);
    }

    kalan.shuffle(Random());
    final secilen = kalan.first;
    final metin   = VariableReplacer.replace(
        secilen['metin'] as String, profile.toVariableMap());

    // Gösterilen kaydet
    gosterilen.add('${secilen['id']}');
    await prefs.setStringList(tip.gosterilenKey, gosterilen);
    await prefs.setString(tip.tarihKey, _bugun);

    // Inbox'a ekle — 3 dakika sonra açılır
    final unlockAt = DateTime.now().add(const Duration(minutes: 3)).toIso8601String();
    final item = InboxItem(
      id:             const Uuid().v4(),
      title:          tip.inboxBaslik,
      text:           metin,
      date:           DateTime.now().toIso8601String(),
      fortuneTypeKey: 'durugoru',
      iconAsset:      'assets/images/menu/durugoru.png',
      unlockAt:       unlockAt,
    );
    ref.read(inboxProvider.notifier).addItem(item);

    // 2 saniye animasyon sonra ana menüye dön
    await Future.delayed(const Duration(seconds: 2));
    _saatToggle?.cancel();

    if (!mounted) return;
    ref.read(durugoruSentProvider.notifier).state = true;
    context.pop();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/falbg/durugoru.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF060D1A)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xAA000000), Color(0x44000000), Color(0xAA000000)],
              ),
            ),
          ),
          SafeArea(
            child: _odaklaniyor ? _buildOdaklaniyor() : _buildSorular(),
          ),
        ],
      ),
    );
  }

  Widget _buildSorular() {
    final tumKullanildi = _kullanildi.values.every((v) => v);
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tumKullanildi) ...[
              const Icon(Icons.visibility_off_rounded,
                  color: Color(0xFF5599AA), size: 52),
              const SizedBox(height: 20),
              const Text('Bugünkü durugörü\nhakkın doldu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 17,
                    height: 1.5, fontWeight: FontWeight.w300)),
              const SizedBox(height: 8),
              Text('Yarın yeni bir görü açılacak.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13)),
            ] else ...[
              _buildMagnusBalon('Nasıl ilerleyelim?'),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final tip in _SoruTipi.values)
                      _buildSoruButon(tip),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      // Geri Git — dert ortağı standardı
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 2),
                  Text('Geri Git', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildMagnusBalon(String metin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Magnus yuvarlağı
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFAA88FF), width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/magnusicon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF4835A6),
                  child: const Center(child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Konuşma balonu
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6633CC).withValues(alpha: 0.85),
                    const Color(0xFF4422AA).withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: const Color(0xFFAA88FF).withValues(alpha: 0.40), width: 1),
              ),
              child: Text(
                metin,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoruButon(_SoruTipi tip) {
    final kullanildi = _kullanildi[tip] == true;
    const accent = Color(0xFF4DBBCC);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: kullanildi ? null : () => _soruyuSec(tip),
          child: AnimatedOpacity(
            opacity: kullanildi ? 0.38 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: kullanildi
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: kullanildi
                      ? Colors.white.withValues(alpha: 0.10)
                      : accent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: kullanildi ? null : [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 16, spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    child: Image.asset(
                      tip.ikonAsset,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 80,
                        child: Icon(Icons.remove_red_eye_outlined,
                            color: Color(0xFF4DBBCC), size: 52),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                    child: Text(
                      tip.soru,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kullanildi ? Colors.white38 : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (kullanildi) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white30, size: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOdaklaniyor() {
    return Column(children: [
      _buildHeader(),
      Expanded(child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00BBDD), Color(0xFF0077AA)],
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
              'Geleceğine odaklanıyorum...',
              style: TextStyle(color: Colors.white70, fontSize: 16,
                  fontStyle: FontStyle.italic, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      )),
    ]);
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
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 18),
          ),
        ),
        Expanded(
          child: Center(
            child: Text('DURUGÖRÜ',
              style: GoogleFonts.cinzel(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: const Color(0xFF4DBBCC), letterSpacing: 5,
                shadows: const [Shadow(color: Color(0xAA00BBDD), blurRadius: 16)],
              )),
          ),
        ),
        const SizedBox(width: 38),
      ]),
    );
  }
}
