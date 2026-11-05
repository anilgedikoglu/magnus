// lib/presentation/shell/main_tabs.dart
//
// Ana sekmeler kapsayıcısı: Ana Menü · Gelen Kutusu · Kullanıcı Bilgileri (bardaki sıra,
// Anıl 2026-11-05). Cam alt bar (GlassTabBar) sayfa geçişlerinin DIŞINDA, en üstte durur →
// üç ekranda tam aynı yerde, hiç kımıldamadan; seçim kapsülü doğrudan kayar.
//
// Neden ortak kapsayıcı (Codex incelemesi, 2026-11-04): Hero ile rota geçişinde bar
// taşımak go('/inbox') dal değişiminde çalışmıyor, pop+push örtüşüyor ve geçiş anında
// cam farklı arka planı örnekliyordu. Burada sekme değişimi = rota değil, durum.
//
// Kurallar:
//   - Aktif sekme tek kaynak: mainTabProvider. Her yerden selectMainTab(context, tab).
//   - Sekmeler keyed Stack çocukları → state korunur; gizli sekmede TickerMode kapalı
//     (settings nebula shader'ı / yıldızlar arka planda çalışmaz).
//   - Geçiş yönü bardaki sıradan: sağdaki sekme sağdan, soldaki soldan gelir; ana menü
//     en solda → ana menüye dönüşte çıkan sayfa sağa kayar.
//   - Android geri: ana menü dışındaysa ana menüye döner.
//   - Fallar/detaylar kendi rotalarında açılır → bu kapsayıcının (ve barın) ÜSTÜNE biner.
//   - Bar kaydırmayla küçülür/büyür (Instagram iOS 26 ölçümü, bar_minimize.dart): görünen
//     sekmenin dikey kaydırma olayları burada dinlenir; sekme değişince bar tam boy.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/bar_minimize.dart';
import '../../core/widgets/glass_tab_bar.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';
import '../home/home_screen.dart';
import '../inbox/inbox_screen.dart';
import '../settings/settings_screen.dart';

abstract final class MainTab {
  static const int profile = 0;
  static const int home = 1;
  static const int inbox = 2;
}

/// Aktif ana sekme (tek doğru kaynak).
final mainTabProvider = StateProvider<int>((ref) => MainTab.home);

/// Bardaki soldan sağa sıra: Ana Menü · Gelen Kutusu · Kullanıcı Bilgileri.
const List<int> kMainTabOrder = [MainTab.home, MainTab.inbox, MainTab.profile];

/// Görünen sekmeye bardan TEKRAR dokunulunca artar (ör. ana menü listesi başa kayar).
final mainTabReselectProvider = StateProvider<int>((ref) => 0);

/// Sekmenin bar slotu (0..2).
int barSlotFor(int tab) => kMainTabOrder.indexOf(tab).clamp(0, kMainTabOrder.length - 1);

/// Sekme sayfasının hangi yönden kayarak geleceği.
enum TabEntry { left, right, bottom }

class MainTabsScope extends InheritedWidget {
  const MainTabsScope({super.key, required this.select, required super.child});

  final void Function(int tab, {TabEntry? entry}) select;

  /// Bağımlılık kurmaz (yalnız fonksiyon referansı) → gereksiz rebuild yok.
  static MainTabsScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MainTabsScope>();

  @override
  bool updateShouldNotify(MainTabsScope oldWidget) => false;
}

/// Her yerden sekme değiştir. Kapsayıcı içindeyse animasyonla; dışındaysa
/// (ör. tarot sonucu / astroloji — üstte açılmış bir rota) provider'ı ayarlayıp ana ekrana döner.
void selectMainTab(BuildContext context, int tab, {TabEntry? entry}) {
  final scope = MainTabsScope.maybeOf(context);
  if (scope != null) {
    scope.select(tab, entry: entry);
    return;
  }
  ProviderScope.containerOf(context, listen: false)
      .read(mainTabProvider.notifier)
      .state = tab;
  GoRouter.of(context).go('/home');
}

class MainTabsScreen extends ConsumerStatefulWidget {
  const MainTabsScreen({super.key, this.debugPageBuilder});

  /// Yalnız test: gerçek ekranlar (Hive/servis bağımlı) yerine sahte sayfa.
  @visibleForTesting
  final Widget Function(int tab)? debugPageBuilder;

  @override
  ConsumerState<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends ConsumerState<MainTabsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  /// Barın küçülme ilerlemesi (0 tam boy, 1 küçük; yayda hafif taşabilir).
  late final AnimationController _minimize = AnimationController.unbounded(vsync: this);
  late final BarMinimizeLogic _minimizeLogic = BarMinimizeLogic(
    onCreep: (v) {
      // Azaltılmış harekette sürünme yok; yay çalışırken de yok (inceleme: ters kaydırmada
      // çalışan küçülme yayı durup ölçek bir karede sıçrıyordu).
      if (_reduceMotion || _minimize.isAnimating) return;
      _minimize.value = v;
    },
    onCommit: (compact) => _springMinimize(compact ? 1 : 0,
        compact ? kBarMinimizeKickVelocity : -kBarMinimizeKickVelocity),
    onRelease: (compact) => _springMinimize(compact ? 1 : 0, 0),
  );

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _springMinimize(double target, double velocity) {
    if (!mounted) return;
    if (_reduceMotion) {
      _minimize.value = target;
      return;
    }
    if (_minimize.value == target && !_minimize.isAnimating) return;
    _minimize.animateWith(SpringSimulation(
        kBarMinimizeSpring, _minimize.value, target, _minimize.velocity + velocity));
  }

  /// Görünen sekmenin DİKEY ana kaydırması → küçülme mantığı. Esneme (overscroll) sayılmaz;
  /// listenin başı = tam boy. Yatay (sekme/marquee) ve iç içe kaydırmalar yok sayılır.
  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final m = n.metrics;
    if (n is ScrollUpdateNotification) {
      if (m.pixels <= m.minScrollExtent) {
        _minimizeLogic.reset();
        return false;
      }
      if (m.pixels > m.maxScrollExtent) return false; // alt esneme
      // Hareket esneme bölgesinden başladıysa yalnız sınırın içindeki kısmı say.
      final before = m.pixels - (n.scrollDelta ?? 0);
      _minimizeLogic.add(m.pixels - before.clamp(m.minScrollExtent, m.maxScrollExtent));
    } else if (n is ScrollEndNotification) {
      _minimizeLogic.release();
    }
    return false;
  }
  late final CurvedAnimation _curved =
      CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic);

  late int _current;
  int? _from; // geçişte çıkan sekme
  final Set<int> _built = {};
  // Sağdaki sekmeler sağdan gelir (gelen kutusu HER ZAMAN sağdan — Anıl).
  final Map<int, TabEntry> _entry = {
    MainTab.profile: TabEntry.right,
    MainTab.inbox: TabEntry.right,
  };
  TabEntry? _pendingEntry;

  /// Geçiş sürerken gelen seçim sıraya alınır (Codex: aksi hâlde yarım görünen
  /// sayfa bir anda tam konuma sıçrıyordu). Yalnız SON istek tutulur.
  int? _queued;
  TabEntry? _queuedEntry;

  /// Sistem geri tuşu: go_router 13.2.5 `popRoute`, hiçbir navigatör pop edemezken
  /// `maybePop()` ÇAĞIRMIYOR (delegate.dart:59-77) → PopScope atlanır, uygulama
  /// kapanırdı (Codex bulgusu, kaynakla doğrulandı). `onExit` de uygun değil:
  /// `go()` navigasyonunda da çağrılıp yönlendirmeyi bloklar. → Öncelikli çocuk
  /// geri-tuşu dağıtıcısı yalnız geri olaylarını yakalar.
  BackButtonDispatcher? _parentBack;
  ChildBackButtonDispatcher? _back;

  static const _still = AlwaysStoppedAnimation<Offset>(Offset.zero);

  /// Zarf rozeti zamana bağlı: "hazırlanıyor" bir fal, unlockAt anında kendiliğinden
  /// "hazır" olur ama inboxProvider değişmez → bar yenilenmezse rozet turuncuda kalırdı
  /// (Codex). En erken açılma anına zamanlayıcı + uygulamaya dönüşte yenileme.
  Timer? _badgeTimer;
  late final AppLifecycleListener _life = AppLifecycleListener(onResume: _refreshBadge);

  void _refreshBadge() {
    if (!mounted) return;
    setState(() {});
    _scheduleBadgeTimer(ref.read(inboxProvider));
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
    _badgeTimer = Timer(earliest.difference(now) + const Duration(milliseconds: 50), _refreshBadge);
  }

  @override
  void initState() {
    super.initState();
    _current = ref.read(mainTabProvider);
    _built.add(_current);
    _life; // dinleyiciyi başlat
    _scheduleBadgeTimer(ref.read(inboxProvider));
    _anim.addStatusListener((s) {
      if (s != AnimationStatus.completed || !mounted) return;
      setState(() => _from = null);
      final q = _queued;
      _queued = null;
      if (q != null && q != _current) {
        _pendingEntry = _queuedEntry;
        _onTabChanged(q);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = Router.maybeOf(context)?.backButtonDispatcher;
    if (parent != null && parent != _parentBack) {
      _releaseBack();
      _parentBack = parent;
      _back = parent.createChildBackButtonDispatcher()
        ..addCallback(_onSystemBack)
        ..takePriority();
    }
  }

  void _releaseBack() {
    final b = _back;
    if (b != null) {
      b.removeCallback(_onSystemBack);
      _parentBack?.forget(b);
    }
    _back = null;
  }

  Future<bool> _onSystemBack() {
    bool handled() {
      if (!mounted || _current == MainTab.home) return false; // ana menü: eski davranış
      if (!TickerMode.valuesOf(context).enabled) return false; // dal görünmüyor
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return false; // dalda üstte rota (inbox detayı)
      final root = Navigator.maybeOf(context, rootNavigator: true);
      if (root != null && root.canPop()) return false; // kökte üstte rota (fal ekranı vb.)
      _select(MainTab.home);
      return true;
    }

    return SynchronousFuture<bool>(handled());
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _life.dispose();
    _releaseBack();
    _curved.dispose();
    _anim.dispose();
    _minimize.dispose();
    super.dispose();
  }

  /// Bar dokunuşu: 0 → ana menü, 1 → gelen kutusu, 2 → kullanıcı bilgileri.
  void _onBarTap(int slot) {
    final tab = kMainTabOrder[slot];
    if (tab == _current && _from == null) {
      ref.read(mainTabReselectProvider.notifier).state++;
      return;
    }
    _select(tab);
  }

  void _select(int tab, {TabEntry? entry}) {
    _pendingEntry = entry;
    final notifier = ref.read(mainTabProvider.notifier);
    if (notifier.state == tab) {
      _onTabChanged(tab); // aynı sekmeye tekrar dokunuş
    } else {
      notifier.state = tab; // ref.listen → _onTabChanged
    }
  }

  void _onTabChanged(int tab) {
    final entry = _pendingEntry;
    _pendingEntry = null;
    if (_from != null) {
      // Geçiş sürüyor → bitince uygula (son istek kazanır).
      _queued = tab;
      _queuedEntry = entry;
      return;
    }
    if (tab == _current) return; // aynı sekme
    // Varsayılan yön bardaki sıradan: hedef sağdaysa sağdan, soldaysa soldan gelir.
    if (tab != MainTab.home) {
      _entry[tab] = entry ??
          (barSlotFor(tab) > barSlotFor(_current) ? TabEntry.right : TabEntry.left);
    }
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _minimizeLogic.reset(); // yeni sekmede bar tam boy
    setState(() {
      _built.add(tab);
      _from = _current;
      _current = tab;
    });
    if (reduce) {
      _anim.value = 1;
      setState(() => _from = null);
    } else {
      _anim.forward(from: 0);
    }
  }

  Offset _offsetFor(int tab) => switch (_entry[tab] ?? TabEntry.right) {
        TabEntry.left => const Offset(-1, 0),
        TabEntry.right => const Offset(1, 0),
        TabEntry.bottom => const Offset(0, 1),
      };

  Widget _page(int tab) {
    final debug = widget.debugPageBuilder;
    if (debug != null) return debug(tab);
    return switch (tab) {
      MainTab.profile => const SettingsScreen(),
      MainTab.home => const HomeScreen(),
      _ => const InboxScreen(),
    };
  }

  /// Yapı HER ZAMAN aynı (Offstage/TickerMode/IgnorePointer/SlideTransition) → state kaybolmaz.
  Widget _tab(int tab, {required bool visible, Animation<Offset>? slide}) {
    return Positioned.fill(
      key: ValueKey<int>(tab),
      child: Offstage(
        offstage: !visible,
        child: TickerMode(
          enabled: visible,
          child: IgnorePointer(
            ignoring: _from != null, // geçiş sırasında çift dokunuşu engelle
            // Yalnız GÖRÜNEN ve geçişte olmayan sekmenin kaydırması barı küçültür
            // (inceleme: çıkan sekmenin momentumu gelen sekmede barı küçültüyordu).
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) => tab == _current && _from == null && _onScroll(n),
              child: SlideTransition(position: slide ?? _still, child: _page(tab)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainTabProvider, (prev, next) => _onTabChanged(next));
    ref.listen<List<InboxItem>>(inboxProvider, (_, items) => _scheduleBadgeTimer(items));

    final from = _from;
    final to = _current;
    final children = <Widget>[];
    // Görünmeyen ama inşa edilmiş sekmeler en altta (offstage, state korunur).
    for (final t in _built) {
      if (t != to && t != from) children.add(_tab(t, visible: false));
    }
    if (from == null) {
      children.add(_tab(to, visible: true));
    } else if (to == MainTab.home) {
      // Ana menüye dönüş: ana menü altta sabit; ana menü barın en solunda → çıkan
      // sayfa her zaman sağa kayar.
      children.add(_tab(to, visible: true));
      children.add(_tab(from, visible: true,
          slide: Tween(begin: Offset.zero, end: const Offset(1, 0)).animate(_curved)));
    } else {
      // Yeni sekme üstte kayarak gelir; çıkan altta bekler.
      children.add(_tab(from, visible: true));
      children.add(_tab(to, visible: true,
          slide: Tween(begin: _offsetFor(to), end: Offset.zero).animate(_curved)));
    }

    final s = ref.watch(l10nProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: _current == MainTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(MainTab.home);
      },
      child: MainTabsScope(
        select: _select,
        child: Stack(
          children: [
            Positioned.fill(child: Stack(children: children)),
            Positioned(
              left: kGlassBarSide,
              right: kGlassBarSide,
              bottom: bottom + kGlassBarGap,
              height: kGlassBarHeight,
              child: Consumer(builder: (context, cref, _) {
                // Zarf rozeti (Anıl, 2026-11-05): hazırlanan fal varsa turuncu, hepsi
                // hazır + okunmamış varsa yeşil, okunmamış yoksa nokta yok.
                // Doğrudan öğelerden (önbellekli readyUnreadCountProvider zamanla
                // değişmez): rozet zamanlayıcısı bu kapsayıcıyı yeniden çizdirince güncel.
                final items = cref.watch(inboxProvider);
                final hasLocked = items.any((e) => e.isLocked);
                final hasUnread = items.any((e) => !e.isRead && !e.isLocked);
                final badge = hasLocked
                    ? InboxBadge.preparing
                    : hasUnread
                        ? InboxBadge.ready
                        : InboxBadge.none;
                return GlassTabBar(
                  selected: barSlotFor(_current), // görünen sekme → kapsülün yeri
                  onTap: _onBarTap,
                  badge: badge,
                  minimize: _minimize,
                  tint: cref.watch(glassTintProvider),
                  labels: [
                    s.tabHome,
                    switch (badge) {
                      InboxBadge.preparing => s.tabInboxPreparing,
                      InboxBadge.ready => s.tabInboxUnread,
                      InboxBadge.none => s.tabInbox,
                    },
                    s.settingsTitle,
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
