// "Arabam Ne?" falı (2026-11-05). Mantık: lib/data/services/araba_engine.dart.
// Akış: panel ("Tıkla") → kısa hesaplama → 5 yıl aralığı (alt alta, yanında kapalı kutu).
// Kapalı kutu: ödüllü reklam teklifi (kullanıcı seçerse) → model açılır, KALICI; reklam yoksa /
// sınır doluysa / yönetici modunda ücretsiz açılır.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/unlock_flash.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/ad_pacing.dart';
import '../../core/services/ad_service.dart';
import '../../core/widgets/odul_teklifi.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../core/widgets/marquee_text.dart';
import '../../core/widgets/blur_reveal_spinner.dart';
import '../../core/widgets/hold_to_reveal.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../data/providers.dart';
import '../../data/services/araba_engine.dart';

enum _Adim { marka, hesap, liste }

// Hesaplanıyor ekranındaki reveal spinner'ının döndüğü belirsiz araba görselleri (Anıl, 2026-11-07).
// Görseller henüz yok → BlurRevealSpinner errorBuilder ile prosedürel yedeğe düşer, kod çalışır.
const List<String> _kArabaGorselleri = [
  'assets/images/arabam/araba_01.jpg',
  'assets/images/arabam/araba_02.jpg',
  'assets/images/arabam/araba_03.jpg',
  'assets/images/arabam/araba_04.jpg',
  'assets/images/arabam/araba_05.jpg',
  'assets/images/arabam/araba_06.jpg',
  'assets/images/arabam/araba_07.jpg',
  'assets/images/arabam/araba_08.jpg',
  'assets/images/arabam/araba_09.jpg',
  'assets/images/arabam/araba_10.jpg',
  'assets/images/arabam/araba_11.jpg',
  'assets/images/arabam/araba_12.jpg',
  'assets/images/arabam/araba_13.jpg',
  'assets/images/arabam/araba_14.jpg',
  'assets/images/arabam/araba_15.jpg',
  'assets/images/arabam/araba_16.jpg',
];

class ArabamScreen extends ConsumerStatefulWidget {
  const ArabamScreen({super.key});

  @override
  ConsumerState<ArabamScreen> createState() => _ArabamScreenState();
}

class _ArabamScreenState extends ConsumerState<ArabamScreen> {
  static const _pink = Color(0xFFFF55FF);
  static const _purple = Color(0xFF8B5CF6);

  _Adim _adim = _Adim.marka;
  ArabaTimeline? _t;
  Map<int, ArabaCar> _cars = {};
  SharedPreferences? _prefs;
  final Set<int> _opening = {};

  // Marka seçimi: "arabam yok" (üstte) + A–Z markalar.
  List<String> _brands = const [];
  String? _selectedBrand; // null & !_noCar → henüz seçilmedi
  bool _noCar = false;

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
    // Önceden markasını seçip hesapladıysa → doğrudan liste; yoksa marka seçimi.
    final saved = prefs.getString(ArabaEngine.brandPrefsKey);
    setState(() {
      _prefs = prefs;
      _cars = {for (final c in pool) c.id: c};
      _brands = ArabaEngine.brands(pool);
      if (t.computed) {
        _t = t;
        _adim = _Adim.hesap; // her açılışta arama animasyonu, sonra liste
      } else {
        _adim = _Adim.marka;
        if (saved != null) {
          if (saved.isEmpty) {
            _noCar = true;
          } else {
            _selectedBrand = saved;
          }
        }
      }
    });
  }

  Future<void> _hesapla() async {
    final prefs = _prefs;
    if (prefs == null || !(_noCar || _selectedBrand != null)) return;
    final profile = ref.read(userProfileProvider);
    final pool = await ArabaEngine.loadPool();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final brandStr = _noCar ? '' : (_selectedBrand ?? '');
    // Sonucu önce hesapla; bekleme süresi artık BlurRevealSpinner'a ait. Spinner ~5.5 sn
    // belirsiz araba görselleri arasında dönüp durunca _spinnerBitti() listeye geçirir.
    final t = await ArabaEngine.load(prefs, profile, pool,
        currentBrand: brandStr, seed: Random().nextInt(1 << 31));
    await ArabaEngine.markComputed(prefs, t);
    if (!mounted) return;
    setState(() {
      _t = t;
      _adim = _Adim.hesap;
    });
  }

  void _spinnerBitti() {
    if (!mounted || _adim != _Adim.hesap) return;
    setState(() => _adim = _Adim.liste);
  }

  bool _teklifte = false; // teklif penceresi / reklam sürerken ikinci dokunuş yok

  Future<void> _ac(int index) async {
    final t = _t, prefs = _prefs;
    if (t == null || prefs == null || t.isRevealed(index) || _opening.contains(index) || _teklifte) return;
    _teklifte = true;
    try {
      // Ödül mümkünse teklif; değilse (reklam yok / sınır dolu) kutu ücretsiz açılır.
      var ac = true;
      if (AdService.instance.odulMumkun(OdulTuru.kutuAc)) {
        ac = await ref.kutuAcTeklifi(context, ref.read(l10nProvider).adOpenBoxSingleBody);
      }
      if (!ac || !mounted) return;
      setState(() => _opening.add(index));
      await ArabaEngine.reveal(prefs, t, index);
    } catch (_) {
      // Açılış hatası kutuyu bekleme halinde bırakmaz.
    } finally {
      _teklifte = false;
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
                      _Adim.marka => KeyedSubtree(key: const ValueKey('marka'), child: _buildMarka()),
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

  Widget _buildMarka() {
    final secildi = _noCar || _selectedBrand != null;
    // "Arabam yok" + A–Z markalar. Kaydırırken sayfa geri gitmesin → NoEdgeSwipeBack.
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Column(
        children: [
          const Icon(Icons.directions_car_filled_rounded, color: _pink, size: 32),
          const SizedBox(height: 8),
          // Falın amacı (Anıl, 2026-11-06): önce merakı uyandır.
          Text(
            _tr('Yıllar içinde nasıl arabalara bineceğini merak ediyor musun?',
                'Curious what cars you’ll be driving over the years?'),
            textAlign: TextAlign.center,
            style: TextStyle(color: _pink, fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 8),
          Text(
            _tr('Önce şu an hangi marka araban var?', 'First, what car brand do you have now?'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: NoEdgeSwipeBack(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.30),
                  border: Border.all(color: _pink.withValues(alpha: 0.35), width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _brands.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _markaSatir(
                        _tr('Arabam yok', 'I have no car'),
                        selected: _noCar,
                        italic: true,
                        onTap: () => setState(() {
                          _noCar = true;
                          _selectedBrand = null;
                        }),
                      );
                    }
                    final b = _brands[i - 1];
                    return _markaSatir(
                      b,
                      selected: !_noCar && _selectedBrand == b,
                      onTap: () => setState(() {
                        _selectedBrand = b;
                        _noCar = false;
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Opacity(
            opacity: secildi ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !secildi,
              child: HoldToReveal(
                onComplete: _hesapla,
                color: _pink,
                icon: Icons.directions_car_filled_rounded,
                radius: 56,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            secildi
                ? _tr('Geleceğe odaklanmak için basılı tut', 'Hold to focus on the future')
                : _tr('Önce bir marka seç', 'First pick a brand'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _markaSatir(String ad, {required bool selected, required VoidCallback onTap, bool italic = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: selected ? _pink.withValues(alpha: 0.22) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                ad,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.78),
                  fontSize: 15.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: _pink, size: 20),
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
            // Belirsiz araba görselleri arasında dönüp yavaşlayarak birinde durur.
            BlurRevealSpinner(
              assetPaths: _kArabaGorselleri,
              accent: _pink,
              size: 190,
              onDone: (_) => _spinnerBitti(),
            ),
            const SizedBox(height: 16),
            Text(
              _tr('Gelecekteki araban aranıyor...', 'Searching for your future car...'),
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
              // Tematik amblem (araba) — Anıl, 2026-11-06.
              Image.asset('assets/images/fal_sonuc/araba.png',
                  height: 100, filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 8)),
              const SizedBox(height: 4),
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
    // Son (ufka kadar süren) aralık açık uçlu: bitiş yılı yerine sağ ok — "2074 sonrası ne
    // oluyor?" dedirtmesin (Anıl, 2026-11-06).
    final acikUclu = _t != null && _t!.slots.isNotEmpty && identical(s, _t!.slots.last);
    if (acikUclu) return '$from →';
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
                    MarqueeText(ArabaEngine.displayName(car, s, _t!.baseYear),
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

}
