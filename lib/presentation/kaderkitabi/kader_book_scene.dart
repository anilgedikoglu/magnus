// lib/presentation/kaderkitabi/kader_book_scene.dart
//
// Kader Kitabı sahnesi (Anıl, 2026-11-06): koyu dalgalı gece denizinden eski, açık bir
// parşömen kitap yükselir — Hooop'ta engellerin sudan çıkışı gibi: suyun altından EĞİK çıkar,
// yükseldikçe düzleşip oturur, yüzeyi kırarken su sıçrar ve halkalar yayılır; üzerindeki
// damlalar kayarak denize akar, sayfalar kurur ve kaderin yazısı mürekkep gibi belirir.
//
// Zaman çizelgesi (_kRiseMs, 0..1):
//   0.00–0.12 kabarcıklar + halkalar (kitap altta)
//   0.08–0.42 yükseliş (eğik → düz, hafif taşma), 0.12'de yüzey kırılır: sıçrama + titreşim
//   0.30–0.86 damlalar sayfalardan kayıp denize düşer (iz bırakır), ıslaklık yukarıdan kurur
//   0.60–0.96 yazı: sol sayfa, sonra sağ sayfa; mürekkep yukarıdan aşağı belirir
// Sonra kitap dalgalarla hafifçe sallanır. Reduced-motion: doğrudan son hâl.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Parşömen görseli ve sayfa yazı alanları (görselin 0..1 koordinatında).
const String kKaderParchment = 'assets/images/kaderkitabi/parsomen.webp';
const double kKaderParchmentAspect = 1200 / 885; // en / boy (kırpılmış görsel)
// Yazı alanları: sayfaların yırtık kenarlarından ve cilt kıvrımından içeride.
const Rect kKaderLeftPage = Rect.fromLTRB(0.12, 0.105, 0.462, 0.85);
const Rect kKaderRightPage = Rect.fromLTRB(0.532, 0.105, 0.874, 0.85);

const int _kRiseMs = 6400;

/// Yalnız test/görsel doğrulama: zaman çizelgesini sabitle (0..1).
@visibleForTesting
double? debugKaderBookT;

class KaderBookScene extends StatefulWidget {
  const KaderBookScene({
    super.key,
    required this.leftText,
    required this.rightText,
    this.textScale = 1,
    this.animate = true,
    this.waterline = 0.72,
    this.onRisen,
    this.onTap,
    this.dropCap = true,
    this.showNextArrow = false,
  });

  /// Sonraki açılım varsa sağ sayfanın altında ok.
  final bool showNextArrow;

  /// Kitaba dokununca (metin iki sayfaya sığmıyorsa sonraki açılıma geç).
  final VoidCallback? onTap;

  /// Sol sayfanın ilk harfi büyük (yalnız ilk açılımda; sonraki sayfalarda düz).
  final bool dropCap;

  /// Sol ve sağ sayfaya yazılacak metin (bölme [splitKaderPages] ile).
  final String leftText;
  final String rightText;

  /// [splitKaderPages]'in seçtiği yazı ölçeği (uzun metin küçülür).
  final double textScale;

  /// false → kitap zaten yüzeyde (aynı gün tekrar açılış).
  final bool animate;

  /// Su çizgisi (sahne yüksekliğinin oranı).
  final double waterline;

  final VoidCallback? onRisen;

  @override
  State<KaderBookScene> createState() => _KaderBookSceneState();
}

class _KaderBookSceneState extends State<KaderBookScene> with TickerProviderStateMixin {
  late final AnimationController _rise =
      AnimationController(vsync: this, duration: const Duration(milliseconds: _kRiseMs));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  bool _splashed = false;
  bool _reduced = false;

  // Boşta sallanma ekran hızında değil ~30 Hz'de yenilenir (inceleme: okurken sahnenin
  // her karede yeniden çizilmesi pil/ısı).
  final ValueNotifier<double> _idleTick = ValueNotifier<double>(0);
  Duration _lastIdle = Duration.zero;

  // Kitap içeriği (parşömen + sayfalar + damlalar) yalnız yükseliş sürerken değişir.
  Widget? _bookCache;
  Object? _bookKey;

  @override
  void initState() {
    super.initState();
    _idle.addListener(() {
      final e = _idle.lastElapsedDuration ?? Duration.zero;
      if ((e - _lastIdle).abs() >= const Duration(milliseconds: 33)) {
        _lastIdle = e;
        _idleTick.value = _idle.value;
      }
    });
    _rise.addListener(() {
      if (!_splashed && _rise.value >= 0.12) {
        _splashed = true;
        HapticFeedback.lightImpact();
      }
    });
    _rise.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onRisen?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced != _reduced || (!_rise.isAnimating && _rise.value == 0)) {
      _reduced = reduced;
      if (!widget.animate || reduced) {
        _rise.value = 1;
        _splashed = true;
      } else if (_rise.value == 0) {
        _rise.forward();
      }
      if (reduced) {
        _idle.stop();
      } else if (!_idle.isAnimating) {
        _idle.repeat();
      }
    }
  }

  @override
  void dispose() {
    _rise.dispose();
    _idle.dispose();
    _idleTick.dispose();
    super.dispose();
  }

  static double _seg(double t, double a, double b, [Curve c = Curves.linear]) =>
      c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  Widget _bookFor(double t, double bookW, double bookH) {
    final key = (t, bookW, bookH, widget.leftText, widget.rightText, widget.textScale, widget.dropCap, widget.showNextArrow);
    if (_bookCache != null && _bookKey == key) return _bookCache!;
    final wet = 1 - _seg(t, 0.34, 0.86, Curves.easeInOut); // 1 ıslak … 0 kuru
    final leftInk = _seg(t, 0.60, 0.80, Curves.easeInOut);
    final rightInk = _seg(t, 0.74, 0.96, Curves.easeInOut);

    final book = RepaintBoundary(child: SizedBox(
      width: bookW,
      height: bookH,
      child: Stack(fit: StackFit.expand, children: [
        // Görsel stüdyo ışığında; gece denizine uysun diye karartılıp soğutulur.
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.80, 0, 0, 0, 0, //
            0, 0.76, 0, 0, 0, //
            0, 0, 0.86, 0, 8, //
            0, 0, 0, 1, 0,
          ]),
          child: Image.asset(kKaderParchment,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const _FallbackParchment()),
        ),
        // Ay ışığı: üstten soğuk, kenarlarda karanlık (sahneye oturtur).
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.35),
                radius: 0.95,
                colors: [Color(0x00000000), Color(0x3A0A0620), Color(0x8A05030F)],
                stops: [0.45, 0.8, 1.0],
              ),
            ),
          ),
        ),
        // Islaklık: koyu, soğuk ton; yukarıdan aşağı kurur.
        if (wet > 0.001)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A1630).withValues(alpha: 0.42 * wet * wet),
                    const Color(0xFF0A1630).withValues(alpha: 0.46 * wet),
                  ],
                ),
              ),
            ),
          ),
        _page(kKaderLeftPage, bookW, bookH, widget.leftText, leftInk, dropCap: widget.dropCap),
        _page(kKaderRightPage, bookW, bookH, widget.rightText, rightInk),
        if (widget.showNextArrow)
          Positioned(
            key: const ValueKey('kaderNextArrow'),
            // Sağ sayfanın son satır yeri (paginateKaderPages o satırı boş bırakır).
            left: kKaderRightPage.right * bookW - bookW * 0.105,
            top: kKaderRightPage.bottom * bookH - bookW * 0.05,
            width: bookW * 0.105,
            height: bookW * 0.05,
            child: IgnorePointer(
              child: Opacity(
                opacity: rightInk,
                child: const CustomPaint(painter: _NextArrowPainter()),
              ),
            ),
          ),
        IgnorePointer(
          child: CustomPaint(painter: _DropsPainter(t: t, seed: 11)),
        ),
      ]),
    ));
    _bookKey = key;
    return _bookCache = book;
  }

  @override
  Widget build(BuildContext context) {
    final scene = LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final bookW = math.min(w * 0.94, 560.0);
      final bookH = bookW / kKaderParchmentAspect;
      final water = h * widget.waterline;
      return AnimatedBuilder(
        animation: Listenable.merge([_rise, _idleTick]),
        builder: (context, _) {
          final t = debugKaderBookT ?? _rise.value;
          final idle = _idleTick.value * 2 * math.pi;
          // Yükseliş: suyun altından (tamamen batık) → son yer (alt %7'si suda).
          final up = _seg(t, 0.08, 0.42, const _RiseCurve());
          final restTop = water - bookH * 0.93;
          final sunkTop = water + bookH * 0.06;
          final bob = (t >= 0.42 ? 1.0 : _seg(t, 0.30, 0.42)) * 3.0 * math.sin(idle);
          final top = sunkTop + (restTop - sunkTop) * up + bob;
          // Anıl (2026-11-06): kitap sudan DÜZ çıksın (eski "eğik çıkıp düzelme" kaldırıldı).
          // Yalnız oturduktan sonra çok hafif, göze çarpmayan bir salınım kalır.
          final tilt = t >= 0.42 ? 0.010 * math.sin(idle + 1.1) : 0.0;
          final left = (w - bookW) / 2;
          final waterInBook = water - top; // kitap yerel koordinatında su çizgisi
          final phase = idle;
          final book = _bookFor(t, bookW, bookH);

          return Stack(clipBehavior: Clip.none, children: [
            // Kabarcıklar + halkalar (kitabın arkasında, su yüzeyinde)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WaterFxPainter(
                    t: t,
                    phase: phase,
                    water: water,
                    cx: w / 2,
                    bookW: bookW,
                  ),
                ),
              ),
            ),
            // Suya düşen yansıma: kitabın ayna görüntüsü, dalgalı, soluk, derine doğru söner
            // (Grok: kitap havada asılı gibiydi; alt boş deniz de dolsun).
            if (up > 0.2)
              Positioned(
                left: left,
                top: water,
                width: bookW,
                height: bookH * 0.62,
                child: IgnorePointer(
                  child: ClipRect(
                    child: Opacity(
                      opacity: (0.40 * ((up - 0.2) / 0.8)).clamp(0.0, 0.40),
                      // Su yansıması bulanık: içindeki ters yazı okunmasın.
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 1.6, sigmaY: 3.2),
                        child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (b) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                        ).createShader(b),
                        child: ColorFiltered(
                          colorFilter:
                              const ColorFilter.mode(Color(0xFF8AA6DA), BlendMode.modulate),
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minHeight: bookH,
                            maxHeight: bookH,
                            child: Transform.translate(
                              offset: Offset(
                                  2.5 * math.sin(phase), water - top - bookH),
                              child: Transform.flip(flipY: true, child: book),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            // Kitap: suyun üstü net, altı soluk ve mavi (su içinden görünür)
            Positioned(
              left: left,
              top: top,
              width: bookW,
              height: bookH,
              // Hafif perspektif: kitap denize doğru geriye yatık (deniz göz hizasından görülüyor).
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0011)
                  ..rotateX(0.32)
                  ..rotateZ(tilt),
                child: Stack(fit: StackFit.expand, children: [
                  // Suyun altındaki kısım: soluk, mavi ve derine doğru kaybolur.
                  ClipPath(
                    clipper: _WaterClip(waterInBook, phase, below: true),
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (b) {
                        final wf = (waterInBook / bookH).clamp(0.0, 1.0);
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [Colors.white, Colors.transparent],
                          stops: [wf, (wf + 0.22).clamp(0.0, 1.0)],
                        ).createShader(b);
                      },
                      child: Opacity(
                        opacity: 0.30,
                        child: ColorFiltered(
                          colorFilter:
                              const ColorFilter.mode(Color(0xFF3C6AA8), BlendMode.modulate),
                          child: book,
                        ),
                      ),
                    ),
                  ),
                  ClipPath(clipper: _WaterClip(waterInBook, phase, below: false), child: book),
                ]),
              ),
            ),
            // Sıçrama (önde)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SprayPainter(t: t, water: water, cx: w / 2, bookW: bookW),
                ),
              ),
            ),
          ]);
        },
      );
    });
    if (widget.onTap == null) return scene;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: scene);
  }

  Widget _page(Rect r, double bw, double bh, String text, double ink, {bool dropCap = false}) {
    final rect = Rect.fromLTRB(r.left * bw, r.top * bh, r.right * bw, r.bottom * bh);
    final style = kaderPageStyle(rect.size, scale: widget.textScale);
    Widget body = _PageText(text: text, style: style, dropCap: dropCap);
    if (ink < 1) {
      // Mürekkep yukarıdan aşağı belirir (yumuşak kenarlı süpürme).
      body = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (b) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.white, Colors.white, Colors.transparent, Colors.transparent],
          stops: [0, (ink * 1.25 - 0.18).clamp(0.0, 1.0), (ink * 1.25).clamp(0.0, 1.0), 1],
        ).createShader(b),
        child: body,
      );
    }
    return Positioned.fromRect(rect: rect, child: ink <= 0 ? const SizedBox() : body);
  }
}

/// Sayfa yazısının stili (sayfa alanına göre ölçeklenir).
TextStyle kaderPageStyle(Size page, {double scale = 1}) => GoogleFonts.raleway(
      fontSize: (page.width * 0.095).clamp(10.0, 15.0) * scale,
      height: 1.32,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF2A1808),
    );

/// Metni iki sayfaya DENGELİ böler (satır sayısı yarı yarıya, kelime sınırında; kısa metinde
/// de sağ sayfa boş kalmaz). Sığmazsa yazı küçülür. Dönen: (sol, sağ, ölçek).
(String, String, double) splitKaderPages(String text, Size page, TextScaler scaler) {
  for (var scale = 1.0; scale >= 0.6; scale -= 0.05) {
    final style = kaderPageStyle(page, scale: scale);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: page.width);
    final lines = tp.computeLineMetrics();
    if (lines.isEmpty) {
      tp.dispose();
      return (text, '', scale);
    }
    final lineH = lines.first.height;
    // Sol sayfada büyük ilk harf bir satır kadar yer yer.
    final perPage = (page.height / lineH).floor();
    if (lines.length > perPage * 2 - 1) {
      tp.dispose();
      continue;
    }
    if (lines.length < 2) {
      tp.dispose();
      return (text, '', scale);
    }
    // Sol sayfada büyük ilk harf ilk satırı uzatır ve satır kaydırabilir: bir satır pay.
    final leftLines = math.min((lines.length / 2).ceil(), perPage - 1);
    final y = lines[leftLines - 1].baseline - lineH * 0.3;
    var cut = tp.getLineBoundary(tp.getPositionForOffset(Offset(page.width - 1, y))).end;
    tp.dispose();
    cut = cut.clamp(1, text.length - 1);
    while (cut > 0 && text[cut - 1] != ' ' && text[cut] != ' ') {
      cut--;
    }
    if (cut <= 0) return (text, '', scale);
    return (text.substring(0, cut).trimRight(), text.substring(cut).trimLeft(), scale);
  }
  final mid = text.lastIndexOf(' ', text.length ~/ 2);
  if (mid <= 0) {
    // Boşluksuz metin (Codex bulgusu: substring(0, -1) → RangeError): harf sınırında ortadan böl.
    final chars = text.characters;
    final half = chars.length ~/ 2;
    return (chars.take(half).toString(), chars.skip(half).toString(), 0.6);
  }
  return (text.substring(0, mid), text.substring(mid + 1), 0.6);
}

/// Bir sayfaya SIĞAN kadar metni (en fazla [maxLines] satır) kelime sınırında keser.
/// Dönen: (sayfaya sığan, kalan). Kalan boşsa tek sayfaya sığmıştır.
(String, String) _kaderCutPage(
    String text, Size page, TextStyle style, TextScaler scaler, int maxLines) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout(maxWidth: page.width);
  final lines = tp.computeLineMetrics();
  if (lines.length <= maxLines) {
    tp.dispose();
    return (text, '');
  }
  final lineH = lines.first.height;
  final y = lines[maxLines - 1].baseline - lineH * 0.3;
  var cut = tp.getLineBoundary(tp.getPositionForOffset(Offset(page.width - 1, y))).end;
  tp.dispose();
  cut = cut.clamp(1, text.length - 1);
  while (cut > 0 && text[cut - 1] != ' ' && text[cut] != ' ') {
    cut--;
  }
  if (cut <= 0) {
    // Boşluksuz uzun metin: harf sınırında yarıdan böl (RangeError olmasın).
    final chars = text.characters;
    final half = (chars.length / 2).ceil().clamp(1, chars.length - 1);
    return (chars.take(half).toString(), chars.skip(half).toString());
  }
  return (text.substring(0, cut).trimRight(), text.substring(cut).trimLeft());
}

/// Uzun metni, her biri iki sayfaya (sol+sağ) KÜÇÜLTMEDEN sığan "açılımlara" böler.
/// Metin iki sayfaya sığıyorsa [splitKaderPages] dengeli tek açılım verir; buraya yalnız
/// sığmayan metinler gelir → sayfalanır, kullanıcı dokununca sıradaki açılıma geçer (Anıl).
/// İlk açılımın sol sayfasında büyük ilk harf için bir satır pay bırakılır.
List<(String, String)> paginateKaderPages(String text, Size page, TextScaler scaler) {
  final style = kaderPageStyle(page);
  final probe = TextPainter(
    text: TextSpan(text: 'Xy', style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final perPage = (page.height / probe.preferredLineHeight).floor().clamp(1, 999);
  probe.dispose();

  final spreads = <(String, String)>[];
  var rest = text.trim();
  var first = true;
  for (var guard = 0; guard < 60 && rest.isNotEmpty; guard++) {
    final leftCap = first ? math.max(1, perPage - 1) : perPage;
    final (left, afterLeft) = _kaderCutPage(rest, page, style, scaler, leftCap);
    final (right, afterRight) =
        afterLeft.isEmpty
            ? ('', '')
            : _kaderCutPage(afterLeft, page, style, scaler, math.max(1, perPage - 1)); // son satır: ok yeri
    spreads.add((left, right));
    rest = afterRight;
    first = false;
  }
  if (spreads.isEmpty) spreads.add((text, ''));
  return spreads;
}

/// Parşömene kalemle çizilmiş gibi sağ ok.
class _NextArrowPainter extends CustomPainter {
  const _NextArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = const Color(0xFF2A1808).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, h * 0.09)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.02, h * 0.54)
        ..quadraticBezierTo(w * 0.5, h * 0.46, w * 0.96, h * 0.5)
        ..moveTo(w * 0.66, h * 0.08)
        ..lineTo(w * 0.97, h * 0.5)
        ..lineTo(w * 0.64, h * 0.94),
      p,
    );
  }

  @override
  bool shouldRepaint(_NextArrowPainter old) => false;
}

class _PageText extends StatelessWidget {
  const _PageText({required this.text, required this.style, required this.dropCap});
  final String text;
  final TextStyle style;
  final bool dropCap;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();
    if (!dropCap) return Text(text, style: style, textAlign: TextAlign.start);
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: text.characters.first,
          style: GoogleFonts.cinzel(
            fontSize: style.fontSize! * 1.9,
            height: 1.0,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B1D1D),
          ),
        ),
        TextSpan(text: text.characters.skip(1).toString(), style: style),
      ]),
      textAlign: TextAlign.start,
    );
  }
}

/// Parşömen görseli yoksa sade bir yedek.
class _FallbackParchment extends StatelessWidget {
  const _FallbackParchment();
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [Color(0xFFEFDDB4), Color(0xFFE2C995)]),
        ),
      );
}

/// Yükseliş eğrisi: hızlı çıkış, %4 taşma, yerine oturma.
class _RiseCurve extends Curve {
  const _RiseCurve();
  @override
  double transformInternal(double t) {
    final e = 1 - math.pow(1 - t, 3).toDouble();
    return e + 0.04 * math.sin(math.pi * t) * (1 - t) * 2.2;
  }
}

/// Su çizgisinin üstü / altı (dalgalı).
class _WaterClip extends CustomClipper<Path> {
  _WaterClip(this.y, this.phase, {required this.below});
  final double y;
  final double phase;
  final bool below;

  @override
  Path getClip(Size size) {
    final p = Path();
    double wave(double x) => y + 2.4 * math.sin(x / 38 + phase) + 1.2 * math.sin(x / 17 - phase * 2);
    if (below) {
      p.moveTo(0, size.height + 40);
      p.lineTo(0, wave(0));
      for (double x = 0; x <= size.width; x += 6) {
        p.lineTo(x, wave(x));
      }
      p.lineTo(size.width, size.height + 40);
    } else {
      p.moveTo(-40, -200);
      p.lineTo(size.width + 40, -200);
      p.lineTo(size.width + 40, wave(size.width));
      for (double x = size.width; x >= 0; x -= 6) {
        p.lineTo(x, wave(x));
      }
      p.lineTo(-40, wave(0));
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_WaterClip old) => old.y != y || old.phase != phase || old.below != below;
}

/// Kabarcıklar (yükselişten önce) ve su çizgisinde yayılan halkalar.
class _WaterFxPainter extends CustomPainter {
  _WaterFxPainter(
      {required this.t, required this.phase, required this.water, required this.cx, required this.bookW});
  final double t, phase, water, cx, bookW;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(5);
    // Kabarcıklar: 0–0.16
    if (t < 0.18) {
      for (var i = 0; i < 18; i++) {
        final x0 = cx + (rnd.nextDouble() - 0.5) * bookW * 0.8;
        final st = rnd.nextDouble() * 0.10;
        final u = ((t - st) / 0.08).clamp(0.0, 1.0);
        if (u <= 0 || u >= 1) continue;
        final y = water + 30 - u * 30;
        final x = x0 + math.sin(u * 9 + i) * 3;
        final r = 1.5 + rnd.nextDouble() * 2.5;
        canvas.drawCircle(Offset(x, y), r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color(0xFFBFE6FF).withValues(alpha: 0.6 * (1 - u)));
      }
    }
    // Halkalar: yüzey kırılınca (0.12) 3 dalga, sonra sakin dalgalanma
    for (var k = 0; k < 3; k++) {
      final st = 0.12 + k * 0.05;
      final u = ((t - st) / 0.30).clamp(0.0, 1.0);
      if (u <= 0 || u >= 1) continue;
      final rx = bookW * (0.45 + 0.55 * u);
      final ry = rx * 0.10;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, water + 2), width: rx * 2, height: ry * 2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 * (1 - u) + 0.4
            ..color = const Color(0xFFD9F1FF).withValues(alpha: 0.55 * (1 - u)));
    }
    // Kitabın çevresinde sürekli ince köpük çizgisi (yüzeydeyken)
    if (t > 0.3) {
      final a = ((t - 0.3) / 0.2).clamp(0.0, 1.0);
      final path = Path();
      for (double x = -bookW * 0.52; x <= bookW * 0.52; x += 5) {
        final y = water + 1.5 + 1.5 * math.sin(x / 14 + phase * 2);
        x == -bookW * 0.52 ? path.moveTo(cx + x, y) : path.lineTo(cx + x, y);
      }
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFFE6F6FF).withValues(alpha: 0.30 * a));
    }
  }

  @override
  bool shouldRepaint(_WaterFxPainter old) => old.t != t || old.phase != phase || old.water != water;
}

/// Yüzey kırılırken fırlayan su damlacıkları (yerçekimiyle düşer).
class _SprayPainter extends CustomPainter {
  _SprayPainter({required this.t, required this.water, required this.cx, required this.bookW});
  final double t, water, cx, bookW;

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0.12 || t > 0.40) return;
    final rnd = math.Random(9);
    final secs = (t - 0.12) * _kRiseMs / 1000;
    for (var i = 0; i < 26; i++) {
      // Çoğu kitabın iki yanından (yüzeyi yaran kenarlar), azı önden ve alçak.
      final side = i % 5 == 0 ? 0.0 : (i.isEven ? 1.0 : -1.0);
      final x0 = side == 0
          ? cx + (rnd.nextDouble() - 0.5) * bookW * 0.8
          : cx + side * bookW * (0.44 + rnd.nextDouble() * 0.12);
      final vx = side * (40 + rnd.nextDouble() * 110) + (rnd.nextDouble() - 0.5) * 30;
      final vy = -(side == 0 ? 90 + rnd.nextDouble() * 90 : 170 + rnd.nextDouble() * 230);
      final delay = rnd.nextDouble() * 0.25;
      final s = secs - delay;
      if (s <= 0) continue;
      final x = x0 + vx * s;
      final y = water + vy * s + 0.5 * 900 * s * s;
      if (y > water + 4) continue;
      final r = 0.9 + rnd.nextDouble() * 1.8;
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = const Color(0xFFE2F4FF).withValues(alpha: 0.45 + rnd.nextDouble() * 0.35));
    }
  }

  @override
  bool shouldRepaint(_SprayPainter old) => old.t != t;
}

/// Sayfalardan kayan damlalar: yapışıp kayar (dur-kalk), arkasında ıslak iz bırakır, alt
/// kenardan denize düşer.
class _DropsPainter extends CustomPainter {
  _DropsPainter({required this.t, required this.seed});
  final double t;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0.28 || t > 0.92) return;
    final rnd = math.Random(seed);
    for (var i = 0; i < 18; i++) {
      final x = size.width * (0.08 + rnd.nextDouble() * 0.84);
      final y0 = size.height * (0.05 + rnd.nextDouble() * 0.45);
      final st = 0.28 + rnd.nextDouble() * 0.30;
      final dur = 0.20 + rnd.nextDouble() * 0.16;
      final u = ((t - st) / dur).clamp(0.0, 1.0);
      if (u <= 0) continue;
      // Dur-kalk: kademeli hızlanma + küçük takılmalar.
      final stick = 0.06 * math.sin(u * 18 + i);
      final p = (u * u * (1.6 - 0.6 * u) + stick * u * (1 - u)).clamp(0.0, 1.0);
      final y = y0 + (size.height * 1.02 - y0) * p;
      final r = size.width * (0.006 + rnd.nextDouble() * 0.006);
      final wobble = math.sin(u * 7 + i * 2) * r * 0.8;
      // Islak iz
      if (y > y0 + 2) {
        canvas.drawLine(
          Offset(x, y0),
          Offset(x + wobble, y - r),
          Paint()
            ..strokeWidth = r * 0.9
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x00203A5A),
                const Color(0xFF203A5A).withValues(alpha: 0.28 * (1 - u * 0.6)),
              ],
            ).createShader(Rect.fromPoints(Offset(x, y0), Offset(x + 1, y))),
        );
      }
      if (u >= 1) continue;
      // Damla: koyu gövde + parlak nokta (ışığı yakalar)
      final c = Offset(x + wobble, y);
      canvas.drawOval(Rect.fromCenter(center: c, width: r * 2, height: r * 2.5),
          Paint()..color = const Color(0xFF1E3550).withValues(alpha: 0.55));
      canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.45), r * 0.38,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85));
    }
  }

  @override
  bool shouldRepaint(_DropsPainter old) => old.t != t;
}
