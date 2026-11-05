// lib/presentation/shell/main_tabs.dart
//
// Ana sekmeler kapsayıcısı: Ana Menü · Gelen Kutusu · Kullanıcı Bilgileri (bardaki sıra,
// Anıl 2026-11-05). Sekme değişimi = rota değil, durum (Codex 2026-11-04: Hero ile rota
// geçişinde bar taşımak go('/inbox') dal değişiminde çalışmıyordu).
//
// 2026-11-05 (Anıl):
//   • Cam alt bar artık BURADA DEĞİL: tüm rotaların üstünde yüzen tek bar
//     (shell/floating_bar.dart, MaterialApp.builder). Fal ekranlarında da aynı yerde durur.
//   • Sekme geçişleri ANİMASYONSUZ ("her nereden nereye olursa olsun tak tak tak"): sayfa
//     anında değişir; yalnız bardaki cam kapsül yayla kayar.
//
// Kurallar:
//   - Aktif sekme tek kaynak: mainTabProvider. Her yerden selectMainTab(context, tab).
//   - Sekmeler keyed Stack çocukları → state korunur; gizli sekmede TickerMode kapalı
//     (settings nebula shader'ı / yıldızlar arka planda çalışmaz).
//   - Yalnız GÖRÜNEN sekmenin kaydırma olayları yukarı (yüzen bara) geçer → bar küçülme.
//   - Android geri: ana menü dışındaysa ana menüye döner.
//   - Fallar/detaylar kendi rotalarında açılır → bu kapsayıcının ÜSTÜNE biner (bar hep en üstte).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Eski API (yön) — geçişler artık anında; parametre geriye uyum için duruyor.
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

/// Her yerden sekme değiştir. Kapsayıcı içindeyse doğrudan; dışındaysa (üstte açılmış bir
/// rota, ör. tarot / astroloji) provider'ı ayarlayıp ana ekrana döner.
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

class _MainTabsScreenState extends ConsumerState<MainTabsScreen> {
  late int _current;
  final Set<int> _built = {};

  /// Sistem geri tuşu: go_router 13.2.5 `popRoute`, hiçbir navigatör pop edemezken
  /// `maybePop()` ÇAĞIRMIYOR (delegate.dart:59-77) → PopScope atlanır, uygulama
  /// kapanırdı (Codex bulgusu, kaynakla doğrulandı). `onExit` de uygun değil:
  /// `go()` navigasyonunda da çağrılıp yönlendirmeyi bloklar. → Öncelikli çocuk
  /// geri-tuşu dağıtıcısı yalnız geri olaylarını yakalar.
  BackButtonDispatcher? _parentBack;
  ChildBackButtonDispatcher? _back;

  @override
  void initState() {
    super.initState();
    _current = ref.read(mainTabProvider);
    _built.add(_current);
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
    super.dispose();
  }

  void _select(int tab, {TabEntry? entry}) {
    final notifier = ref.read(mainTabProvider.notifier);
    if (notifier.state == tab) {
      _onTabChanged(tab);
    } else {
      notifier.state = tab; // ref.listen → _onTabChanged
    }
  }

  /// Anında geçiş (Anıl: "tak tak tak").
  void _onTabChanged(int tab) {
    if (tab == _current) return;
    setState(() {
      _built.add(tab);
      _current = tab;
    });
  }

  Widget _page(int tab) {
    final debug = widget.debugPageBuilder;
    if (debug != null) return debug(tab);
    return switch (tab) {
      MainTab.profile => const SettingsScreen(),
      MainTab.home => const HomeScreen(),
      _ => const InboxScreen(),
    };
  }

  /// Yapı HER ZAMAN aynı (Offstage/TickerMode) → state kaybolmaz.
  Widget _tab(int tab) {
    final visible = tab == _current;
    return Positioned.fill(
      key: ValueKey<int>(tab),
      child: Offstage(
        offstage: !visible,
        child: TickerMode(
          enabled: visible,
          // Yalnız görünen sekmenin kaydırması yüzen bara ulaşır (gizli sekme olayı yutulur).
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) => tab != _current,
            child: _page(tab),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainTabProvider, (prev, next) => _onTabChanged(next));
    return PopScope(
      canPop: _current == MainTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(MainTab.home);
      },
      child: MainTabsScope(
        select: _select,
        child: Stack(children: [for (final t in _built) _tab(t)]),
      ),
    );
  }
}
