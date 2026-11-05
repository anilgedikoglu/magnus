// Tavşan Falı: tavşan 5 kapalı kağıttan rastgele birini çeker, kısa bir kısmet yazısı çıkar.
// Veri: assets/data/tavsanfali.json  ({"tavsanfali":[{id, metin, metin_en, kosullar}]})
// Günlük limit: 'tavsanfali_bugun_tarih' + 'tavsanfali_bugun_id' (ana menü rozeti bunları okur).
// No-repeat: 'tavsanfali_gosterilen'. Metin RichTextParser ile çizilir (CLAUDE.md kuralları).
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_text_styles.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

class TavsanFaliScreen extends ConsumerStatefulWidget {
  const TavsanFaliScreen({super.key});

  @override
  ConsumerState<TavsanFaliScreen> createState() => _TavsanFaliScreenState();
}

class _TavsanFaliScreenState extends ConsumerState<TavsanFaliScreen>
    with TickerProviderStateMixin {
  static const _kPapers = 5;
  // Toplam süre: 1000 ms bekleme + 900 uzanma + 400 kalkış + 600 süzülme + 500 açılış.
  static const _kLeadMs = 1000;
  static const _kActionMs = 2400;
  static const _kTotalMs = _kLeadMs + _kActionMs;

  late final AnimationController _ctrl;
  // Bekleme: kağıtlar hafifçe dalgalanır (dokunulabilir olduklarını belli eder).
  late final AnimationController _idle;
  // Göz kırpma (Anıl, 2026-11-06): iki hızlı kırpış → bekleme → yine iki hızlı kırpış.
  late final AnimationController _blink;
  // Not kartı: açıldıktan sonra dışına dokununca kapanır; kağıt tavşanın önünde kalır,
  // ona dokununca yeniden açılır (Anıl, 2026-11-06). 1 = açık.
  late final AnimationController _card;
  int _target = 0;
  // Kullanıcı dokunmadan tavşan çekmez (Anıl, 2026-11-05). Kayıt da dokununca yapılır:
  // açıp dokunmadan çıkan kullanıcının günlük hakkı boşa gitmez.
  bool _started = false;
  Future<void> Function(String today)? _persist;
  String? _text; // hazır (yer tutucuları doldurulmuş) metin
  bool _repeat = false; // aynı gün tekrar açılış → animasyonsuz
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _target = math.Random().nextInt(_kPapers);
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _kTotalMs));
    _idle = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _blink = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _kBlinkCycleMs))
      ..repeat();
    _card = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280), value: 1);
    _load();
  }

  /// Dokunuş → seçimi kaydet, tavşan [paper] kağıdını (null → rastgele) çeksin.
  void _start([int? paper]) {
    if (_started || _text == null || _failed) return;
    HapticFeedback.selectionClick();
    setState(() {
      _started = true;
      if (paper != null) _target = paper;
    });
    // Tarih DOKUNUŞ anında alınır (23.59'da açılıp 00.01'de dokunulursa bugüne yazılır).
    final persist = _persist;
    _persist = null;
    if (persist != null) {
      persist(_today()).catchError((Object e) {
        debugPrint('[TavsanFali] kayıt hatası: $e');
      });
    }
    _idle.stop();
    // Bekleme payını atla: dokunur dokunmaz uzansın.
    _ctrl.forward(from: _kLeadMs / _kTotalMs);
  }

  @override
  void dispose() {
    _idle.dispose();
    _ctrl.dispose();
    _blink.dispose();
    _card.dispose();
    super.dispose();
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // İlk kırpışta katman yüklenirken boş kare olmasın.
    precacheImage(const AssetImage(_kClosedEyes), context);
  }

  /// Not kartını kapat (dışına dokunuş) / yeniden aç (tavşanın önündeki kağıda dokunuş).
  void _closeCard() {
    if (_card.status == AnimationStatus.reverse || _card.value == 0) return;
    HapticFeedback.selectionClick();
    _card.reverse();
  }

  void _openCard() {
    if (_card.status == AnimationStatus.forward || _card.value == 1) return;
    HapticFeedback.selectionClick();
    _card.forward();
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
        var base = shown;
        if (available.isEmpty) {
          final lastId = shown.isNotEmpty ? shown.last : null;
          base = lastId != null ? [lastId] : <String>[];
          available = pool.where((e) => '${e['id']}' != lastId).toList();
          if (available.isEmpty) available = List.of(pool);
        }
        available.shuffle();
        final chosen = available.first;
        pick = chosen;
        final updated = List<String>.of(base)..add('${chosen['id']}');
        // Kayıt kullanıcı dokununca (_start). Sıra önemli: önce ID + gösterilenler, EN SON
        // tarih → arada uygulama kapanırsa dünün ID'si bugünün sayılmaz.
        _persist = (String tapDay) async {
          await prefs.setInt('tavsanfali_bugun_id', chosen['id'] as int);
          await prefs.setStringList('tavsanfali_gosterilen', updated);
          await prefs.setString('tavsanfali_bugun_tarih', tapDay);
        };
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
        _started = true;
        _ctrl.value = 1;
      } else {
        _idle.repeat(); // dokunuşu bekle
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
      // Zarflar masanın ön kenarına yakın (Anıl, 2026-11-06: "az daha yukarıda"; eski 0.76).
      final baseY = h * 0.70;

      Offset paperPos(int i) {
        final d = (i - 2).abs();
        return Offset(w / 2 + (i - 2) * spacing, baseY + (2 - d) * h * 0.012);
      }

      double paperRot(int i) => (i - 2) * 0.14;

      return AnimatedBuilder(
        animation: Listenable.merge([_ctrl, _idle, _card]),
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
          final card = _card.value;
          // Kapalı kartın kağıdı: tavşanın önünde, ayaklarının hizasında.
          final restW = pw * 1.5;
          final restH = restW * 206 / 240;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Tavşan (masanın arkasında)
              Positioned(
                left: rabCx - rabW / 2,
                top: rabBottom - rabH,
                width: rabW,
                height: rabH,
                child: GestureDetector(
                  key: const ValueKey('tavsan-kendisi'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _started ? null : () => _start(),
                  child: Transform.translate(
                  offset: Offset(rabDx, rabDy),
                  child: Transform.rotate(
                    angle: rabRot,
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: 1 + 0.06 * rabbitAmt,
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('assets/images/tavsanfali/tavsan.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                          // Göz kapakları: tavşanın kendi kürkünden üretilmiş kapalı göz katmanı
                          // (tools/tavsan_kapali_goz.py) yukarıdan aşağı iner.
                          RepaintBoundary(child: _BlinkLayer(anim: _blink)),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ),
              // Kağıtlar
              for (var i = 0; i < _kPapers; i++)
                if (i != _target || open < 1.0 && !_repeat)
                  _paper(i, tp, paperPos(i), paperRot(i), pw, ph, w, h, lift, fly, open),
              // Kart kapalıyken kağıt tavşanın önünde durur; dokununca kart yeniden açılır.
              if (done && card < 1)
                Positioned(
                  left: w / 2 - restW / 2,
                  top: rabBottom - restH * 0.55,
                  width: restW,
                  height: restH,
                  child: GestureDetector(
                    key: const ValueKey('tavsan-acik-kagit'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _openCard,
                    child: Opacity(
                      opacity: (1 - card).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.85 + 0.15 * (1 - card),
                        child: Image.asset('assets/images/tavsanfali/tavsan_kagit.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    ),
                  ),
                ),
              // Kart açıkken dışına dokunuş kapatır.
              if (done && card > 0 && _card.status != AnimationStatus.reverse)
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('tavsan-kart-disi'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeCard,
                  ),
                ),
              // Açılan not kartı
              if ((open > 0 || _repeat) && card > 0)
                Center(
                  child: GestureDetector(
                    onTap: () {}, // kartın kendisine dokunuş kapatmaz
                    child: Opacity(
                      opacity: (open * card).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scaleY: (0.02 + 0.98 * open) * (0.6 + 0.4 * card),
                        scaleX: (0.92 + 0.08 * open) * (0.6 + 0.4 * card),
                        child: _noteCard(cardW),
                      ),
                    ),
                  ),
                ),
              // Alt alan: durum yazısı → not (yüzen barın üstünde)
              Positioned(
                left: 20,
                right: 20,
                bottom: floatingBarInset(context),
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
    if (!_started) {
      // Bekleme dalgası: soldan sağa hafif kalkıp inme (±3 px) + çok az büyüme.
      final wave = math.sin(2 * math.pi * (_idle.value - i / _kPapers));
      y -= 3 * wave;
      scale = 1 + 0.025 * (wave + 1) / 2;
    }
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
      child: GestureDetector(
        key: ValueKey('tavsan-kagit-$i'),
        behavior: HitTestBehavior.opaque,
        onTap: _started ? null : () => _start(i),
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
      ),
    );
  }

  Widget _noteCard(double cardW) {
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
        !_started
            ? (isEn
                ? 'Tap a paper and the rabbit will pull it for you.'
                : 'Bir kağıda dokun, tavşan onu senin için çeksin.')
            : (isEn
                ? 'The rabbit is picking a paper for you...'
                : 'Tavşan senin için bir kağıt seçiyor...'),
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
      ],
    );
  }
}

/// Göz kırpma döngüsü: iki hızlı kırpış, sonra uzun bekleme (ms).
const int _kBlinkCycleMs = 4600;

/// Yalnız test/görsel doğrulama: göz kapağı kapanma oranını sabitle (0…1).
@visibleForTesting
double? debugTavsanBlink;

/// Döngüdeki [ms] anında göz kapağının kapanma oranı (0 açık … 1 kapalı).
double _blinkClosure(double ms) {
  double one(double t0) {
    final t = ms - t0;
    if (t < 0 || t > 150) return 0;
    if (t < 60) return Curves.easeIn.transform(t / 60); // kapanış
    return 1 - Curves.easeOut.transform((t - 60) / 90); // açılış
  }

  return math.max(one(0), one(230));
}

const String _kClosedEyes = 'assets/images/tavsanfali/tavsan_goz_kapali.png';

/// Göz kırpma katmanı: kapalı göz görseli, kapanma oranı kadar YUKARIDAN AŞAĞI açılır
/// (göz kapağı iner). Açıkken hiçbir şey çizmez.
class _BlinkLayer extends StatelessWidget {
  const _BlinkLayer({required this.anim});

  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final c = debugTavsanBlink ?? _blinkClosure(anim.value * _kBlinkCycleMs);
        if (c <= 0.001) return const SizedBox.expand();
        final clip = _LidClipper(c);
        return Stack(fit: StackFit.expand, children: [
          ClipPath(clipper: clip, child: child),
          // İnen kapağın kenarında kirpik çizgisi (kapalı görselin kendi kirpiği ~%58'de).
          if (c > 0.05 && c < 0.62) CustomPaint(painter: _LidEdgePainter(clip)),
        ]);
      },
      child: Image.asset(_kClosedEyes,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
    );
  }
}

class _LidEdgePainter extends CustomPainter {
  _LidEdgePainter(this.clip);

  final _LidClipper clip;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 505;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2 * k
      ..color = const Color(0xE63A1E42);
    for (final (ex, ey, rx, ry) in _LidClipper._eyes) {
      final r = Rect.fromCenter(
          center: Offset(ex * k, ey * k), width: rx * 2 * k * 0.86, height: (ry * 2 + 6) * k);
      final edge = r.top + r.height * clip.closure;
      final sag = r.height * 0.10 * clip.closure;
      canvas.drawPath(
          Path()
            ..moveTo(r.left, edge - sag)
            ..quadraticBezierTo(r.center.dx, edge + sag, r.right, edge - sag),
          p);
    }
  }

  @override
  bool shouldRepaint(_LidEdgePainter old) => old.clip.closure != clip.closure;
}

/// Her gözde üstten [closure] oranına kadar inen, alt kenarı hafif kavisli kapak bölgesi.
class _LidClipper extends CustomClipper<Path> {
  _LidClipper(this.closure);

  final double closure;

  // tools/tavsan_kapali_goz.py ile aynı elipsler (görsel pikseli, 505×640).
  static const _eyes = [
    (201.5, 240.5, 24.5, 27.0),
    (310.0, 240.5, 22.0, 27.0),
  ];

  @override
  Path getClip(Size size) {
    final k = size.width / 505;
    final path = Path();
    for (final (ex, ey, rx, ry) in _eyes) {
      final r = Rect.fromCenter(
          center: Offset(ex * k, ey * k), width: (rx * 2 + 6) * k, height: (ry * 2 + 6) * k);
      if (closure >= 0.999) {
        path.addRect(r);
        continue;
      }
      final edge = r.top + r.height * closure;
      final sag = r.height * 0.10 * closure;
      path
        ..moveTo(r.left, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, edge - sag)
        ..quadraticBezierTo(r.center.dx, edge + sag, r.left, edge - sag)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(_LidClipper old) => old.closure != closure;
}
