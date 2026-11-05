// lib/presentation/shell/main_tabs.dart
//
// Ana sekmeler kapsayıcısı: Kullanıcı Bilgileri (0) · Ana Menü (1) · Gelen Kutusu (2).
// Cam alt bar (GlassTabBar) sayfa geçişlerinin DIŞINDA, en üstte durur → üç ekranda
// tam aynı yerde, hiç kımıldamadan; seçim kapsülü doğrudan kayar (settings↔inbox 0↔2).
//
// Neden ortak kapsayıcı (Codex incelemesi, 2026-11-04): Hero ile rota geçişinde bar
// taşımak go('/inbox') dal değişiminde çalışmıyor, pop+push örtüşüyor ve geçiş anında
// cam farklı arka planı örnekliyordu. Burada sekme değişimi = rota değil, durum.
//
// Kurallar:
//   - Aktif sekme tek kaynak: mainTabProvider. Her yerden selectMainTab(context, tab).
//   - Sekmeler keyed Stack çocukları → state korunur; gizli sekmede TickerMode kapalı
//     (settings nebula shader'ı / yıldızlar arka planda çalışmaz).
//   - Geçişler eskisiyle aynı yön: settings soldan, inbox alttan (swipe ile sağdan);
//     ana menüye dönüşte çıkan sayfa geldiği yöne kayar.
//   - Android geri: ana menü dışındaysa ana menüye döner.
//   - Fallar/detaylar kendi rotalarında açılır → bu kapsayıcının (ve barın) ÜSTÜNE biner.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/glass_tab_bar.dart';
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

/// Ana menünün sayfası (0..2) — tek kaynak. Barda Ev1/Ev2/Ev3 → bu değer.
/// HomeScreen swipe/ok ile değişince yazar; bar dokunuşu yazınca HomeScreen o sayfaya gider.
/// (Codex: hedef ile ara sayfa karışmasın diye HomeScreen programatik animasyon
/// sırasında onPageChanged ara değerlerini yazmaz → kapsül doğrudan hedefe kayar.)
final homePageProvider = StateProvider<int>((ref) => 0);

/// Ana menü sayfa sayısı (bardaki ev slotları).
const int kHomePages = 3;

/// Bar slotu ↔ sekme/sayfa eşlemesi: 0 = profil, 1..3 = ana menü sayfa 1..3, 4 = inbox.
int barSlotFor(int tab, int homePage) => switch (tab) {
      MainTab.profile => 0,
      MainTab.inbox => kHomePages + 1,
      _ => 1 + homePage.clamp(0, kHomePages - 1),
    };

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final CurvedAnimation _curved =
      CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic);

  late int _current;
  int? _from; // geçişte çıkan sekme
  final Set<int> _built = {};
  final Map<int, TabEntry> _entry = {
    MainTab.profile: TabEntry.left,
    MainTab.inbox: TabEntry.right, // Anıl: gelen kutusu HER ZAMAN sağdan sola açılır
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

  @override
  void initState() {
    super.initState();
    _current = ref.read(mainTabProvider);
    _built.add(_current);
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
    _releaseBack();
    _curved.dispose();
    _anim.dispose();
    super.dispose();
  }

  /// Bar dokunuşu: 0 → profil, 1..3 → ana menü o sayfa, 4 → inbox.
  void _onBarTap(int slot) {
    if (slot == 0) return _select(MainTab.profile);
    if (slot == kHomePages + 1) return _select(MainTab.inbox);
    // Önce sayfa, sonra sekme: ana menü gizliyken HomeScreen anında atlar
    // (TickerMode kapalı → jumpToPage), görünürken kayarak gider.
    ref.read(homePageProvider.notifier).state = slot - 1;
    _select(MainTab.home);
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
    if (tab == _current) return; // aynı sekme (ev sayfaları homePageProvider ile)
    if (tab != MainTab.home) _entry[tab] = entry ?? (tab == MainTab.profile ? TabEntry.left : TabEntry.right);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
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
            child: SlideTransition(position: slide ?? _still, child: _page(tab)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainTabProvider, (prev, next) => _onTabChanged(next));

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
      // Ana menüye dönüş: ana menü altta sabit, çıkan sayfa geldiği yöne kayar.
      children.add(_tab(to, visible: true));
      children.add(_tab(from, visible: true,
          slide: Tween(begin: Offset.zero, end: _offsetFor(from)).animate(_curved)));
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
            ...children,
            Positioned(
              left: kGlassBarSide,
              right: kGlassBarSide,
              bottom: bottom + kGlassBarGap,
              height: kGlassBarHeight,
              child: Consumer(builder: (context, cref, _) {
                // Yeşil halka kuralı (değişmedi): hazırlanan fal kalmadı + okunmamış ≥1.
                final items = cref.watch(inboxProvider);
                final hasUnread = cref.watch(readyUnreadCountProvider) > 0;
                final hasLocked = items.any((e) => e.isLocked);
                final page = cref.watch(homePageProvider);
                return GlassTabBar(
                  // Görünen sekme (_current) + ana menü sayfası → kapsülün yeri.
                  selected: barSlotFor(_current, page),
                  onTap: _onBarTap,
                  hasUnread: hasUnread,
                  greenRing: !hasLocked && hasUnread,
                  labels: [
                    s.settingsTitle,
                    for (var p = 1; p <= kHomePages; p++) s.homePageLabel(p, kHomePages),
                    hasUnread ? s.tabInboxUnread : s.tabInbox,
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
