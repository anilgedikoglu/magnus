// "Evim Neresi?" falı (2026-11-05). Mantık: lib/data/services/ev_engine.dart.
// Akış: (ilk kullanımda bir kez) "Şu an hangi ilde yaşıyorsun?" → yıl seç (bu yıl ortada, geçmiş yok,
// sola kaydır → +50) → kısa hesaplama → sonuç: yer, ev tipi, denize mesafe, durum, kullanım, (varsa) yazlık
// + kısa bir anlatı. Her satır kapalı kutu: geçiş reklamı (AdService sıklık sınırıyla) → açılır ve KALICI kalır.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_text_styles.dart';
import '../../core/services/ad_service.dart';
import '../../core/widgets/marquee_text.dart';
import '../../core/widgets/elegant_hourglass.dart';
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

  Future<void> _goster() async {
    HapticFeedback.mediumImpact();
    setState(() => _adim = _Adim.hesap);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
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
        HapticFeedback.lightImpact();
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: _geriGit(),
                ),
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
            Text(
              _tr('Şu an hangi ilde yaşıyorsun?', 'Which province do you live in right now?'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
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
            const SizedBox(height: 18),
            _gradientButton(_tr('Evimi Göster', 'Show My Home'), onTap: _t == null ? null : _goster),
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
    );
  }

  Widget _buildHesap() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ElegantHourglass(size: 64, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            _tr('Hesaplanıyor...', 'Calculating...'),
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
            const SizedBox(height: 4),
            Text(_tr('Eğlence amaçlıdır.', 'For entertainment purposes only.'),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
            const SizedBox(height: 12),
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
              child: AnimatedContainer(
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
              ),
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

  Widget _geriGit() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 2),
            Text(ref.watch(l10nProvider).backButton,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
