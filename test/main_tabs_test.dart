// MainTabsScreen navigasyon testleri (sahte sayfalarla — gerçek ekranlar Hive/servis ister).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/l10n/app_strings.dart';
import 'package:magnus_app/data/models/inbox_item.dart';
import 'package:magnus_app/data/providers.dart';
import 'package:magnus_app/presentation/shell/main_tabs.dart';

class _FakeInbox extends InboxNotifier {
  @override
  List<InboxItem> build() => [];
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${widget.name}:$n'),
            TextButton(onPressed: () => setState(() => n++), child: Text('inc ${widget.name}')),
            TextButton(
              onPressed: () => selectMainTab(context, MainTab.inbox),
              child: Text('git inbox ${widget.name}'),
            ),
            Text('ticker ${widget.name}:${TickerMode.valuesOf(context).enabled}'),
          ]),
        ),
      );
}

Widget _app() => ProviderScope(
      overrides: [
        inboxProvider.overrideWith(_FakeInbox.new),
        l10nProvider.overrideWithValue(AppStrings('tr')),
      ],
      child: MaterialApp(
        home: MainTabsScreen(
          debugPageBuilder: (t) => _Page(const ['P', 'H', 'I'][t]),
        ),
      ),
    );

void main() {
  _routerTests();
  testWidgets('sekme geçişi: state korunur, gizli sekmede ticker kapalı', (tester) async {
    final sem = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    expect(find.text('H:0'), findsOneWidget);
    await tester.tap(find.text('inc H'));
    await tester.pump();
    expect(find.text('H:1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Kullanıcı Bilgileri'));
    await tester.pumpAndSettle();
    expect(find.text('P:0'), findsOneWidget);
    expect(find.text('H:1'), findsNothing, reason: 'ana menü gizli (offstage) olmalı');
    expect(find.text('H:1', skipOffstage: false), findsOneWidget, reason: 'state korunmalı');
    expect(find.text('ticker H:false', skipOffstage: false), findsOneWidget,
        reason: 'gizli sekmede animasyon/ticker çalışmamalı');

    await tester.tap(find.bySemanticsLabel('Ana Menü'));
    await tester.pumpAndSettle();
    expect(find.text('H:1'), findsOneWidget, reason: 'geri gelince sayaç aynı');
    expect(find.text('ticker H:true'), findsOneWidget);
    expect(tester.takeException(), isNull);
    sem.dispose();
  });

  testWidgets('Android geri: ana menü dışındayken ana menüye döner', (tester) async {
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

  testWidgets('sayfa içinden selectMainTab (scope) çalışır', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('git inbox H'));
    await tester.pumpAndSettle();
    expect(find.text('I:0'), findsOneWidget);
    expect(find.text('H:0'), findsNothing);
  });
}

// ── Gerçek go_router yapısı (StatefulShellRoute + kök rota) — Codex: MaterialApp(home:)
//    testi go_router 13.2.5'in popRoute davranışını göremiyordu (sahte geçiyordu).
Widget _routerApp(GoRouter router) => ProviderScope(
      overrides: [
        inboxProvider.overrideWith(_FakeInbox.new),
        l10nProvider.overrideWithValue(AppStrings('tr')),
      ],
      child: MaterialApp.router(routerConfig: router),
    );

GoRouter _router() {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => Scaffold(resizeToAvoidBottomInset: false, body: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => MainTabsScreen(
                debugPageBuilder: (t) => _RoutedPage(const ['P', 'H', 'I'][t]),
              ),
            ),
          ]),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$name:0'),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('DAL DETAY')))),
              child: Text('detay $name'),
            ),
            TextButton(onPressed: () => context.push('/kok'), child: Text('kok $name')),
          ]),
        ),
      );
}


void _routerTests() {
  late bool exited;
  setUp(() => exited = false);

  Future<void> mockExit(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
        (call) async {
      if (call.method == 'SystemNavigator.pop') exited = true;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
  }

  testWidgets('router: inbox sekmesinde geri → ana menü (uygulama KAPANMAZ)', (tester) async {
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

  testWidgets('router: dal detayı ve kök rota açıkken geri önce onları kapatır', (tester) async {
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
    expect(find.text('I:0'), findsOneWidget, reason: 'sekme değişmemeli, sadece detay kapanmalı');

    await tester.tap(find.text('kok I'));
    await tester.pumpAndSettle();
    expect(find.text('KOK ROTA'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('KOK ROTA'), findsNothing);
    expect(find.text('I:0'), findsOneWidget);
    expect(exited, isFalse);
    sem.dispose();
  });
}
