// "Kısmetim Kim?" falı (2026-11-05). Mantık: lib/data/services/kismet_engine.dart.
// Akış: yıl seç (bu yıl ortada, geçmiş yok, sola kaydır → +50) → kısa hesaplama →
// sonuç: "Eşin" / "Şu anki partnerin" / "yeni tanışma görünmüyor" / 6 kapalı kutu.
// Kapalı kutuya dokununca ödüllü reklam teklifi (kullanıcı seçerse) → o kişinin TÜM kutuları açılır, KALICI.
// Reklam hazır değilse / sınır doluysa / yönetici modunda kutu ücretsiz açılır (kullanıcı kilitlenmez).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/unlock_flash.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../core/widgets/hold_to_reveal.dart';
import '../../core/widgets/floating_bar_spacer.dart';

import '../../core/constants/app_text_styles.dart';
import '../../core/services/ad_pacing.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/sonuc_reklami.dart';
import '../../core/widgets/odul_teklifi.dart';
import '../../core/widgets/marquee_text.dart';
import '../../data/services/kismet_lines.dart';
import '../../core/widgets/blur_reveal_spinner.dart';
import '../../data/providers.dart';
import '../../data/services/kismet_engine.dart';

enum _Adim { secim, hesap, sonuc }

// Hesaplanıyor ekranındaki reveal spinner'ının döndüğü belirsiz portreler (Anıl, 2026-11-07).
// Görseller henüz yok → BlurRevealSpinner errorBuilder ile prosedürel yedeğe düşer, kod çalışır.
const List<String> _kKismetPortreler = [
  'assets/images/kismetim/portre_01.jpg',
  'assets/images/kismetim/portre_02.jpg',
  'assets/images/kismetim/portre_03.jpg',
  'assets/images/kismetim/portre_04.jpg',
  'assets/images/kismetim/portre_05.jpg',
  'assets/images/kismetim/portre_06.jpg',
  'assets/images/kismetim/portre_07.jpg',
  'assets/images/kismetim/portre_08.jpg',
  'assets/images/kismetim/portre_09.jpg',
  'assets/images/kismetim/portre_10.jpg',
  'assets/images/kismetim/portre_11.jpg',
  'assets/images/kismetim/portre_12.jpg',
  'assets/images/kismetim/portre_13.jpg',
  'assets/images/kismetim/portre_14.jpg',
  'assets/images/kismetim/portre_15.jpg',
  'assets/images/kismetim/portre_16.jpg',
];

class KismetimScreen extends ConsumerStatefulWidget {
  const KismetimScreen({super.key});

  @override
  ConsumerState<KismetimScreen> createState() => _KismetimScreenState();
}

class _KismetimScreenState extends ConsumerState<KismetimScreen> {
  static const _pink = Color(0xFFFF55FF);
  static const _purple = Color(0xFF8B5CF6);

  _Adim _adim = _Adim.secim;
  KismetTimeline? _t;
  SharedPreferences? _prefs;
  late final int _base = DateTime.now().year;
  late int _year = _base;
  final _yearCtrl = FixedExtentScrollController();
  final Set<String> _opening = {};

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
    if (!mounted) return;
    final t = await KismetEngine.load(prefs, profile);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _t = t;
    });
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  void _goster() {
    HapticFeedback.mediumImpact();
    // Sonuç zaten _load()'da hesaplandı (_t). Bekleme süresi artık BlurRevealSpinner'a ait:
    // spinner ~5.5 sn belirsiz portreler arasında dönüp durunca _spinnerBitti() sonuca geçirir.
    setState(() => _adim = _Adim.hesap);
  }

  bool _reklamda = false;

  Future<void> _spinnerBitti() async {
    if (!mounted || _adim != _Adim.hesap || _reklamda) return;
    _reklamda = true;
    await sonucOncesiReklam();
    _reklamda = false;
    if (!mounted || _adim != _Adim.hesap) return;
    setState(() => _adim = _Adim.sonuc);
  }

  bool _teklifte = false; // teklif penceresi / reklam sürerken ikinci dokunuş yok

  Future<void> _ac(KismetPerson p, String field) async {
    final t = _t, prefs = _prefs;
    if (t == null || prefs == null || t.isRevealed(p.id, field) || _opening.contains(field) || _teklifte) return;
    _teklifte = true;
    try {
      // Ödül mümkünse teklif; değilse (reklam yok / sınır dolu) kutu ücretsiz açılır.
      var ac = true;
      await AdService.instance.odulluBekle();
      if (!mounted) return;
      if (AdService.instance.odulMumkun(OdulTuru.kutuAc)) {
        ac = await ref.kutuAcTeklifi(context, ref.read(l10nProvider).adOpenBoxPersonBody);
      }
      if (!ac || !mounted) return;
      setState(() => _opening.add(field));
      for (final f in kKismetFields) {
        if (!t.isRevealed(p.id, f)) await KismetEngine.reveal(prefs, t, p.id, f);
      }
    } catch (_) {
      // Açılış hatası kutuyu bekleme halinde bırakmaz.
    } finally {
      _teklifte = false;
      if (mounted) {
        HapticFeedback.mediumImpact(); // kilit açıldı (2026-11-06)
        setState(() => _opening.remove(field));
      }
    }
  }

  String _deger(KismetPerson p, String field, int year) => switch (field) {
        'name' => p.displayName,
        'job' => KismetLabels.job(KismetEngine.jobForYear(p, year), _en),
        'city' => p.city,
        'hair' => KismetLabels.hair(p.hair, _en),
        'eye' => KismetLabels.eye(p.eye, _en),
        'height' => '${p.heightCm} cm',
        _ => '',
      };

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
            'assets/images/kismetim/kismetim_menu.jpg',
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
                      child: Text(_tr('Kısmetim Kim?', 'Who Is My Destiny?'),
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

  Widget _buildSecim() {
    return Center(
      // Popup içinde yatay kaydırma (yıl tekerleği) sayfayı GERİ götürmesin (Anıl, 2026-11-06):
      // tekerlek RotatedBox içinde dikey eksenli olduğundan global EdgeSwipeBack'in yatay-scroll
      // koruması devreye girmiyordu; kutuyu NoEdgeSwipeBack ile sarıyoruz.
      child: NoEdgeSwipeBack(
      child: _panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: _pink, size: 30),
            const SizedBox(height: 22),
            // Falın amacı (Anıl, 2026-11-06): önce merakı uyandır.
            Text(
              _tr('Gelecekte kimine olacaksın?',
                  'Who will you belong to in the future?'),
              textAlign: TextAlign.center,
              style: TextStyle(color: _pink, fontSize: 15, fontWeight: FontWeight.w700, height: 1.25),
            ),
            const SizedBox(height: 18),
            Text(
              _tr('Hangi tarihteki kısmetini merak ediyorsun?', 'Which year of your destiny are you curious about?'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w600, height: 1.3),
            ),
            const SizedBox(height: 12),
            Text(
              _tr('Sola kaydırarak geleceğe git', 'Swipe left to travel into the future'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5),
            ),
            const SizedBox(height: 38),
            // Yatay yıl tekerleği: bu yıl solda/ortada başlar, geçmiş yok, sola kaydır → gelecek
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
                        childCount: KismetEngine.horizon + 1,
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
            const SizedBox(height: 56),
            // Basılı-tut: geleceğe odaklan (Anıl, 2026-11-06; yıl tekerleğinden uzak + büyük).
            Opacity(
              opacity: _t == null ? 0.4 : 1,
              child: IgnorePointer(
                ignoring: _t == null,
                child: HoldToReveal(
                  onComplete: _goster,
                  color: _pink,
                  icon: Icons.favorite_rounded,
                  radius: 58,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _tr('Geleceğe odaklanmak için basılı tut', 'Hold to focus on the future'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
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
          // Belirsiz portreler arasında dönüp yavaşlayarak birinde durur (gelecek kısmet).
          BlurRevealSpinner(
            assetPaths: _kKismetPortreler,
            accent: _pink,
            size: 200,
            onDone: (_) => _spinnerBitti(),
          ),
          const SizedBox(height: 22),
          Text(
            _tr('$_year yılındaki kısmetin hesaplanıyor...', 'Calculating your destiny for $_year...'),
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
    final r = t.resultFor(_year);
    final baslik = Text(_tr('$_year Kısmetin', 'Your Destiny in $_year'),
        textAlign: TextAlign.center, style: AppTextStyles.screenTitle.copyWith(fontSize: 17));
    final Widget govde;
    switch (r.kind) {
      case KismetKind.spouse:
      case KismetKind.partner:
        final es = r.kind == KismetKind.spouse;
        govde = Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.favorite_rounded, color: _pink, size: 54),
          const SizedBox(height: 10),
          Text(es ? _tr('Eşin', 'Your spouse') : _tr('Şu anki partnerin', 'Your current partner'),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            // İlk cümle sabit, ikincisi yıla göre değişen havuzdan (art arda yıllarda farklı).
            es
                ? '${_tr('$_year yılında da kısmetin eşinle.', 'In $_year your destiny is still with your spouse.')} '
                    '${KismetLines.spouse(t.seed, _year, _en)}'
                : '${_tr('$_year yılında kısmetin, şu an yanında olan kişiyle görünüyor.', 'In $_year your destiny appears to be with the person by your side today.')} '
                    '${KismetLines.partner(t.seed, _year, _en)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.45),
          ),
        ]);
      case KismetKind.gap:
        govde = Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.nights_stay_rounded, color: Colors.white.withValues(alpha: 0.8), size: 46),
          const SizedBox(height: 10),
          Text(_tr('Bu yıl yeni bir tanışma görünmüyor.', 'No new encounter appears this year.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            KismetLines.gap(t.seed, _year, _en),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14.5, height: 1.4),
          ),
        ]);
      case KismetKind.person:
        final p = r.person!;
        govde = Column(mainAxisSize: MainAxisSize.min, children: [
          for (final f in kKismetFields) _kutu(p, f),
        ]);
    }
    return Center(
      child: SingleChildScrollView(
        child: _panel(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Tematik amblem (kısmet) — Anıl, 2026-11-06.
            Image.asset('assets/images/fal_sonuc/kismet.png',
                height: 104, filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox(height: 8)),
            const SizedBox(height: 6),
            baslik,
            const SizedBox(height: 16),
            govde,
            const SizedBox(height: 16),
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

  Widget _kutu(KismetPerson p, String field) {
    final t = _t!;
    final acik = t.isRevealed(p.id, field);
    final aciliyor = _opening.contains(field);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text('${KismetLabels.field(field, _en)}:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: acik ? null : () => _ac(p, field),
              child: UnlockFlash(revealed: acik, color: _pink, child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          child: MarqueeText(_deger(p, field, _year),
                              style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
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
    );
  }
}

