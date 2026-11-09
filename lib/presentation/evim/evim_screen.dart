// "Evim Neresi?" falı (2026-11-05). Mantık: lib/data/services/ev_engine.dart.
// Akış: (ilk kullanımda bir kez) "Şu an hangi ilde yaşıyorsun?" → yıl seç (bu yıl ortada, geçmiş yok,
// sola kaydır → +50) → kısa hesaplama → sonuç: yer, ev tipi, denize mesafe, durum, kullanım, (varsa) yazlık
// + kısa bir anlatı. Kapalı kutu: ödüllü reklam teklifi (kullanıcı seçerse) → o dönemin tüm kutuları açılır, KALICI;
// reklam yoksa / sınır doluysa / yönetici modunda ücretsiz açılır.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/blur_reveal_spinner.dart';
import '../../core/widgets/unlock_flash.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/ad_pacing.dart';
import '../../core/services/ad_service.dart';
import '../../core/widgets/odul_teklifi.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../core/widgets/hold_to_reveal.dart';
import '../../core/widgets/liquid_glass_panel.dart';
import '../../core/widgets/marquee_text.dart';
import '../../data/providers.dart';
import '../../data/services/ev_engine.dart';

enum _Adim { yukleniyor, il, secim, hesap, sonuc }

final _kEvGorselleri = [
  for (var i = 1; i <= 16; i++) 'assets/images/evim/ev_${i.toString().padLeft(2, '0')}.jpg',
];

class EvimScreen extends ConsumerStatefulWidget {
  const EvimScreen({super.key});

  @override
  ConsumerState<EvimScreen> createState() => _EvimScreenState();
}

class _EvimScreenState extends ConsumerState<EvimScreen> {
  static const _pink = Color(0xFFFF55FF);
  static const _purple = Color(0xFF8B5CF6);

  _Adim _adim = _Adim.yukleniyor;
  EvimData? _data;
  EvimTimeline? _t;
  SharedPreferences? _prefs;
  String? _il; // kayıtlı / seçilen yaşadığı il
  String? _ilSecili; // il listesinde işaretli
  late final int _base = DateTime.now().year;
  late int _year = _base;
  final _yearCtrl = FixedExtentScrollController();
  final _ilCtrl = ScrollController();
  static const double _ilItemH = 42;
  static const double _yearItemW = 82;
  static const double _yearDiameter = 1.5; // tekerleğin eğriliği (çizim de bunu kullanır)
  final Set<String> _opening = {};

  bool get _en => ref.read(localeProvider) == 'en';
  String _tr(String tr, String en) => _en ? en : tr;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await rootBundle.loadString('assets/data/evim.json');
    final data = EvimData.parse(raw);
    if (!mounted) return;
    _prefs = prefs;
    _data = data;
    final profile = ref.read(userProfileProvider);
    final fallback = data.matchIl(profile.birthCity) ?? 'İstanbul';
    final asked = prefs.getBool(EvimEngine.prefsAskedKey) ?? false;
    final stored = EvimEngine.storedIl(prefs, data);
    if (!asked) {
      setState(() {
        _ilSecili = fallback;
        _adim = _Adim.il;
      });
      _ilSeciliyeKaydir();
      return;
    }
    await _useIl(stored ?? fallback);
  }

  Future<void> _useIl(String il) async {
    final prefs = _prefs, data = _data;
    if (prefs == null || data == null || !mounted) return;
    final profile = ref.read(userProfileProvider); // await'ten ÖNCE
    final t = await EvimEngine.load(prefs, data, profile, il);
    if (!mounted) return;
    setState(() {
      _il = il;
      _t = t;
      _adim = _Adim.secim;
    });
  }

  Future<void> _ilKaydet(String il) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await EvimEngine.saveIl(prefs, il);
    await _useIl(il);
  }

  void _ilDegistir() {
    setState(() {
      _ilSecili = _il;
      _adim = _Adim.il;
    });
    _ilSeciliyeKaydir();
  }

  List<String> _sortedIller(EvimData data) =>
      [...data.iller]..sort((a, b) => EvimData.fold(a).compareTo(EvimData.fold(b)));

  /// İl listesi açılınca işaretli il ortada görünsün (liste başta kalmasın).
  void _ilSeciliyeKaydir() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = _data, sel = _ilSecili;
      if (!mounted || data == null || sel == null || !_ilCtrl.hasClients) return;
      final i = _sortedIller(data).indexOf(sel);
      if (i < 0) return;
      final target = (i * _ilItemH - (_ilCtrl.position.viewportDimension - _ilItemH) / 2)
          .clamp(0.0, _ilCtrl.position.maxScrollExtent);
      _ilCtrl.jumpTo(target);
    });
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _ilCtrl.dispose();
    super.dispose();
  }

  void _goster() {
    HapticFeedback.mediumImpact();
    // Sonuç zaten _useIl()'de hesaplandı (_t). Bekleme süresi BlurRevealSpinner'a ait.
    setState(() => _adim = _Adim.hesap);
  }

  void _hesapBitti() {
    if (!mounted || _adim != _Adim.hesap) return;
    setState(() => _adim = _Adim.sonuc);
  }

  bool _teklifte = false; // teklif penceresi / reklam sürerken ikinci dokunuş yok

  Future<void> _ac(EvimSegment s, String field) async {
    final t = _t, prefs = _prefs;
    final key = '${s.id}:$field';
    if (t == null || prefs == null || t.isRevealed(s.id, field) || _opening.contains(key) || _teklifte) return;
    _teklifte = true;
    try {
      // Ödül mümkünse teklif; değilse (reklam yok / sınır dolu) kutu ücretsiz açılır.
      var ac = true;
      await AdService.instance.odulluBekle();
      if (!mounted) return;
      if (AdService.instance.odulMumkun(OdulTuru.kutuAc)) {
        ac = await ref.kutuAcTeklifi(context, ref.read(l10nProvider).adOpenBoxPeriodBody);
      }
      if (!ac || !mounted) return;
      setState(() => _opening.add(key));
      for (final f in s.fields) {
        if (!t.isRevealed(s.id, f)) await EvimEngine.reveal(prefs, t, s.id, f);
      }
    } catch (_) {
      // Açılış hatası kutuyu bekleme halinde bırakmaz.
    } finally {
      _teklifte = false;
      if (mounted) {
        HapticFeedback.mediumImpact(); // kilit açıldı (2026-11-06)
        setState(() => _opening.remove(key));
      }
    }
  }

  String _deger(EvimSegment s, String field) => switch (field) {
        'yer' => EvimLabels.place(s, _en),
        'tip' => EvimLabels.tip(s.tip, _en),
        'deniz' => EvimLabels.sea(s.km, _en),
        'durum' => EvimLabels.durum(s.durum, _en),
        'kullanim' => EvimLabels.kullanim(s.kullanim, _en),
        'yazlik' => EvimLabels.summerHome(s, _en),
        _ => '',
      };

  String _anlati(EvimSegment s) {
    final list = _data?.anlati[s.narrPool];
    if (list == null || list.isEmpty) return '';
    final n = list[s.narrIdx % list.length];
    return _en ? n.en : n.tr;
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/evim/evim_menu.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0D0A20)),
          ),
          const ColoredBox(color: Color(0xA60D0A20)), // LG panelin arkası azıcık görünsün
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(_tr('Evim Neresi?', 'Where Is My Home?'),
                          textAlign: TextAlign.center, style: AppTextStyles.screenTitle),
                    ),
                    const SizedBox(width: 48),
                  ]),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(a), child: c),
                    ),
                    child: switch (_adim) {
                      _Adim.yukleniyor => const KeyedSubtree(
                          key: ValueKey('yuk'), child: Center(child: CircularProgressIndicator(color: _pink))),
                      _Adim.il => KeyedSubtree(key: const ValueKey('il'), child: _buildIl()),
                      _Adim.secim => KeyedSubtree(key: const ValueKey('secim'), child: _buildSecim()),
                      _Adim.hesap => KeyedSubtree(key: const ValueKey('hesap'), child: _buildHesap()),
                      _Adim.sonuc => KeyedSubtree(key: ValueKey('sonuc$_year'), child: _buildSonuc()),
                    },
                  ),
                ),
                const FloatingBarSpacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child, EdgeInsets padding = const EdgeInsets.fromLTRB(18, 20, 18, 18)}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: LiquidGlassPanel(padding: padding, child: child),
      );

  /// Popup'ın ek yüksekliği için 0..1: küçük ekranda 0 (taşma yok), büyükte 1. [base] sıkışık hâl, [extra] ek boy.
  double _uzama(BuildContext context, double maxH, double base, double extra) {
    final yazi = math.max(1.0, MediaQuery.textScalerOf(context).scale(14) / 14);
    return ((maxH - 16 - base * yazi) / extra).clamp(0.0, 1.0);
  }

  // ── Adım: il sorusu ─────────────────────────────────────────────────────
  Widget _buildIl() {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final iller = _sortedIller(data);
    final secili = _ilSecili;
    return LayoutBuilder(builder: (context, box) {
      final k = _uzama(context, box.maxHeight, 448, 108);
      double g(double a, double b) => lerpDouble(a, b, k)!;
      return Center(
      // Büyük yazı boyutunda taşmasın; sığdığında kaydırma yok (basılı tutmayı da bozmaz).
      child: SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: _panel(
        padding: EdgeInsets.fromLTRB(18, g(20, 34), 18, g(18, 28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_rounded, color: _pink, size: 30),
            SizedBox(height: g(10, 16)),
            // Tek satır kalır: sığmazsa yazı küçülür, alta inmez (Anıl, 2026-11-08).
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _tr('Gelecekte nerede yaşayacağını söyleyeceğim.', "I'll tell you where you're going to live."),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(color: _pink, fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.3),
              ),
            ),
            SizedBox(height: g(10, 14)),
            Text(
              _tr('Önce şu an hangi ilde yaşadığını söyle:', 'First, tell me which province you live in now:'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
            ),
            SizedBox(height: g(12, 18)),
            SizedBox(
              height: g(250, 310),
              child: ListView.builder(
                controller: _ilCtrl,
                itemCount: iller.length,
                itemExtent: _ilItemH,
                itemBuilder: (_, i) {
                  final il = iller[i];
                  final sel = il == secili;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _ilSecili = il);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: sel ? _purple.withValues(alpha: 0.32) : Colors.black.withValues(alpha: 0.25),
                        border: Border.all(
                            color: sel ? _pink.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.15), width: 1.2),
                      ),
                      child: Text(il,
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.white.withValues(alpha: 0.75),
                              fontSize: 15.5,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: g(14, 22)),
            _gradientButton(_tr('Devam', 'Continue'), onTap: secili == null ? null : () => _ilKaydet(secili)),
          ],
        ),
      ),
      ),
      );
    });
  }

  // ── Adım: yıl seçimi ────────────────────────────────────────────────────
  Widget _buildSecim() {
    return LayoutBuilder(builder: (context, box) {
      final k = _uzama(context, box.maxHeight, 445, 148);
      double g(double a, double b) => lerpDouble(a, b, k)!;
      return Center(
      // Popup içinde yatay kaydırma (yıl tekerleği) sayfayı GERİ götürmesin (Anıl, 2026-11-06).
      child: NoEdgeSwipeBack(
      child: SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: _panel(
        padding: EdgeInsets.fromLTRB(18, g(20, 38), 18, g(18, 30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_rounded, color: _pink, size: 30),
            SizedBox(height: g(12, 20)),
            Text(
              _tr('Hangi yıldaki evini merak ediyorsun?', 'Which year\'s home are you curious about?'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
            ),
            SizedBox(height: g(6, 10)),
            Text(
              _tr('Sola kaydırarak geleceğe git', 'Swipe left to travel into the future'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5),
            ),
            SizedBox(height: g(16, 36)),
            SizedBox(
              height: g(78, 88),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Yılların arkasındaki tekerlek: kaydırmayla döner, döndürülebilir olduğu anlaşılır.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _YearDrumPainter(_yearCtrl, itemExtent: _yearItemW, diameterRatio: _yearDiameter),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _purple.withValues(alpha: 0.25),
                      border: Border.all(color: _pink.withValues(alpha: 0.85), width: 1.4),
                    ),
                  ),
                  RotatedBox(
                    quarterTurns: 3,
                    child: ListWheelScrollView.useDelegate(
                      controller: _yearCtrl,
                      itemExtent: _yearItemW,
                      diameterRatio: _yearDiameter,
                      perspective: 0.004,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _year = _base + i);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: EvimEngine.horizon + 1,
                        builder: (_, i) {
                          final y = _base + i;
                          final sel = y == _year;
                          return RotatedBox(
                            quarterTurns: 1,
                            child: Center(
                              child: Text(
                                '$y',
                                style: TextStyle(
                                  color: sel ? Colors.white : Colors.white.withValues(alpha: 0.45),
                                  fontSize: sel ? 24 : 18,
                                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Kenarlara doğru tekerlek arkaya dönerken kararır.
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          gradient: LinearGradient(
                            stops: [0.0, 0.24, 0.76, 1.0],
                            colors: [Color(0xB3050310), Color(0x00050310), Color(0x00050310), Color(0xB3050310)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Basılı-tut yıl tekerleğinden uzak dursun, dokunma alanı rahat olsun (Anıl, 2026-11-06).
            SizedBox(height: g(30, 80)),
            Opacity(
              opacity: _t == null ? 0.4 : 1,
              child: IgnorePointer(
                ignoring: _t == null,
                child: HoldToReveal(
                  onComplete: _goster,
                  color: _pink,
                  icon: Icons.home_rounded,
                  radius: 58,
                ),
              ),
            ),
            SizedBox(height: g(12, 24)),
            Text(
              _tr('Geleceğe odaklanmak için basılı tut', 'Hold to focus on the future'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            SizedBox(height: g(6, 20)),
            TextButton(
              onPressed: _ilDegistir,
              child: Text(
                _tr('Şehrini değiştir${_il == null ? '' : ' ($_il)'}',
                    'Change your city${_il == null ? '' : ' ($_il)'}'),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12.5,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
      );
    });
  }

  Widget _buildHesap() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Belirsiz ev görselleri arasında dönüp yavaşlayarak birinde durur.
          BlurRevealSpinner(
            assetPaths: _kEvGorselleri,
            accent: _pink,
            size: 200,
            onDone: (_) => _hesapBitti(),
          ),
          const SizedBox(height: 22),
          Text(
            _tr('Gelecekteki evin aranıyor...', 'Searching for your future home...'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD8C4FF), fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSonuc() {
    final t = _t;
    if (t == null) return const SizedBox.shrink();
    final s = t.segmentFor(_year);
    final anlati = _anlati(s);
    return Center(
      child: SingleChildScrollView(
        child: _panel(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Tematik amblem (ev) — Anıl, 2026-11-06.
            Image.asset('assets/images/fal_sonuc/ev.png',
                height: 104, filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox(height: 8)),
            const SizedBox(height: 6),
            Text(_tr('$_year Evin', 'Your Home in $_year'),
                textAlign: TextAlign.center, style: AppTextStyles.screenTitle.copyWith(fontSize: 17)),
            const SizedBox(height: 16),
            for (final f in s.fields) _kutu(s, f),
            if (anlati.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(anlati,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.4)),
            ],
            const SizedBox(height: 14),
            _gradientButton(_tr('Başka bir yıl', 'Another year'), small: true, onTap: () {
              setState(() => _adim = _Adim.secim);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_yearCtrl.hasClients) _yearCtrl.jumpToItem(_year - _base);
              });
            }),
          ]),
        ),
      ),
    );
  }

  Widget _kutu(EvimSegment s, String field) {
    final t = _t!;
    final acik = t.isRevealed(s.id, field);
    final aciliyor = _opening.contains('${s.id}:$field');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text('${EvimLabels.field(field, _en)}:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: acik ? null : () => _ac(s, field),
              child: UnlockFlash(revealed: acik, color: _pink, child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: acik ? _purple.withValues(alpha: 0.30) : Colors.black.withValues(alpha: 0.35),
                  border: Border.all(
                      color: acik ? _pink.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.25), width: 1.2),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: acik
                      ? Align(
                          key: const ValueKey('acik'),
                          alignment: Alignment.centerLeft,
                          child: MarqueeText(_deger(s, field),
                              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
                        )
                      : Row(
                          key: const ValueKey('kapali'),
                          children: [
                            Icon(aciliyor ? Icons.hourglass_top_rounded : Icons.lock_rounded,
                                color: _pink.withValues(alpha: 0.9), size: 16),
                            const SizedBox(width: 8),
                            Text(_tr('Açmak için dokun', 'Tap to reveal'),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5)),
                          ],
                        ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton(String text, {VoidCallback? onTap, bool small = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: small ? 42 : 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)]),
            boxShadow: [BoxShadow(color: _pink.withValues(alpha: 0.35), blurRadius: 12)],
          ),
          child: Center(
            child: Text(text,
                style: TextStyle(color: Colors.white, fontSize: small ? 14.5 : 16.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

/// Yıl şeridinin arkasındaki yatay tekerlek: silindir gölgesi + üstte ve altta tırtıklar.
/// Tırtıklar yıllarla aynı eğride döner (ListWheelScrollView yarıçapı = genişlik × çap oranı / 2).
class _YearDrumPainter extends CustomPainter {
  _YearDrumPainter(this.controller, {required this.itemExtent, required this.diameterRatio})
      : super(repaint: controller);

  final FixedExtentScrollController controller;
  final double itemExtent;
  final double diameterRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          stops: [0.0, 0.5, 1.0],
          colors: [Color(0x66000000), Color(0x2EFFFFFF), Color(0x66000000)],
        ).createShader(rect),
    );

    final pos = controller.positions.length == 1 ? controller.position : null;
    final pixels = pos != null && pos.hasPixels ? pos.pixels : 0.0;
    final radius = size.width * diameterRatio / 2;
    final spacing = itemExtent / 4;
    final maxAngle = math.pi / 2;
    final first = ((pixels - radius * maxAngle) / spacing).floor();
    final last = ((pixels + radius * maxAngle) / spacing).ceil();
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    for (var i = first; i <= last; i++) {
      final angle = (i * spacing - pixels) / radius;
      if (angle.abs() >= maxAngle) continue;
      final depth = math.cos(angle);
      final x = size.width / 2 + radius * math.sin(angle);
      final major = i % 4 == 0;
      final len = major ? 12.0 : 7.0;
      tick
        ..strokeWidth = (major ? 1.6 : 1.0) * (0.45 + 0.55 * depth)
        ..color = Colors.white.withValues(alpha: (major ? 0.48 : 0.26) * depth);
      canvas.drawLine(Offset(x, 2), Offset(x, 2 + len), tick);
      canvas.drawLine(Offset(x, size.height - 2 - len), Offset(x, size.height - 2), tick);
    }
    canvas.restore();

    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _YearDrumPainter old) =>
      old.controller != controller || old.itemExtent != itemExtent || old.diameterRatio != diameterRatio;
}
