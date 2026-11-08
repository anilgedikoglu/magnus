// lib/presentation/home/home_chat_box.dart
//
// Ana menünün üstündeki Magnus sohbet kutusu (Anıl, 2026-11-08): alt barla aynı biçim ve aynı cam.
// Kaydırma, üstten inme, 3 satır yok; tek mesaj görünür.
//
// Yazı efekti Anıl'ın ekran kaydından ölçüldü (60 fps, 411 kare):
//   • Döngü 1,5 sn: karartma soldan sağa geçer, sonra yazı kısa süre tam parlak kalır.
//   • Geçiş döngünün ilk %62'si; en koyu yerde parlaklık %25; karartma yarı eni yazı eninin %47'si.
//   • Yazı değişimi geçişsiz, tek karede; yeni yazı 1,1 sn sonra ilk taramasına başlar.
//
// İki satıra sığmayan mesaj cümle cümle sayfalanır; sayfalar sırayla değişir, yazı kesilmez.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/glass_tab_bar.dart' show kGlassBarHeight;
import '../../core/widgets/liquid_glass_panel.dart';

const Duration _kSweepPeriod = Duration(milliseconds: 1500);
const Duration _kSweepDelay = Duration(milliseconds: 1100);
const double _kSweepActive = 0.62;
const double _kBandHalf = 0.47;
const Color _kBandDim = Color(0x40FFFFFF);

/// Dış yazı, kutu boyunu aşmasın diye en çok bu orana kadar büyür.
const double _kMaxTextScale = 1.3;

/// Bir yazının ekranda kalma süresi: okumaya yetecek kadar.
Duration chatPageDwell(String text) =>
    Duration(milliseconds: (text.length * 65).clamp(3500, 7000));

/// Metni, [fits] doğru dönen sayfalara böler: önce cümle sınırından, tek cümle sığmıyorsa kelimeden.
List<String> paginateChatText(String text, bool Function(String) fits) {
  final whole = text.trim();
  if (whole.isEmpty || fits(whole)) return whole.isEmpty ? const [] : [whole];
  final pages = <String>[];
  var cur = '';
  void add(String piece) {
    final joined = cur.isEmpty ? piece : '$cur $piece';
    if (fits(joined)) {
      cur = joined;
    } else {
      if (cur.isNotEmpty) pages.add(cur);
      cur = piece;
    }
  }

  for (final sentence in whole.split(RegExp(r'(?<=[.!?…])\s+'))) {
    if (fits(sentence)) {
      add(sentence);
    } else {
      sentence.split(RegExp(r'\s+')).forEach(add);
    }
  }
  if (cur.isNotEmpty) pages.add(cur);
  return pages;
}

class HomeChatBox extends StatefulWidget {
  const HomeChatBox({super.key, required this.tint});

  /// Alt barla aynı saydamlık ayarı (Ayarlar > CAM).
  final double tint;

  @override
  State<HomeChatBox> createState() => HomeChatBoxState();
}

class HomeChatBoxState extends State<HomeChatBox> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;
  final List<String> _queue = [];
  String? _message;
  List<String> _pages = const [];
  int _page = 0;
  double _width = 0;
  TextScaler? _scaler;
  bool _holding = false;
  bool _readOnce = false; // eldeki mesajın tüm sayfaları en az bir kez gösterildi
  bool _reduce = false;
  Timer? _dwell;
  Timer? _sweepStart;

  static final TextStyle _style = AppTextStyles.uiLabel.copyWith(
    fontSize: 14.5,
    height: 1.25,
    letterSpacing: 0.1,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(vsync: this, duration: _kSweepPeriod, value: 1);
  }

  /// Yeni mesaj: kutu boşsa ya da eldeki yazı yeterince kaldıysa hemen, değilse sırayla.
  /// [now]: dokunuşa cevap, eldeki yazıyı beklemeden değiştirir.
  void say(String text, {bool now = false}) {
    final t = text.trim();
    if (t.isEmpty) return;
    if (now) {
      if (t == _message) {
        _startPage(); // aynı cevap tekrar: yalnız süre ve tarama baştan
        return;
      }
      _dwell?.cancel();
      _holding = false;
      _queue.insert(0, t);
    } else {
      _queue.add(t);
    }
    _next();
  }

  /// Kutuyu boşaltır (dil değişince eski dilde yazı kalmasın).
  void clear() {
    _dwell?.cancel();
    _sweepStart?.cancel();
    _sweep
      ..stop()
      ..value = 1;
    _queue.clear();
    _holding = false;
    if (!mounted) return;
    setState(() {
      _message = null;
      _pages = const [];
      _page = 0;
      _readOnce = false;
    });
  }

  void _next() {
    if (_holding || _queue.isEmpty || !mounted) return;
    final m = _queue.removeAt(0);
    setState(() {
      _message = m;
      _pages = _paginate(m);
      _page = 0;
      _readOnce = false;
    });
    _startPage();
  }

  void _startPage() {
    _holding = true;
    _restartSweep();
    _dwell?.cancel();
    final text = _page < _pages.length ? _pages[_page] : (_message ?? '');
    _dwell = Timer(chatPageDwell(text), _onDwellEnd);
  }

  void _onDwellEnd() {
    if (!mounted) return;
    _holding = false;
    final last = _page >= _pages.length - 1;
    if (last) _readOnce = true;
    if (_queue.isNotEmpty && _readOnce) {
      _next(); // bir kez tamamı okunduysa sıradaki beklemez
    } else if (!last) {
      setState(() => _page++);
      _startPage();
    } else if (_pages.length > 1) {
      setState(() => _page = 0); // uzun mesaj bütün kalsın: başa döner
      _startPage();
    }
  }

  void _restartSweep() {
    _sweepStart?.cancel();
    _sweep
      ..stop()
      ..value = 1;
    if (_reduce) return;
    _sweepStart = Timer(_kSweepDelay, () {
      if (!mounted) return;
      _sweep
        ..value = 0
        ..repeat();
    });
  }

  List<String> _paginate(String text) {
    if (_width <= 0) return [text];
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: _kMaxTextScale);
    final dir = Directionality.of(context);
    bool fits(String s) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: _style),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 2,
      )..layout(maxWidth: _width);
      final ok = !tp.didExceedMaxLines;
      tp.dispose();
      return ok;
    }

    final pages = paginateChatText(text, fits);
    return pages.isEmpty ? [text] : pages;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reduce) {
      _reduce = reduce;
      if (_message != null) _restartSweep();
    }
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _sweepStart?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  void _measure(double width, TextScaler scaler) {
    if (width == _width && scaler == _scaler) return;
    _width = width;
    _scaler = scaler;
    final m = _message;
    if (m == null) return;
    _pages = _paginate(m);
    _page = math.min(_page, _pages.length - 1);
  }

  /// Karartmanın merkezi (yazı enine oranla); döngünün boş kısmında yazının çok dışında.
  static double _bandCenter(double p) => p >= _kSweepActive
      ? 2 + _kBandHalf
      : -_kBandHalf + (1 + 2 * _kBandHalf) * (p / _kSweepActive);

  Shader _bandShader(Rect r) {
    final c = _bandCenter(_sweep.value);
    return ui.Gradient.linear(
      Offset(r.left + (c - _kBandHalf) * r.width, 0),
      Offset(r.left + (c + _kBandHalf) * r.width, 0),
      const [Colors.white, _kBandDim, Colors.white],
      const [0, 0.5, 1],
    );
  }

  Widget _text(String text) => Semantics(
        liveRegion: true,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _sweep,
            builder: (context, child) => ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: _bandShader,
              child: child,
            ),
            child: Text(
              text,
              key: const ValueKey('homeChatText'),
              style: _style,
              maxLines: 2,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _kMaxTextScale,
      child: GestureDetector(
        // Kutuya dokunuş altındaki kartı açmasın.
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () {},
        child: LiquidGlassPanel(
          key: const ValueKey('homeChatBox'),
          barOptics: true,
          radius: kGlassBarHeight / 2,
          tint: widget.tint,
          padding: const EdgeInsets.only(left: 11, right: 20),
          child: SizedBox.expand(
            child: Row(
              children: [
                const _MagnusAvatar(),
                const SizedBox(width: 11),
                Expanded(
                  child: LayoutBuilder(builder: (context, box) {
                    _measure(box.maxWidth, scaler);
                    final hasText = _message != null && _pages.isNotEmpty;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: hasText ? _text(_pages[_page]) : const SizedBox.shrink(),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MagnusAvatar extends StatelessWidget {
  const _MagnusAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFAA88FF), width: 1.0),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/magnusicon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.inkCard,
            alignment: Alignment.center,
            child: const Text(
              'M',
              style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
