// "Arabam Ne?" falı (2026-11-05). Mantık: lib/data/services/araba_engine.dart.
// Akış: panel ("Tıkla") → kısa hesaplama → 5 yıl aralığı (alt alta, yanında kapalı kutu).
// Her kutu: geçiş reklamı (AdService sıklık sınırıyla) → model açılır ve KALICI açık kalır.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/unlock_flash.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/ad_service.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../core/widgets/marquee_text.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/providers.dart';
import '../../data/services/araba_engine.dart';

enum _Adim { giris, hesap, liste }

class ArabamScreen extends ConsumerStatefulWidget {
  const ArabamScreen({super.key});

  @override
  ConsumerState<ArabamScreen> createState() => _ArabamScreenState();
}

class _ArabamScreenState extends ConsumerState<ArabamScreen> {
  static const _pink = Color(0xFFFF55FF);
  static const _purple = Color(0xFF8B5CF6);

  _Adim _adim = _Adim.giris;
  ArabaTimeline? _t;
  Map<int, ArabaCar> _cars = {};
  SharedPreferences? _prefs;
  final Set<int> _opening = {};

  bool get _en => ref.read(localeProvider) == 'en';
  String _tr(String tr, String en) => _en ? en : tr;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = ref.read(userProfileProvider); // await'ten ÖNCE (dispose sonrası ref yok)
    final prefs = await SharedPreferences.getInstance();
    final pool = await ArabaEngine.loadPool();
    if (!mounted) return;
    final t = await ArabaEngine.load(prefs, profile, pool);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _cars = {for (final c in pool) c.id: c};
      _t = t;
      if (t.computed) _adim = _Adim.liste; // daha önce hesaplandı → doğrudan liste
    });
  }

  Future<void> _hesapla() async {
    final t = _t, prefs = _prefs;
    if (t == null || prefs == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _adim = _Adim.hesap);
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    await ArabaEngine.markComputed(prefs, t);
    if (!mounted) return;
    setState(() => _adim = _Adim.liste);
  }

  void _ac(int index) {
    final t = _t, prefs = _prefs;
    if (t == null || prefs == null || t.isRevealed(index) || _opening.contains(index)) return;
    setState(() => _opening.add(index));
    _acReklamla(() => ArabaEngine.reveal(prefs, t, index), index);
  }

  /// Reklam kapanınca kutuyu açar; reklam hata verse de kutu bekleme halinde kalmaz.
  Future<void> _acReklamla(Future<void> Function() reveal, int index) async {
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
        setState(() => _opening.remove(index));
      }
    }
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
            'assets/images/arabam/arabam_menu.jpg',
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
                      child: Text(_tr('Arabam Ne?', 'What Is My Car?'),
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
                      _Adim.giris => KeyedSubtree(key: const ValueKey('giris'), child: _buildGiris()),
                      _Adim.hesap => KeyedSubtree(key: const ValueKey('hesap'), child: _buildHesap()),
                      _Adim.liste => KeyedSubtree(key: const ValueKey('liste'), child: _buildListe()),
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

  Widget _buildGiris() {
    return Center(
      child: _panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_filled_rounded, color: _pink, size: 34),
            const SizedBox(height: 12),
            Text(
              _tr('Gelecekte sahip olacağın arabaları merak ediyor musun? Tıkla.',
                  'Curious about the cars you will own in the future? Tap.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
            ),
            const SizedBox(height: 18),
            _gradientButton(_tr('Tıkla', 'Tap'), onTap: _t == null ? null : _hesapla),
          ],
        ),
      ),
    );
  }

  Widget _buildHesap() {
    return Center(
      child: _panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tr('Gelecekte sahip olacağın arabaları merak ediyor musun? Tıkla.',
                  'Curious about the cars you will own in the future? Tap.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14, height: 1.35),
            ),
            const SizedBox(height: 20),
            const ElegantHourglass(size: 60, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _tr('Hesaplanıyor...', 'Calculating...'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD8C4FF), fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListe() {
    final t = _t;
    if (t == null) return const SizedBox.shrink();
    return Center(
      child: SingleChildScrollView(
        child: _panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_tr('Arabaların', 'Your Cars'),
                  textAlign: TextAlign.center, style: AppTextStyles.screenTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 14),
              // Geçmişte kalan aralıklar gösterilmez; süren aralık bu yıldan başlar.
              for (var i = 0; i < t.slots.length; i++)
                if (t.slots[i].end >= _thisYear) _satir(i, t.slots[i]),
            ],
          ),
        ),
      ),
    );
  }

  static int get _thisYear => DateTime.now().year;
  String _aralik(ArabaSlot s) {
    final from = s.start < _thisYear ? _thisYear : s.start;
    return from == s.end ? '$from:' : '$from – ${s.end}:';
  }

  Widget _satir(int index, ArabaSlot s) {
    final etiket = SizedBox(
      width: 112,
      child: Text(_aralik(s),
          style: TextStyle(
              color: Colors.white.withValues(alpha: s.isGap ? 0.5 : 0.85), fontSize: 14, fontWeight: FontWeight.w600)),
    );
    if (s.isGap) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 36,
          child: Row(children: [
            etiket,
            Expanded(
              child: Text(_tr('Arabasız dönem', 'No-car period'),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 14, fontStyle: FontStyle.italic)),
            ),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [etiket, Expanded(child: _kutu(index, s))]),
    );
  }

  IconData _fuelIcon(String f) => switch (f) {
        'elektrik' => Icons.bolt_rounded,
        'hidrojen' => Icons.water_drop_rounded,
        _ => Icons.local_gas_station_rounded,
      };

  Widget _kutu(int index, ArabaSlot s) {
    final t = _t!;
    final acik = t.isRevealed(index);
    final aciliyor = _opening.contains(index);
    final car = s.carId == null ? null : _cars[s.carId];
    return GestureDetector(
      onTap: acik ? null : () => _ac(index),
      child: UnlockFlash(revealed: acik, color: _pink, child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: acik ? _purple.withValues(alpha: 0.30) : Colors.black.withValues(alpha: 0.35),
          border: Border.all(
              color: acik ? _pink.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.25), width: 1.2),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: acik && car != null
              ? Column(
                  key: const ValueKey('acik'),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sığmayan model adı alt satıra inmez: tek satırda yavaşça kayar.
                    MarqueeText(car.model,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_fuelIcon(car.fuel), size: 13, color: _pink.withValues(alpha: 0.95)),
                      const SizedBox(width: 3),
                      Text(ArabaLabels.fuel(car.fuel, _en),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
                    ]),
                  ],
                )
              : Row(
                  key: const ValueKey('kapali'),
                  children: [
                    Icon(aciliyor ? Icons.hourglass_top_rounded : Icons.lock_rounded,
                        color: _pink.withValues(alpha: 0.9), size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(_tr('Açmak için dokun', 'Tap to reveal'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5)),
                    ),
                  ],
                ),
        ),
      )),
    );
  }

  Widget _gradientButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)]),
          boxShadow: [BoxShadow(color: _pink.withValues(alpha: 0.35), blurRadius: 12)],
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
