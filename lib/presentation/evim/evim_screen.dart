// "Evim Neresi?" falı (2026-11-05). Mantık: lib/data/services/ev_engine.dart.
// Akış: (ilk kullanımda bir kez) "Şu an hangi ilde yaşıyorsun?" → yıl seç (bu yıl ortada, geçmiş yok,
// sola kaydır → +50) → kısa hesaplama → sonuç: yer, ev tipi, denize mesafe, durum, kullanım, (varsa) yazlık
// + kısa bir anlatı. Her satır kapalı kutu: geçiş reklamı (AdService sıklık sınırıyla) → açılır ve KALICI kalır.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/unlock_flash.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/ad_service.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../core/widgets/hold_to_reveal.dart';
import '../../core/widgets/marquee_text.dart';
import '../../data/providers.dart';
import '../../data/services/ev_engine.dart';

enum _Adim { yukleniyor, il, secim, hesap, sonuc }

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
  static const double _ilListH = 250;
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
      final target = (i * _ilItemH - (_ilListH - _ilItemH) / 2)
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
    // Sonuç zaten _useIl()'de hesaplandı (_t). Bekleme süresi artık dünya-haritası nabız
    // animasyonuna ait: ~5 sn harita üzerinde noktalar yanıp söner, bitince _hesapBitti().
    setState(() => _adim = _Adim.hesap);
  }

  void _hesapBitti() {
    if (!mounted || _adim != _Adim.hesap) return;
    setState(() => _adim = _Adim.sonuc);
  }

  void _ac(EvimSegment s, String field) {
    final t = _t, prefs = _prefs;
    final key = '${s.id}:$field';
    if (t == null || prefs == null || t.isRevealed(s.id, field) || _opening.contains(key)) return;
    setState(() => _opening.add(key));
    _acReklamla(() => EvimEngine.reveal(prefs, t, s.id, field), key);
  }

  /// Reklam kapanınca kutuyu açar; reklam hata verse de kutu bekleme halinde kalmaz.
  Future<void> _acReklamla(Future<void> Function() reveal, String key) async {
    Future<void>? opened; // tek açılış; herkes aynı işi bekler
    Future<void> doReveal() => opened ??= reveal();
    try {
      await AdService.instance.showInterstitial(onClosed: () => doReveal());
      await doReveal(); // geri çağrı gelmediyse yine de aç
    } catch (_) {
      await doReveal();
    } finally {
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
          const ColoredBox(color: Color(0xD90D0A20)),
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

  Widget _panel({required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xEE1E1150), Color(0xEE2D1580)],
          ),
          border: Border.all(color: _pink.withValues(alpha: 0.75), width: 1.4),
          boxShadow: [BoxShadow(color: _pink.withValues(alpha: 0.30), blurRadius: 18)],
        ),
        child: child,
      );

  // ── Adım: il sorusu ─────────────────────────────────────────────────────
  Widget _buildIl() {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final iller = _sortedIller(data);
    final secili = _ilSecili;
    final ilkKez = !(_prefs?.getBool(EvimEngine.prefsAskedKey) ?? false);
    return Center(
      child: _panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_rounded, color: _pink, size: 30),
            const SizedBox(height: 10),
            // Falın amacı (Anıl, 2026-11-06): önce merakı uyandır, sonra şehri sor.
            Text(
              _tr('Gelecekte nerelerde yaşayacağını merak ediyor musun?',
                  "Curious where you'll be living in the years to come?"),
              textAlign: TextAlign.center,
              style: TextStyle(color: _pink, fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.3),
            ),
            const SizedBox(height: 10),
            Text(
              _tr('Önce şu an hangi ilde yaşadığını söyle:', 'First, tell me which province you live in now:'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _ilListH,
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
            const SizedBox(height: 14),
            _gradientButton(_tr('Devam', 'Continue'), onTap: secili == null ? null : () => _ilKaydet(secili)),
            if (ilkKez) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _ilKaydet(data.matchIl(ref.read(userProfileProvider).birthCity) ?? 'İstanbul'),
                child: Text(_tr('Geç', 'Skip'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Adım: yıl seçimi ────────────────────────────────────────────────────
  Widget _buildSecim() {
    return Center(
      // Popup içinde yatay kaydırma (yıl tekerleği) sayfayı GERİ götürmesin (Anıl, 2026-11-06).
      child: NoEdgeSwipeBack(
      child: _panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_rounded, color: _pink, size: 30),
            const SizedBox(height: 12),
            Text(
              _tr('Hangi yıldaki evini merak ediyorsun?', 'Which year\'s home are you curious about?'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              _tr('Sola kaydırarak geleceğe git', 'Swipe left to travel into the future'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 78,
              child: Stack(
                alignment: Alignment.center,
                children: [
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
                      itemExtent: 82,
                      diameterRatio: 2.4,
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
                ],
              ),
            ),
            // Basılı-tut yıl tekerleğinden uzak dursun, dokunma alanı rahat olsun (Anıl, 2026-11-06).
            const SizedBox(height: 30),
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
            const SizedBox(height: 12),
            Text(
              _tr('Geleceğe odaklanmak için basılı tut', 'Hold to focus on the future'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            const SizedBox(height: 6),
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
    );
  }

  Widget _buildHesap() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dünya haritası üzerinde rastgele noktalar ardı ardına yanıp söner (~5 sn),
          // sonra sonuç. Harita görseli varsa kullanır, yoksa stilize koyu dünya çizer.
          _WorldMapPulse(
            size: 230,
            accent: _pink,
            onDone: _hesapBitti,
          ),
          const SizedBox(height: 22),
          Text(
            _tr('Haritada evin aranıyor...', 'Searching the map for your home...'),
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

// ── "Hesaplanıyor" dünya-haritası nabzı ──────────────────────────────────────
// Koyu bir dünya haritası (varsa görsel, yoksa stilize glob) üzerinde rastgele konumlarda
// ~150-250 ms'de bir yeni ışık noktası parlayıp söner. [duration] sonunda onDone çağrılır.
// Azaltılmış hareket: nokta üretimi kapanır, birkaç durağan nokta gösterilir, kısa süre
// sonra onDone (akış yine ilerler). Harita görseli: assets/images/evim/world_map.jpg (opsiyonel).
class _WorldMapPulse extends StatefulWidget {
  final double size;
  final Color accent;
  final VoidCallback? onDone;

  const _WorldMapPulse({
    required this.size,
    required this.accent,
    this.onDone,
  });

  @override
  State<_WorldMapPulse> createState() => _WorldMapPulseState();
}

class _WorldMapPulseState extends State<_WorldMapPulse>
    with SingleTickerProviderStateMixin {
  static const int _kLifeMs = 950; // bir noktanın parlayıp sönme süresi
  static const int _kMaxPulses = 48;
  static const Duration _kDuration = Duration(milliseconds: 5000); // toplam süre ~5 sn

  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: _kDuration); // kare tetikleyici
  final Stopwatch _sw = Stopwatch(); // nokta yaşlarını ölçer
  final math.Random _rnd = math.Random();
  final List<_Pulse> _pulses = [];
  Timer? _spawnTimer;
  Timer? _holdTimer;
  bool _reduced = false;
  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_done) {
      _spawnTimer?.cancel();
      _holdTimer?.cancel();
      _holdTimer = Timer(const Duration(milliseconds: 350), _finish);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_started) {
      _started = true;
      _sw.start();
      if (_reduced) {
        // Durağan birkaç nokta, kısa bekleme, bitir.
        for (var i = 0; i < 4; i++) {
          _pulses.add(_Pulse(_randomPoint(), -_kLifeMs ~/ 3));
        }
        _ctrl.value = 1.0;
        _holdTimer = Timer(const Duration(milliseconds: 600), _finish);
        setState(() {});
      } else {
        _ctrl.forward();
        _spawn();
      }
    }
  }

  Offset _randomPoint() {
    // Glob/orta oval içinde kalacak dağılım (hem stilize glob hem tam harita için makul).
    final ang = _rnd.nextDouble() * 2 * math.pi;
    final r = math.sqrt(_rnd.nextDouble()) * 0.44;
    return Offset(0.5 + r * math.cos(ang), 0.5 + r * math.sin(ang) * 0.92);
  }

  void _spawn() {
    if (!mounted || _done) return;
    _pulses.add(_Pulse(_randomPoint(), _sw.elapsedMilliseconds));
    // Sönmüş olanları temizle + taşmayı sınırla.
    final now = _sw.elapsedMilliseconds;
    _pulses.removeWhere((p) => now - p.bornMs > _kLifeMs);
    if (_pulses.length > _kMaxPulses) {
      _pulses.removeRange(0, _pulses.length - _kMaxPulses);
    }
    final next = 150 + _rnd.nextInt(100); // 150-250 ms
    _spawnTimer = Timer(Duration(milliseconds: next), _spawn);
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _holdTimer?.cancel();
    _ctrl.removeStatusListener(_onStatus);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.size * 0.1);
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Harita görseli (opsiyonel) → yoksa stilize koyu glob.
              Image.asset(
                'assets/images/evim/world_map.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    CustomPaint(painter: _StylizedMapPainter(accent: widget.accent)),
              ),
              // Yanıp sönen noktalar.
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(
                  painter: _MapPulsePainter(
                    pulses: _pulses,
                    nowMs: _sw.elapsedMilliseconds,
                    lifeMs: _kLifeMs,
                    accent: widget.accent,
                  ),
                ),
              ),
              // Gizemli vinyet + rim.
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: widget.accent.withValues(alpha: 0.30), width: 1.2),
                  gradient: RadialGradient(
                    radius: 0.98,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pulse {
  final Offset pos; // normalize (0..1)
  final int bornMs;
  const _Pulse(this.pos, this.bornMs);
}

class _MapPulsePainter extends CustomPainter {
  final List<_Pulse> pulses;
  final int nowMs;
  final int lifeMs;
  final Color accent;
  _MapPulsePainter({
    required this.pulses,
    required this.nowMs,
    required this.lifeMs,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (final p in pulses) {
      final age = nowMs - p.bornMs;
      if (age < 0 || age > lifeMs) continue;
      final t = age / lifeMs; // 0..1
      final appear = (age / 110).clamp(0.0, 1.0);
      final fade = ((lifeMs - age) / 520).clamp(0.0, 1.0);
      final a = appear * fade; // zarf 0..1
      if (a <= 0.01) continue;
      final c = Offset(p.pos.dx * w, p.pos.dy * h);

      // Genişleyen radar halkası.
      final ringR = w * (0.012 + t * 0.07);
      canvas.drawCircle(
        c,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = accent.withValues(alpha: 0.5 * a * (1 - t)),
      );

      // Hale.
      canvas.drawCircle(
        c,
        w * 0.03,
        Paint()
          ..color = accent.withValues(alpha: 0.35 * a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.03),
      );

      // Çekirdek parlak nokta.
      canvas.drawCircle(
        c,
        w * 0.011,
        Paint()..color = Color.lerp(accent, Colors.white, 0.6)!.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(_MapPulsePainter old) => true;
}

/// Harita görseli yoksa: koyu stilize bir dünya glob'u (ızgara + silik kara noktaları).
class _StylizedMapPainter extends CustomPainter {
  final Color accent;
  _StylizedMapPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final center = Offset(w / 2, h / 2);
    final r = w * 0.44;

    // Uzay zemini.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF14102E), Color(0xFF070512)],
        ).createShader(rect),
    );

    // Glob gövdesi.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [
            accent.withValues(alpha: 0.16),
            const Color(0xFF0E1B3A).withValues(alpha: 0.92),
            const Color(0xFF060A1C),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // Enlem/boylam ızgarası.
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = accent.withValues(alpha: 0.14);
    for (var i = 1; i < 6; i++) {
      final dy = -r + 2 * r * i / 6;
      final chord = math.sqrt(math.max(0.0, r * r - dy * dy));
      canvas.drawLine(Offset(center.dx - chord, center.dy + dy),
          Offset(center.dx + chord, center.dy + dy), grid);
    }
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 2 * (r - r * i * 0.33), height: 2 * r),
        grid,
      );
    }

    // Silik "kara" noktaları (deterministik seed → sabit desen).
    final dots = math.Random(7);
    final dotPaint = Paint()..color = accent.withValues(alpha: 0.22);
    for (var i = 0; i < 90; i++) {
      final ang = dots.nextDouble() * 2 * math.pi;
      final rr = math.sqrt(dots.nextDouble()) * r * 0.96;
      final p = Offset(center.dx + rr * math.cos(ang), center.dy + rr * math.sin(ang));
      canvas.drawCircle(p, 1.1 + dots.nextDouble() * 1.3, dotPaint);
    }
    canvas.restore();

    // İnce dış halka.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(_StylizedMapPainter old) => old.accent != accent;
}
