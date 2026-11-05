// Tavşan Falı: tavşan 5 kapalı kağıttan rastgele birini çeker, kısa bir kısmet yazısı çıkar.
// Veri: assets/data/tavsanfali.json  ({"tavsanfali":[{id, metin, metin_en, kosullar}]})
// Günlük limit: 'tavsanfali_bugun_tarih' + 'tavsanfali_bugun_id' (ana menü rozeti bunları okur).
// No-repeat: 'tavsanfali_gosterilen'. Metin RichTextParser ile çizilir (CLAUDE.md kuralları).
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_text_styles.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

class TavsanFaliScreen extends ConsumerStatefulWidget {
  const TavsanFaliScreen({super.key});

  @override
  ConsumerState<TavsanFaliScreen> createState() => _TavsanFaliScreenState();
}

class _TavsanFaliScreenState extends ConsumerState<TavsanFaliScreen>
    with SingleTickerProviderStateMixin {
  static const _kPapers = 5;
  // Toplam süre: 1000 ms bekleme + 900 uzanma + 400 kalkış + 600 süzülme + 500 açılış.
  static const _kLeadMs = 1000;
  static const _kActionMs = 2400;
  static const _kTotalMs = _kLeadMs + _kActionMs;

  late final AnimationController _ctrl;
  int _target = 0;
  String? _text; // hazır (yer tutucuları doldurulmuş) metin
  bool _repeat = false; // aynı gün tekrar açılış → animasyonsuz
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _target = math.Random().nextInt(_kPapers);
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _kTotalMs));
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  bool _matches(Map e, UserProfile p) {
    final ks = (e['kosullar'] as List?) ?? const [];
    if (ks.isEmpty) return true;
    final byVar = <String, List<String>>{};
    for (final k in ks) {
      byVar
          .putIfAbsent('${k['degisken']}', () => [])
          .add('${k['deger']}'.toLowerCase());
    }
    for (final en in byVar.entries) {
      final String mine;
      switch (en.key) {
        case 'medeni_durum':
          mine = p.maritalStatus;
          break;
        case 'meslek':
          mine = p.job;
          break;
        case 'cinsiyet':
          mine = p.gender;
          break;
        default:
          continue; // bilinmeyen değişken: engelleme
      }
      if (!en.value.contains(mine.toLowerCase())) return false;
    }
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(sharedPrefsProvider);
      final profile = ref.read(userProfileProvider);
      final isEn = ref.read(localeProvider) == 'en';
      final raw = await rootBundle.loadString('assets/data/tavsanfali.json', cache: false);
      final all = ((jsonDecode(raw) as Map)['tavsanfali'] as List)
          .cast<Map<String, dynamic>>();

      final today = _today();
      final savedDate = prefs.getString('tavsanfali_bugun_tarih');
      final savedId = prefs.getInt('tavsanfali_bugun_id');
      Map<String, dynamic>? pick;
      var repeat = false;

      if (savedDate == today && savedId != null) {
        for (final e in all) {
          if (e['id'] == savedId) pick = e;
        }
        repeat = pick != null;
      }

      if (pick == null) {
        var pool = all.where((e) => _matches(e, profile)).toList();
        if (pool.isEmpty) pool = List.of(all);
        final shown = prefs.getStringList('tavsanfali_gosterilen') ?? <String>[];
        var available = pool.where((e) => !shown.contains('${e['id']}')).toList();
        if (available.isEmpty) {
          final lastId = shown.isNotEmpty ? shown.last : null;
          await prefs.setStringList(
              'tavsanfali_gosterilen', lastId != null ? [lastId] : <String>[]);
          available = pool.where((e) => '${e['id']}' != lastId).toList();
          if (available.isEmpty) available = List.of(pool);
        }
        available.shuffle();
        pick = available.first;
        final updated = List<String>.of(
            prefs.getStringList('tavsanfali_gosterilen') ?? <String>[])
          ..add('${pick['id']}');
        await prefs.setStringList('tavsanfali_gosterilen', updated);
        await prefs.setString('tavsanfali_bugun_tarih', today);
        await prefs.setInt('tavsanfali_bugun_id', pick['id'] as int);
      }

      final en = pick['metin_en'] as String?;
      final base = (isEn && en != null && en.isNotEmpty)
          ? en
          : (pick['metin'] as String? ?? '');
      final text = VariableReplacer.replace(base, profile.toVariableMap());
      if (!mounted) return;
      setState(() {
        _text = text;
        _repeat = repeat;
      });
      if (repeat) {
        _ctrl.value = 1;
      } else {
        _ctrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(localeProvider) == 'en';
    final title = isEn ? 'Rabbit Fortune' : 'Tavşan Falı';
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/tavsanfali/tavsan_bg.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0D0A20))),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0x44000000), Color(0x99000000)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                          child: Center(
                              child: Text(title, style: AppTextStyles.screenTitle))),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: _failed
                      ? Center(
                          child: Text(
                              isEn ? 'The rabbit could not pick a paper.' : 'Tavşan kağıt seçemedi.',
                              style: const TextStyle(color: Colors.white70)))
                      : _text == null
                          ? const SizedBox.shrink()
                          : _buildStage(isEn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _seg(double p, double a, double b, [Curve c = Curves.linear]) =>
      c.transform(((p - a) / (b - a)).clamp(0.0, 1.0));

  Widget _buildStage(bool isEn) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      final rabH = h * 0.46;
      final rabW = rabH * 505 / 640;
      final rabCx = w / 2;
      final rabBottom = h * 0.60;
      final pw = math.min(w * 0.17, 90.0);
      final ph = pw * 206 / 240;
      final spacing = w * 0.185;
      final baseY = h * 0.76;

      Offset paperPos(int i) {
        final d = (i - 2).abs();
        return Offset(w / 2 + (i - 2) * spacing, baseY + (2 - d) * h * 0.012);
      }

      double paperRot(int i) => (i - 2) * 0.14;

      return AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final p = _repeat
              ? 1.0
              : (((_ctrl.value * _kTotalMs) - _kLeadMs) / _kActionMs).clamp(0.0, 1.0);
          // Dilimler (2400 ms): uzanma 0-.375, kalkış .375-.54, süzülme .54-.79, açılış .79-1
          final reach = _seg(p, 0, 0.375, Curves.easeInOutCubic);
          final back = _seg(p, 0.54, 0.79, Curves.easeInOutCubic);
          final lift = _seg(p, 0.375, 0.54, Curves.easeOut);
          final fly = _seg(p, 0.54, 0.79, Curves.easeInOutCubic);
          final open = _seg(p, 0.79, 1.0, Curves.easeOutCubic);
          final rabbitAmt = reach * (1 - back);

          final tp = paperPos(_target);
          final dir = (tp.dx - rabCx);
          final rabDx = dir * 0.7 * rabbitAmt;
          final rabDy = h * 0.03 * rabbitAmt - math.sin(math.pi * reach) * 10 * (1 - back);
          final rabRot = (dir / (w / 2)).clamp(-1.0, 1.0) * 0.16 * rabbitAmt;

          final done = p >= 1.0;
          final cardW = math.min(w * 0.86, 420.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Tavşan (masanın arkasında)
              Positioned(
                left: rabCx - rabW / 2,
                top: rabBottom - rabH,
                width: rabW,
                height: rabH,
                child: Transform.translate(
                  offset: Offset(rabDx, rabDy),
                  child: Transform.rotate(
                    angle: rabRot,
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: 1 + 0.06 * rabbitAmt,
                      alignment: Alignment.bottomCenter,
                      child: Image.asset('assets/images/tavsanfali/tavsan.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ),
                ),
              ),
              // Kağıtlar
              for (var i = 0; i < _kPapers; i++)
                if (i != _target || open < 1.0 && !_repeat)
                  _paper(i, tp, paperPos(i), paperRot(i), pw, ph, w, h, lift, fly, open),
              // Açılan not kartı
              if (open > 0 || _repeat)
                Center(
                  child: Opacity(
                    opacity: open.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scaleY: 0.02 + 0.98 * open,
                      scaleX: 0.92 + 0.08 * open,
                      child: _card(cardW),
                    ),
                  ),
                ),
              // Alt alan: durum yazısı → not + Geri Git
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: done ? _bottomDone(isEn) : _statusText(isEn),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _paper(int i, Offset tp, Offset pos, double rot, double pw, double ph,
      double w, double h, double lift, double fly, double open) {
    final isTarget = i == _target;
    var x = pos.dx;
    var y = pos.dy;
    var angle = rot;
    var scale = 1.0;
    var opacity = 1.0;
    if (isTarget) {
      y -= h * 0.14 * lift;
      final cx = w / 2, cy = h * 0.40;
      x = x + (cx - x) * fly;
      y = y + (cy - y) * fly;
      angle = rot * (1 - fly);
      scale = 1 + (math.min(w * 0.4, 190.0) / pw - 1) * fly;
      opacity = 1 - open;
    } else {
      opacity = 1 - 0.7 * lift;
    }
    return Positioned(
      left: x - pw / 2,
      top: y - ph / 2,
      width: pw,
      height: ph,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Image.asset('assets/images/tavsanfali/tavsan_kagit.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }

  Widget _card(double cardW) {
    const ink = Color(0xFF2A1450);
    return Container(
      width: cardW,
      constraints: const BoxConstraints(maxHeight: 360),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7EBD2), Color(0xFFEBDAB6)],
        ),
        border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66FF55FF), blurRadius: 24, spreadRadius: 1),
          BoxShadow(color: Color(0x998B5CF6), blurRadius: 40, spreadRadius: 2),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 2,
              margin: const EdgeInsets.only(bottom: 16),
              color: const Color(0xFF8B5CF6),
            ),
            RichTextParser.build(
              _text ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway( // okuma fontu (EB Garamond pakette yok)
                  fontSize: 20, height: 1.5, fontWeight: FontWeight.w600, color: ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusText(bool isEn) => Text(
        isEn
            ? 'The rabbit is picking a paper for you...'
            : 'Tavşan senin için bir kağıt seçiyor...',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 15),
      );

  Widget _bottomDone(bool isEn) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_repeat)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isEn
                  ? 'Tomorrow the rabbit will pick a new paper for you.'
                  : 'Yarın tavşan senin için yeni bir kağıt çekecek.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 2),
                  Text(isEn ? 'Go Back' : 'Geri Git',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
