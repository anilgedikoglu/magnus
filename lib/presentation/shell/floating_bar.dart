// lib/presentation/shell/floating_bar.dart
//
// YÜZEN CAM ALT BAR — tüm uygulamada tek, sabit yerde, TÜM rotaların üstünde
// (MaterialApp.router builder'ında Navigator'ı sarar). Anıl, 2026-11-05:
//   • "Bu alt menü kompartmanının yeri sabit olacak, tüm app'te her fal türünde floating
//     olacak, çok istisnai durumlarda gizlenecek." → gizli: dil seçimi + onboarding
//     (kFloatingBarHiddenPaths) ve açık diyalog / alt sayfa (modal perdenin üstünde kalmasın).
//   • Ana sekmelerde (/home) seçili sekme gösterilir; fal ekranlarında SEÇİMSİZ (kapsül yok,
//     ikonlar beyaz). Dokununca seçili faza geçer (cam damla belirip oturur) ve o sekmeye gider.
//   • "Yukarı swipe ile küçülme, aşağı swipe ile büyüme app'in her yerinde": tüm rotaların
//     dikey kaydırma olayları burada dinlenir (bar_minimize.dart). Rota/sekme değişince tam boy.
//   • Alttaki "Geri Git" tuşları kaldırıldı; ekranlar FloatingBarSpacer ile yer bırakır.
//   • Fal titreşimleri (merkezi, tüm fal türleri): gelen kutusuna yeni fal düşünce
//     ("fal gönderildi") güçlü + orta vuruş; hazırlanan fal açılınca ("fal hazır/geldi")
//     artan üçlü vuruş.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/bar_minimize.dart';
import '../../core/widgets/glass_tab_bar.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';
import 'main_tabs.dart';

/// Barın gizlendiği istisnai rotalar (henüz uygulamaya girilmemiş akışlar).
const Set<String> kFloatingBarHiddenPaths = {'/language', '/onboarding'};

/// Açık modal (diyalog / alt sayfa) sayısı — kök navigatör gözlemcisinden. >0 iken bar
/// solarak gizlenir (yoksa en üstteki bar modal perdenin üstünde kalırdı).
final ValueNotifier<int> floatingBarModalCount = ValueNotifier<int>(0);

/// Kök navigatöre takılır (GoRouter observers). Her GoRouter örneğine yeni bir tane verilir.
class FloatingBarRouteObserver extends NavigatorObserver {
  void _inc(Route<dynamic>? r) {
    if (r is PopupRoute) floatingBarModalCount.value++;
  }

  void _dec(Route<dynamic>? r) {
    if (r is PopupRoute) floatingBarModalCount.value = math.max(0, floatingBarModalCount.value - 1);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _inc(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _dec(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _dec(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dec(oldRoute);
    _inc(newRoute);
  }
}

class FloatingBarHost extends ConsumerStatefulWidget {
  const FloatingBarHost({super.key, this.router, required this.child});

  /// Konum bilgisi için (null → testlerde hep '/home').
  final GoRouter? router;
  final Widget child;

  @override
  ConsumerState<FloatingBarHost> createState() => _FloatingBarHostState();
}

class _FloatingBarHostState extends ConsumerState<FloatingBarHost>
    with SingleTickerProviderStateMixin {
  String _path = '/home';

  /// Barın küçülme ilerlemesi (0 tam boy, 1 küçük; yayda hafif taşabilir).
  late final AnimationController _minimize = AnimationController.unbounded(vsync: this);
  late final BarMinimizeLogic _logic = BarMinimizeLogic(
    onCreep: (v) {
      // Azaltılmış harekette sürünme yok; yay çalışırken de yok (inceleme: ters kaydırmada
      // çalışan küçülme yayı durup ölçek bir karede sıçrıyordu).
      if (_reduce || _minimize.isAnimating) return;
      _minimize.value = v;
    },
    onCommit: (compact) => _spring(
        compact ? 1 : 0, compact ? kBarMinimizeKickVelocity : -kBarMinimizeKickVelocity),
    onRelease: (compact) => _spring(compact ? 1 : 0, 0),
  );

  /// Zarf rozeti zamana bağlı: "hazırlanıyor" bir fal unlockAt anında kendiliğinden
  /// "hazır" olur ama inboxProvider değişmez → en erken açılma anına zamanlayıcı +
  /// uygulamaya dönüşte yenileme (Codex).
  Timer? _badgeTimer;
  late final AppLifecycleListener _life = AppLifecycleListener(onResume: _refreshBadge);

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Fal titreşimleri için önceki durum: gelen kutusundaki fallar ve açılmış olanlar.
  Set<String> _itemIds = {};
  Set<String> _readyIds = {};

  void _rememberFortunes(List<InboxItem> items) {
    _itemIds = {for (final e in items) e.id};
    _readyIds = {for (final e in items) if (!e.isLocked) e.id};
  }

  /// Yeni fal düştü mü / hazırlanan fal açıldı mı → uygun titreşim.
  void _fortuneHaptics(List<InboxItem> items) {
    final ids = {for (final e in items) e.id};
    final ready = {for (final e in items) if (!e.isLocked) e.id};
    final sent = ids.difference(_itemIds).isNotEmpty;
    final opened = ready.difference(_readyIds).intersection(_itemIds).isNotEmpty;
    _itemIds = ids;
    _readyIds = ready;
    if (sent) {
      // "Fal gönderildi": tok bir vuruş + yankı.
      HapticFeedback.heavyImpact();
      Future<void>.delayed(const Duration(milliseconds: 110), HapticFeedback.mediumImpact);
    } else if (opened) {
      // "Falın hazır": artan üçlü vuruş (müjde hissi).
      HapticFeedback.lightImpact();
      Future<void>.delayed(const Duration(milliseconds: 130), HapticFeedback.mediumImpact);
      Future<void>.delayed(const Duration(milliseconds: 260), HapticFeedback.heavyImpact);
    }
  }

  @override
  void initState() {
    super.initState();
    _path = _currentPath();
    widget.router?.routerDelegate.addListener(_onRoute);
    floatingBarModalCount.addListener(_onModal);
    _life; // dinleyiciyi başlat
    _rememberFortunes(ref.read(inboxProvider));
    _scheduleBadgeTimer(ref.read(inboxProvider));
  }

  @override
  void didUpdateWidget(covariant FloatingBarHost old) {
    super.didUpdateWidget(old);
    if (old.router != widget.router) {
      old.router?.routerDelegate.removeListener(_onRoute);
      widget.router?.routerDelegate.addListener(_onRoute);
      _onRoute();
    }
  }

  @override
  void dispose() {
    widget.router?.routerDelegate.removeListener(_onRoute);
    floatingBarModalCount.removeListener(_onModal);
    _badgeTimer?.cancel();
    _life.dispose();
    _minimize.dispose();
    super.dispose();
  }

  String _currentPath() {
    final r = widget.router;
    if (r == null) return '/home';
    try {
      // push edilen rotalar (ImperativeRouteMatch) uri'yi değiştirmez → en üstteki eşleşmenin
      // konumu (go_router 13.2.5 match.dart: matchedLocation = itilen rota).
      final c = r.routerDelegate.currentConfiguration;
      return c.lastOrNull?.matchedLocation ?? c.uri.path;
    } catch (_) {
      return _path;
    }
  }

  /// go_router bildirimi derleme (build) sırasında gelebilir (dal değişimi) → o durumda
  /// yeniden çizimi kare sonuna ertele (setState-during-build hatası).
  void _safeRebuild(VoidCallback fn) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  void _onRoute() {
    final p = _currentPath();
    if (p == _path || !mounted) return;
    _safeRebuild(() => _path = p);
    _logic.reset(); // yeni ekranda bar tam boy
  }

  void _onModal() => _safeRebuild(() {});

  void _spring(double target, double velocity) {
    if (!mounted) return;
    if (_reduce) {
      _minimize.value = target;
      return;
    }
    if (_minimize.value == target && !_minimize.isAnimating) return;
    _minimize.animateWith(SpringSimulation(
        kBarMinimizeSpring, _minimize.value, target, _minimize.velocity + velocity));
  }

  /// Her ekranın DİKEY ana kaydırması → küçülme mantığı. Esneme (overscroll) sayılmaz;
  /// listenin başı = tam boy. Yatay ve iç içe kaydırmalar yok sayılır.
  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final m = n.metrics;
    if (n is ScrollUpdateNotification) {
      if (m.pixels <= m.minScrollExtent) {
        _logic.reset();
        return false;
      }
      if (m.pixels > m.maxScrollExtent) return false; // alt esneme
      // Hareket esneme bölgesinden başladıysa yalnız sınırın içindeki kısmı say.
      final before = m.pixels - (n.scrollDelta ?? 0);
      _logic.add(m.pixels - before.clamp(m.minScrollExtent, m.maxScrollExtent));
    } else if (n is ScrollEndNotification) {
      _logic.release();
    }
    return false;
  }

  void _refreshBadge() {
    if (!mounted) return;
    setState(() {});
    final items = ref.read(inboxProvider);
    _fortuneHaptics(items); // açılma anı: "falın hazır" titreşimi
    _scheduleBadgeTimer(items);
  }

  void _scheduleBadgeTimer(List<InboxItem> items) {
    _badgeTimer?.cancel();
    _badgeTimer = null;
    final now = DateTime.now();
    DateTime? earliest;
    for (final e in items) {
      final u = DateTime.tryParse(e.unlockAt ?? '');
      if (u != null && u.isAfter(now) && (earliest == null || u.isBefore(earliest))) {
        earliest = u;
      }
    }
    if (earliest == null) return;
    // +50 ms: isLocked'un "şimdi"si kesin olarak açılma anını geçmiş olsun.
    _badgeTimer =
        Timer(earliest.difference(now) + const Duration(milliseconds: 50), _refreshBadge);
  }

  /// Bar dokunuşu: 0 → ana menü, 1 → gelen kutusu, 2 → kullanıcı bilgileri.
  void _onTap(int slot) {
    final tab = kMainTabOrder[slot];
    final current = ref.read(mainTabProvider);
    if (_path == '/home') {
      if (tab == current) {
        ref.read(mainTabReselectProvider.notifier).state++;
      } else {
        ref.read(mainTabProvider.notifier).state = tab;
      }
    } else {
      // Fal ekranından: sekmeyi seç + üstteki rotaları kapatıp ana kapsayıcıya dön.
      ref.read(mainTabProvider.notifier).state = tab;
      widget.router?.go('/home');
    }
    _logic.reset();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<InboxItem>>(inboxProvider, (_, items) {
      _fortuneHaptics(items); // yeni fal: "fal gönderildi" titreşimi
      _scheduleBadgeTimer(items);
    });
    ref.listen<int>(mainTabProvider, (_, __) => _logic.reset());

    final content = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
    if (kFloatingBarHiddenPaths.contains(_path)) return content;

    final modal = floatingBarModalCount.value > 0;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final s = ref.watch(l10nProvider);
    final items = ref.watch(inboxProvider);
    // Zarf rozeti: hazırlanan fal varsa turuncu, hepsi hazır + okunmamış varsa yeşil,
    // okunmamış yoksa nokta yok (doğrudan öğelerden; zamanlayıcı yeniden çizdirir).
    final hasLocked = items.any((e) => e.isLocked);
    final hasUnread = items.any((e) => !e.isRead && !e.isLocked);
    final badge = hasLocked
        ? InboxBadge.preparing
        : hasUnread
            ? InboxBadge.ready
            : InboxBadge.none;
    final int? selected = switch (_path) {
      '/home' => barSlotFor(ref.watch(mainTabProvider)),
      '/inbox' => barSlotFor(MainTab.inbox),
      _ => null, // fal ekranı: seçimsiz
    };

    return Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          left: kGlassBarSide,
          right: kGlassBarSide,
          bottom: glassBarBottom(bottom), // Instagram ile aynı dikey yer
          height: kGlassBarHeight,
          child: IgnorePointer(
            ignoring: modal,
            child: AnimatedOpacity(
              opacity: modal ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: GlassTabBar(
                key: const ValueKey('floatingGlassBar'),
                selected: selected,
                onTap: _onTap,
                badge: badge,
                minimize: _minimize,
                tint: ref.watch(glassTintProvider),
                labels: [
                  s.tabHome,
                  switch (badge) {
                    InboxBadge.preparing => s.tabInboxPreparing,
                    InboxBadge.ready => s.tabInboxUnread,
                    InboxBadge.none => s.tabInbox,
                  },
                  s.settingsTitle,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
