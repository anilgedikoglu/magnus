// Sol kenardan sağa kaydır = geri (EdgeSwipeBack) — gerçek GoRouter ile.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:magnus_app/core/widgets/edge_swipe_back.dart';
import 'package:magnus_app/core/widgets/swipe_back.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _branchKey = GlobalKey<NavigatorState>();

Widget _page(String label, {Widget? extra}) => Scaffold(
      body: SizedBox.expand(
        child: Column(children: [Text(label), if (extra != null) Expanded(child: extra)]),
      ),
    );

int innerSteps = 0;

GoRouter _router() => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => shell,
          branches: [
            StatefulShellBranch(navigatorKey: _branchKey, routes: [
              GoRoute(path: '/home', builder: (_, __) => _page('HOME')),
            ]),
          ],
        ),
        GoRoute(
            path: '/a', parentNavigatorKey: _rootKey, builder: (_, __) => _page('A')),
        GoRoute(
          path: '/locked',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const PopScope(canPop: false, child: Scaffold(body: Text('LOCKED'))),
        ),
        GoRoute(
          path: '/steps',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => SwipeBack(
            onSwipeBack: () => innerSteps++,
            child: _page('STEPS'),
          ),
        ),
        GoRoute(
          path: '/list',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => Scaffold(
            body: Column(children: [
              const Text('LIST'),
              SizedBox(
                height: 200,
                child: ListView(
                  key: const ValueKey('hlist'),
                  scrollDirection: Axis.horizontal,
                  children: [for (var i = 0; i < 20; i++) SizedBox(width: 120, child: Text('k$i'))],
                ),
              ),
            ]),
          ),
        ),
        GoRoute(
          path: '/edgeonly',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => Scaffold(
            body: NoEdgeSwipeBack(
              edgeOnly: true,
              child: GestureDetector(
                onHorizontalDragEnd: (_) {},
                child: const SizedBox.expand(child: Text('EDGEONLY')),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/wheel',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => Scaffold(
            body: Align(
              alignment: Alignment.centerLeft,
              child: NoEdgeSwipeBack(
                child: GestureDetector(
                  onPanUpdate: (_) {},
                  child: const SizedBox(width: 200, height: 600, child: Text('WHEEL')),
                ),
              ),
            ),
          ),
        ),
      ],
    );

Future<GoRouter> _pump(WidgetTester t) async {
  final router = _router();
  await t.pumpWidget(MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => EdgeSwipeBack(router: router, child: child!),
  ));
  await t.pumpAndSettle();
  return router;
}

Future<void> _swipe(WidgetTester t,
    {double startX = 8, double dx = 140, double dy = 0, double y = 400}) async {
  final g = await t.startGesture(Offset(startX, y));
  for (var i = 1; i <= 6; i++) {
    await g.moveBy(Offset(dx / 6, dy / 6));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await t.pumpAndSettle();
}

void main() {
  setUp(() => innerSteps = 0);

  testWidgets('itilmiş sayfada sol kenardan kaydırma geri götürür', (t) async {
    final r = await _pump(t);
    r.push('/a');
    await t.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    await _swipe(t);
    expect(find.text('A'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('ekranın ortasından soldan sağa kaydırma da geri götürür', (t) async {
    final r = await _pump(t);
    r.push('/a');
    await t.pumpAndSettle();
    await _swipe(t, startX: 160);
    expect(find.text('A'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('yatay listeyi kaydırmak geri götürmez', (t) async {
    final r = await _pump(t);
    r.push('/list');
    await t.pumpAndSettle();
    // Listeyi biraz sola kaydır (sağa çekince geri kayabilsin), sonra sağa çek.
    await t.drag(find.byKey(const ValueKey('hlist')), const Offset(-300, 0));
    await t.pumpAndSettle();
    await _swipe(t, startX: 160, y: 100); // listenin üstünde
    expect(find.text('LIST'), findsOneWidget);
  });

  testWidgets('"yalnız kenar" alanında ortadan kaydırma geri götürmez, kenardan götürür', (t) async {
    final r = await _pump(t);
    r.push('/edgeonly');
    await t.pumpAndSettle();
    await _swipe(t, startX: 160);
    expect(find.text('EDGEONLY'), findsOneWidget);
    await _swipe(t, startX: 8);
    expect(find.text('EDGEONLY'), findsNothing);
  });

  testWidgets('kısa ya da dikey kaydırma geri götürmez', (t) async {
    final r = await _pump(t);
    r.push('/a');
    await t.pumpAndSettle();
    await _swipe(t, dx: 40); // eşik altı
    await _swipe(t, dx: 80, dy: 300); // dikey baskın
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('kökte (ana sekme) hiçbir şey yapmaz, uygulamayı kapatmaz', (t) async {
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
        (c) async {
      calls.add(c.method);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await _pump(t);
    await _swipe(t);
    expect(find.text('HOME'), findsOneWidget);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    expect(find.byKey(const ValueKey('edge-back-hint')), findsNothing);
  });

  testWidgets('PopScope(canPop:false) sayfası kapanmaz, gösterge çıkmaz', (t) async {
    final r = await _pump(t);
    r.push('/locked');
    await t.pumpAndSettle();
    final g = await t.startGesture(const Offset(8, 400));
    await g.moveBy(const Offset(90, 0));
    await t.pump();
    expect(find.byKey(const ValueKey('edge-back-hint')), findsNothing);
    await g.up();
    await t.pumpAndSettle();
    expect(find.text('LOCKED'), findsOneWidget);
  });

  testWidgets('ekranın kendi SwipeBack i önceliklidir: tek aksiyon, sayfa kapanmaz', (t) async {
    final r = await _pump(t);
    r.push('/steps');
    await t.pumpAndSettle();
    await _swipe(t);
    expect(innerSteps, 1);
    expect(find.text('STEPS'), findsOneWidget);
  });

  testWidgets('dal navigatörüne itilmiş sayfa (gelen kutusu detayı gibi) kapanır', (t) async {
    await _pump(t);
    _branchKey.currentState!.push(MaterialPageRoute(builder: (_) => _page('DETAY')));
    await t.pumpAndSettle();
    expect(find.text('DETAY'), findsOneWidget);
    await _swipe(t);
    expect(find.text('DETAY'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('kökte açık pencere varsa önce o kapanır, alttaki detay kalır', (t) async {
    await _pump(t);
    _branchKey.currentState!.push(MaterialPageRoute(builder: (_) => _page('DETAY')));
    await t.pumpAndSettle();
    showDialog<void>(
      context: _rootKey.currentContext!,
      builder: (_) => const AlertDialog(content: Text('PENCERE')),
    );
    await t.pumpAndSettle();
    await _swipe(t);
    expect(find.text('PENCERE'), findsNothing);
    expect(find.text('DETAY'), findsOneWidget);
  });

  testWidgets('NoEdgeSwipeBack alanında başlayan sürükleme geri götürmez', (t) async {
    final r = await _pump(t);
    r.push('/wheel');
    await t.pumpAndSettle();
    await _swipe(t);
    expect(find.text('WHEEL'), findsOneWidget);
  });

  testWidgets('ikinci parmak inince geri iptal olur', (t) async {
    final r = await _pump(t);
    r.push('/a');
    await t.pumpAndSettle();
    final g1 = await t.startGesture(const Offset(8, 300));
    final g2 = await t.startGesture(const Offset(200, 500));
    await g1.moveBy(const Offset(140, 0));
    await t.pump();
    await g1.up();
    await g2.up();
    await t.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('önce dikey başlayıp sonra sağa dönen hareket geri götürmez (Codex)', (t) async {
    final r = await _pump(t);
    r.push('/a');
    await t.pumpAndSettle();
    final g = await t.startGesture(const Offset(8, 300));
    await g.moveBy(const Offset(0, 5)); // slop altı: karar yok
    await t.pump();
    await g.moveBy(const Offset(0, 60)); // dikey → kalıcı iptal
    await t.pump();
    await g.moveBy(const Offset(160, 0)); // sonra sağa
    await t.pump();
    expect(find.byKey(const ValueKey('edge-back-hint')), findsNothing);
    await g.up();
    await t.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('çekerken gösterge görünür, bırakınca kaybolur', (t) async {
    final r = await _pump(t);
    r.push('/a');
    await t.pumpAndSettle();
    final g = await t.startGesture(const Offset(8, 400));
    await g.moveBy(const Offset(40, 0));
    await t.pump();
    expect(find.byKey(const ValueKey('edge-back-hint')), findsOneWidget);
    await g.moveBy(const Offset(-38, 0)); // geri çek → iptal
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('edge-back-hint')), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });
}
