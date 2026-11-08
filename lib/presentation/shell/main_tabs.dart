// lib/presentation/shell/main_tabs.dart
//
// Ana sekmeler kapsayıcısı: Ana Menü · Gelen Kutusu · Kullanıcı Bilgileri (bardaki sıra,
// Anıl 2026-11-05). Sekme değişimi = rota değil, durum (Codex 2026-11-04: Hero ile rota
// geçişinde bar taşımak go('/inbox') dal değişiminde çalışmıyordu).
//
// 2026-11-05 (Anıl):
//   • Cam alt bar artık BURADA DEĞİL: tüm rotaların üstünde yüzen tek bar
//     (shell/floating_bar.dart, MaterialApp.builder). Fal ekranlarında da aynı yerde durur.
//   • Bar ikonuyla geçiş ANİMASYONSUZ ("tak tak tak"): sayfa anında değişir; yalnız bardaki
//     cam kapsül yayla kayar.
//   • KAYDIRMA ile geçiş: çağrılan sayfa kaydırma yönünden gelip ötekinin ÜSTÜNÜ örter
//     ("nereden ne çağırılıyorsa o diğerinin üzerini örtsün animasyonla") + güçlü titreşim.
//     Ör. gelen kutusunda sağa kaydırma → ana menü SOLDAN gelip gelen kutusunu örter.
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
import 'package:flutter/services.dart';
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

/// Kaydırmayla geçişte gelen sayfanın geldiği yön (null = bar dokunuşu → anında).
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

/// Her yerden sekme değiştir. [entry] verilirse (kaydırma) yeni sayfa o yönden gelip
/// öncekini örter; verilmezse anında. Kapsayıcı dışındaysa (üstte açılmış bir rota)
/// provider'ı ayarlayıp ana ekrana döner.
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

bool Function()? _closeTabOverlays;

/// Sekme dalının navigatöründe kapsayıcının ÜSTÜNE `Navigator.push` ile açılmış sayfaları
/// (ör. Gelen Kutusu → fal detayı) kapatır; kapattıysa true. Bu sayfalar go_router'a
/// görünmez (rota hâlâ /home) → yüzen bar dokunuşu yalnız sekmeyi değiştirip detayı açık
/// bırakıyordu (Anıl, 2026-11-08: "fal içindeyken alt navigator çalışmıyor").
bool closeMainTabsOverlays() => _closeTabOverlays?.call() ?? false;

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
  late int _current;
  final Set<int> _built = {};

  /// Kaydırmayla geçiş: gelen sayfa [_entryDir] yönünden kayıp çıkan sayfanın ([_from])
  /// üstünü örter. Çıkan sayfa altta KIMILDAMAZ.
  // initState'te kurulur (late tembel kurulum dispose sırasında ticker açmaya çalışıyordu).
  late final AnimationController _cover;
  late final CurvedAnimation _coverCurve;
  int? _from;
  TabEntry? _entryDir;
  TabEntry? _pendingEntry;

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
    _cover = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _coverCurve = CurvedAnimation(parent: _cover, curve: Curves.easeOutCubic);
    _closeTabOverlays = _popOverlays;
  }

  /// Bkz. [closeMainTabsOverlays].
  bool _popOverlays() {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) return false;
    Navigator.of(context).popUntil((r) => r == route);
    return true;
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
    if (_closeTabOverlays == _popOverlays) _closeTabOverlays = null;
    _releaseBack();
    _coverCurve.dispose();
    _cover.dispose();
    super.dispose();
  }

  void _select(int tab, {TabEntry? entry}) {
    _pendingEntry = entry;
    final notifier = ref.read(mainTabProvider.notifier);
    if (notifier.state == tab) {
      _onTabChanged(tab);
    } else {
      notifier.state = tab; // ref.listen → _onTabChanged
    }
  }

  void _onTabChanged(int tab) {
    final entry = _pendingEntry;
    _pendingEntry = null;
    if (tab == _current) return;
    // Sürmekte olan örtme animasyonu varsa bitir (yeni istek hemen geçerli).
    if (_from != null) {
      _cover.value = 1;
      _from = null;
    }
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (entry == null || reduce) {
      // Bar dokunuşu: anında (Anıl: "tak tak tak").
      setState(() {
        _built.add(tab);
        _current = tab;
      });
      return;
    }
    // Kaydırma: güçlü titreşim + gelen sayfa yönünden gelip öncekini örter.
    HapticFeedback.heavyImpact();
    setState(() {
      _built.add(tab);
      _from = _current;
      _current = tab;
      _entryDir = entry;
    });
    _cover.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && _from != null) setState(() => _from = null);
    });
  }

  Offset _startOffset() => switch (_entryDir ?? TabEntry.right) {
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

  /// Yapı HER ZAMAN aynı (Offstage/TickerMode/SlideTransition) → state kaybolmaz.
  Widget _tab(int tab) {
    final visible = tab == _current || tab == _from;
    final covering = tab == _current && _from != null;
    return Positioned.fill(
      key: ValueKey<int>(tab),
      child: Offstage(
        offstage: !visible,
        child: TickerMode(
          enabled: visible,
          // Yalnız görünen sekmenin kaydırması yüzen bara ulaşır (gizli sekme olayı yutulur).
          child: IgnorePointer(
            ignoring: _from != null, // örtme sırasında çift dokunuş yok
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) => tab != _current,
              child: SlideTransition(
                position: covering
                    ? Tween(begin: _startOffset(), end: Offset.zero).animate(_coverCurve)
                    : const AlwaysStoppedAnimation(Offset.zero),
                child: _page(tab),
              ),
            ),
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
        // Sıra: gizliler, sonra çıkan (altta, sabit), en üstte gelen (örter).
        child: Stack(children: [
          for (final t in _built)
            if (t != _current && t != _from) _tab(t),
          if (_from != null) _tab(_from!),
          _tab(_current),
        ]),
      ),
    );
  }
}
