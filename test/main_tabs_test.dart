// MainTabsScreen navigasyon testleri (sahte sayfalarla — gerçek ekranlar Hive/servis ister).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/l10n/app_strings.dart';
import 'package:magnus_app/core/widgets/bar_minimize.dart';
import 'package:magnus_app/core/widgets/glass_tab_bar.dart';
import 'package:magnus_app/data/models/inbox_item.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/shell/floating_bar.dart';
import 'package:magnus_app/presentation/shell/main_tabs.dart';

class _FakeInbox extends InboxNotifier {
  @override
  List<InboxItem> build() => [];
}

/// Titreşim testi: elle fal eklenebilen gelen kutusu.
class _PushInbox extends InboxNotifier {
  @override
  List<InboxItem> build() => [];
  void push(InboxItem i) => state = [...state, i];
}

/// Platform kanalındaki titreşim çağrılarını toplar.
List<String> _recordHaptics(WidgetTester tester) {
  final haptics = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
    return null;
  });
  addTearDown(() =>
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return haptics;
}

/// Rozet testi için sabit gelen kutusu.
class _FixedInbox extends InboxNotifier {
  _FixedInbox(this.items);
  final List<InboxItem> items;
  @override
  List<InboxItem> build() => items;
}

InboxItem _item(String id, {bool locked = false, bool read = false, Duration? unlockIn}) {
  final now = DateTime.now();
  if (unlockIn != null) {
    return InboxItem(
      id: id,
      title: 'Fal',
      text: 'metin',
      date: now.toIso8601String(),
      fortuneTypeKey: 'coffee',
      unlockAt: now.add(unlockIn).toIso8601String(),
    );
  }
  return InboxItem(
    id: id,
    title: 'Fal',
    text: 'metin',
    date: now.subtract(const Duration(minutes: 1)).toIso8601String(),
    isRead: read,
    fortuneTypeKey: 'coffee',
    unlockAt: (locked ? now.add(const Duration(hours: 1)) : now.subtract(const Duration(seconds: 1)))
        .toIso8601String(),
  );
}

/// Durum (sayaç) + ticker durumu gösteren sahte sekme sayfası.
class _Page extends StatefulWidget {
  final String name;
  const _Page(this.name);
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  int n = 0;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.name}:$n'),
          TextButton(
            onPressed: () => setState(() => n++),
            child: Text('inc ${widget.name}'),
          ),
          TextButton(
            onPressed: () => selectMainTab(context, MainTab.inbox),
            child: Text('git inbox ${widget.name}'),
          ),
          Text('ticker ${widget.name}:${TickerMode.valuesOf(context).enabled}'),
        ],
      ),
    ),
  );
}

Widget _app({List<InboxItem>? inbox, Key? key}) => ProviderScope(
  key: key, // farklı anahtar → yeni kapsayıcı (override değişimi için)
  overrides: [
    inbox == null
        ? inboxProvider.overrideWith(_FakeInbox.new)
        : inboxProvider.overrideWith(() => _FixedInbox(inbox)),
    l10nProvider.overrideWithValue(AppStrings('tr')),
  ],
  // Yüzen bar artık sekme kapsayıcısında değil, üst katmanda (floating_bar.dart).
  child: MaterialApp(
    home: FloatingBarHost(
      child: MainTabsScreen(
        debugPageBuilder: (t) => _Page(const ['P', 'H', 'I'][t]),
      ),
    ),
  ),
);

void main() {
  _routerTests();

  testWidgets('kaydırmayla geçiş: gelen sayfa yönünden gelip öncekini örter + güçlü titreşim; bar dokunuşu anında', (
    tester,
  ) async {
    final sem = tester.ensureSemantics();
    final haptics = _recordHaptics(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    // Bar dokunuşu: anında (animasyon yok).
    await tester.tap(find.bySemanticsLabel(RegExp('^Gelen Kutusu')));
    await tester.pump();
    expect(find.text('I:0'), findsOneWidget);
    expect(find.text('H:0'), findsNothing);
    haptics.clear();
    // Kaydırma (gelen kutusunda sağa): ana menü SOLDAN gelip gelen kutusunu örter.
    MainTabsScope.maybeOf(tester.element(find.text('I:0')))!
        .select(MainTab.home, entry: TabEntry.left);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final ix = tester.getCenter(find.text('I:0')).dx;
    final hx = tester.getCenter(find.text('H:0')).dx;
    expect(hx, lessThan(ix - 20), reason: 'gelen sayfa soldan geliyor');
    expect(haptics, contains('HapticFeedbackType.heavyImpact'));
    await tester.pumpAndSettle();
    expect(find.text('I:0'), findsNothing, reason: 'örtülen sayfa geçiş bitince gizli');
    expect(tester.getCenter(find.text('H:0')).dx, closeTo(ix, 1));
    sem.dispose();
  });

  testWidgets('fal titreşimleri: yeni fal → güçlü vuruş; hazırlanan fal açılınca artan üçlü', (
    tester,
  ) async {
    final haptics = _recordHaptics(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        inboxProvider.overrideWith(_PushInbox.new),
        l10nProvider.overrideWithValue(AppStrings('tr')),
      ],
      child: MaterialApp(
        home: FloatingBarHost(
          child: MainTabsScreen(debugPageBuilder: (t) => _Page(const ['P', 'H', 'I'][t])),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(MainTabsScreen)));
    (c.read(inboxProvider.notifier) as _PushInbox)
        .push(_item('yeni', unlockIn: const Duration(milliseconds: 300)));
    await tester.pump();
    expect(haptics.first, 'HapticFeedbackType.heavyImpact', reason: 'fal gönderildi');
    await tester.pump(const Duration(milliseconds: 200));
    haptics.clear();
    // Gerçek saat açılma anını geçsin, sonra rozet zamanlayıcısı tetiklensin.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 420)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(haptics, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
    ], reason: 'falın hazır');
  });
  testWidgets('sekme geçişi: state korunur, gizli sekmede ticker kapalı', (
    tester,
  ) async {
    final sem = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    expect(find.text('H:0'), findsOneWidget);
    await tester.tap(find.text('inc H'));
    await tester.pump();
    expect(find.text('H:1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Kullanıcı Bilgileri'));
    await tester.pumpAndSettle();
    expect(find.text('P:0'), findsOneWidget);
    expect(
      find.text('H:1'),
      findsNothing,
      reason: 'ana menü gizli (offstage) olmalı',
    );
    expect(
      find.text('H:1', skipOffstage: false),
      findsOneWidget,
      reason: 'state korunmalı',
    );
    expect(
      find.text('ticker H:false', skipOffstage: false),
      findsOneWidget,
      reason: 'gizli sekmede animasyon/ticker çalışmamalı',
    );

    await tester.tap(find.bySemanticsLabel('Ana Menü'));
    await tester.pumpAndSettle();
    expect(find.text('H:1'), findsOneWidget, reason: 'geri gelince sayaç aynı');
    expect(find.text('ticker H:true'), findsOneWidget);
    expect(tester.takeException(), isNull);
    sem.dispose();
  });

  testWidgets('Android geri: ana menü dışındayken ana menüye döner', (
    tester,
  ) async {
    final sem = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.tap(find.bySemanticsLabel('Gelen Kutusu'));
    await tester.pumpAndSettle();
    expect(find.text('I:0'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('H:0'), findsOneWidget);
    expect(find.text('I:0'), findsNothing);
    sem.dispose();
  });

  testWidgets('bar sırası Ev · Zarf · Profil; kapsül seçili sekmenin slotunda', (
    tester,
  ) async {
    final sem = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    double pillSlot() {
      final bar = tester.getRect(find.byType(GlassTabBar));
      final pill = tester.getRect(find.byKey(const ValueKey('glassTabBarPill')));
      final slot = (bar.width - 10) / kGlassBarSlots;
      return (pill.center.dx - bar.left - 5 - slot / 2) / slot;
    }

    final home = tester.getCenter(find.bySemanticsLabel('Ana Menü'));
    final inbox = tester.getCenter(find.bySemanticsLabel('Gelen Kutusu'));
    final profile = tester.getCenter(find.bySemanticsLabel('Kullanıcı Bilgileri'));
    expect(home.dx, lessThan(inbox.dx));
    expect(inbox.dx, lessThan(profile.dx));
    expect(pillSlot(), closeTo(0, 0.02));

    await tester.tap(find.bySemanticsLabel('Kullanıcı Bilgileri'));
    await tester.pumpAndSettle();
    expect(find.text('P:0'), findsOneWidget);
    expect(pillSlot(), closeTo(2, 0.02));

    await tester.tap(find.bySemanticsLabel('Gelen Kutusu'));
    await tester.pumpAndSettle();
    expect(find.text('I:0'), findsOneWidget);
    expect(pillSlot(), closeTo(1, 0.02));
    sem.dispose();
  });

  testWidgets('ana menüdeyken eve tekrar dokunuş: sekme aynı, reselect sayacı artar', (
    tester,
  ) async {
    final sem = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    final c = ProviderScope.containerOf(tester.element(find.byType(MainTabsScreen)));
    expect(c.read(mainTabReselectProvider), 0);
    await tester.tap(find.bySemanticsLabel('Ana Menü'));
    await tester.pumpAndSettle();
    expect(c.read(mainTabReselectProvider), 1);
    expect(c.read(mainTabProvider), MainTab.home);
    // Başka sekmeden eve dönüş "tekrar dokunuş" sayılmaz.
    await tester.tap(find.bySemanticsLabel('Gelen Kutusu'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ana Menü'));
    await tester.pumpAndSettle();
    expect(c.read(mainTabReselectProvider), 1);
    sem.dispose();
  });

  testWidgets('zarf rozeti: hazırlanan → turuncu, hepsi hazır → yeşil, okunmamış yok → yok', (
    tester,
  ) async {
    Color? dot() {
      final f = find.byKey(const ValueKey('glassTabBarInboxDot'));
      if (f.evaluate().isEmpty) return null;
      return (tester.widget<Container>(f).decoration! as BoxDecoration).color;
    }

    await tester.pumpWidget(_app(inbox: [_item('a', locked: true), _item('b')], key: const ValueKey(1)));
    expect(dot(), const Color(0xFFFFA62B), reason: 'hazırlanan fal var → turuncu');

    await tester.pumpWidget(_app(inbox: [_item('c'), _item('d', read: true)], key: const ValueKey(2)));
    await tester.pump();
    expect(dot(), const Color(0xFF44FF88), reason: 'hepsi hazır, okunmamış var → yeşil');

    await tester.pumpWidget(_app(inbox: [_item('e', read: true)], key: const ValueKey(3)));
    await tester.pump();
    expect(dot(), isNull, reason: 'okunmamış yok → nokta yok');

    // Zamanla: hazırlanan fal açılma anında kendiliğinden hazır olur → rozet yeşile döner
    // (inboxProvider değişmese de; Codex: aksi hâlde turuncuda takılıyordu).
    await tester.pumpWidget(_app(
      inbox: [_item('f', unlockIn: const Duration(milliseconds: 300))],
      key: const ValueKey(4),
    ));
    await tester.pump();
    expect(dot(), const Color(0xFFFFA62B));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 420)));
    await tester.pump(const Duration(milliseconds: 420));
    expect(dot(), const Color(0xFF44FF88), reason: 'açılma anı geçti → yeşil');
    // Açılma anındaki 'falın hazır' titreşim dizisi (260 ms) tamamlansın.
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('sayfa içinden selectMainTab (scope) çalışır', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('git inbox H'));
    await tester.pumpAndSettle();
    expect(find.text('I:0'), findsOneWidget);
    expect(find.text('H:0'), findsNothing);
  });

  testWidgets('kaydırma: yukarı → bar küçülür, aşağı → büyür, sekme değişince tam boy', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        inboxProvider.overrideWith(_FakeInbox.new),
        l10nProvider.overrideWithValue(AppStrings('tr')),
      ],
      child: MaterialApp(
        home: FloatingBarHost(child: MainTabsScreen(
          debugPageBuilder: (t) => t == MainTab.home
              ? ListView.builder(
                  itemCount: 300,
                  itemExtent: 50,
                  itemBuilder: (_, i) => Text('satır $i'),
                )
              : _Page(const ['P', 'H', 'I'][t]),
        )),
      ),
    ));
    double scale() => tester
        .widget<Transform>(find.byKey(const ValueKey('glassTabBarScale')))
        .transform
        .storage[0]; // x ölçeği (getMaxScaleOnAxis z=1'i de sayar)
    final list = find.byType(ListView);

    expect(scale(), 1.0);
    // Küçük oynama (ölü bölge) barı kımıldatmaz.
    await tester.timedDrag(list, const Offset(0, -30), const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(scale(), 1.0);
    // Yukarı kaydırma → küçük.
    await tester.timedDrag(list, const Offset(0, -200), const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(kBarCompactScale, 0.001));
    // Küçük barda zarfa dokunuş hâlâ doğru sekmeyi açar (Transform dokunuşu da ölçekler).
    // Önce aşağı kaydırma → tam boy (listenin başına varmadan).
    await tester.timedDrag(list, const Offset(0, 90), const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1.0, 0.001));
    // Tekrar küçült, sonra sekme değiştir → tam boy.
    await tester.timedDrag(list, const Offset(0, -200), const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(kBarCompactScale, 0.001));
    await tester.tap(find.bySemanticsLabel('Gelen Kutusu'));
    await tester.pumpAndSettle();
    expect(find.text('I:0'), findsOneWidget);
    expect(scale(), closeTo(1.0, 0.001));
  });

  testWidgets('Kullanıcı Bilgileri sekmesinde bar kaydırmayla KÜÇÜLMEZ (Anıl, 2026-11-06)', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        inboxProvider.overrideWith(_FakeInbox.new),
        l10nProvider.overrideWithValue(AppStrings('tr')),
      ],
      child: MaterialApp(
        home: FloatingBarHost(child: MainTabsScreen(
          debugPageBuilder: (t) => ListView.builder(
            key: ValueKey<String>('liste$t'),
            itemCount: 300,
            itemExtent: 50,
            itemBuilder: (_, i) => const Text('satır'),
          ),
        )),
      ),
    ));
    double scale() => tester
        .widget<Transform>(find.byKey(const ValueKey('glassTabBarScale')))
        .transform
        .storage[0];
    await tester.tap(find.bySemanticsLabel('Kullanıcı Bilgileri'));
    await tester.pumpAndSettle();
    final profil = find.byKey(const ValueKey<String>('liste${MainTab.profile}'));
    await tester.timedDrag(profil, const Offset(0, -300), const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(scale(), 1.0, reason: 'profilde bar hep tam boy, en altta');
    // Ana menüde küçülme sürer.
    await tester.tap(find.bySemanticsLabel('Ana Menü'));
    await tester.pumpAndSettle();
    await tester.timedDrag(find.byKey(const ValueKey<String>('liste${MainTab.home}')),
        const Offset(0, -300), const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(kBarCompactScale, 0.001));
  });
}

// ── Gerçek go_router yapısı (StatefulShellRoute + kök rota) — Codex: MaterialApp(home:)
//    testi go_router 13.2.5'in popRoute davranışını göremiyordu (sahte geçiyordu).
Widget _routerApp(GoRouter router) => ProviderScope(
  overrides: [
    inboxProvider.overrideWith(_FakeInbox.new),
    l10nProvider.overrideWithValue(AppStrings('tr')),
  ],
  child: MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => FloatingBarHost(router: router, child: child!),
  ),
);

GoRouter _router() {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: '/home',
    observers: [FloatingBarRouteObserver()],
    routes: [
      StatefulShellRoute.indexedStack(
        builder:
            (_, __, shell) =>
                Scaffold(resizeToAvoidBottomInset: false, body: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder:
                    (_, __) => MainTabsScreen(
                      debugPageBuilder:
                          (t) => _RoutedPage(const ['P', 'H', 'I'][t]),
                    ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/kok',
        parentNavigatorKey: root,
        builder: (_, __) => const Scaffold(body: Text('KOK ROTA')),
      ),
    ],
  );
}

class _RoutedPage extends StatelessWidget {
  final String name;
  const _RoutedPage(this.name);
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$name:0'),
          TextButton(
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('DAL DETAY')),
                  ),
                ),
            child: Text('detay $name'),
          ),
          TextButton(
            onPressed: () => context.push('/kok'),
            child: Text('kok $name'),
          ),
        ],
      ),
    ),
  );
}

void _routerTests() {
  late bool exited;
  setUp(() => exited = false);

  Color iconColor(WidgetTester tester, int i) =>
      ((tester.widget<CustomPaint>(find.byKey(ValueKey('glassTabBarIcon$i'))).painter! as dynamic)
              .color
          as Color);

  testWidgets('yüzen bar: fal rotasında seçimsiz; dokununca o sekmeye gider ve seçili olur', (
    tester,
  ) async {
    final sem = tester.ensureSemantics();
    await tester.pumpWidget(_routerApp(_router()));
    await tester.pumpAndSettle();
    expect(iconColor(tester, 0), kGlassBarSelectedColor, reason: 'ana menüde ev seçili');
    await tester.tap(find.text('kok H'));
    await tester.pumpAndSettle();
    expect(find.text('KOK ROTA'), findsOneWidget);
    // Fal ekranı (kök rota): bar duruyor ama hiçbir sekme seçili değil.
    expect(find.byKey(const ValueKey('floatingGlassBar')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(iconColor(tester, i), Colors.white, reason: 'ikon  seçimsiz');
    }
    // Profil'e dokun → rota kapanır, profil sekmesi açılır ve seçili olur.
    await tester.tap(find.bySemanticsLabel('Kullanıcı Bilgileri'));
    await tester.pumpAndSettle();
    expect(find.text('KOK ROTA'), findsNothing);
    expect(find.text('P:0'), findsOneWidget);
    expect(iconColor(tester, 2), kGlassBarSelectedColor);
    sem.dispose();
  });

  testWidgets('yüzen bar: diyalog açıkken gizlenir, kapanınca döner', (tester) async {
    await tester.pumpWidget(_routerApp(_router()));
    await tester.pumpAndSettle();
    double opacity() => tester
        .widget<AnimatedOpacity>(find.ancestor(
            of: find.byKey(const ValueKey('floatingGlassBar')),
            matching: find.byType(AnimatedOpacity)))
        .opacity;
    expect(opacity(), 1);
    showDialog<void>(
      context: tester.element(find.text('H:0')),
      builder: (_) => const AlertDialog(content: Text('DIYALOG')),
    );
    await tester.pumpAndSettle();
    expect(find.text('DIYALOG'), findsOneWidget);
    expect(opacity(), 0);
    Navigator.of(tester.element(find.text('DIYALOG'))).pop();
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });


  Future<void> mockExit(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exited = true;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  testWidgets('router: inbox sekmesinde geri → ana menü (uygulama KAPANMAZ)', (
    tester,
  ) async {
    await mockExit(tester);
    final sem = tester.ensureSemantics();
    await tester.pumpWidget(_routerApp(_router()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Gelen Kutusu'));
    await tester.pumpAndSettle();
    expect(find.text('I:0'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('H:0'), findsOneWidget);
    expect(exited, isFalse, reason: 'sekmedeyken geri uygulamayı kapatmamalı');
    // Ana menüde geri → eski davranış: uygulamadan çıkış.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exited, isTrue);
    sem.dispose();
  });

  testWidgets(
    'router: dal detayı ve kök rota açıkken geri önce onları kapatır',
    (tester) async {
      await mockExit(tester);
      final sem = tester.ensureSemantics();
      await tester.pumpWidget(_routerApp(_router()));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Gelen Kutusu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('detay I'));
      await tester.pumpAndSettle();
      expect(find.text('DAL DETAY'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('DAL DETAY'), findsNothing);
      expect(
        find.text('I:0'),
        findsOneWidget,
        reason: 'sekme değişmemeli, sadece detay kapanmalı',
      );

      await tester.tap(find.text('kok I'));
      await tester.pumpAndSettle();
      expect(find.text('KOK ROTA'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('KOK ROTA'), findsNothing);
      expect(find.text('I:0'), findsOneWidget);
      expect(exited, isFalse);
      sem.dispose();
    },
  );
}
