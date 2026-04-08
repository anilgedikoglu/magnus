import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_theme.dart';
import 'data/providers.dart';
import 'presentation/astrology/astrology_screen.dart';
import 'presentation/olumlama/olumlama_screen.dart';
import 'presentation/ozlusoz/ozlusoz_screen.dart';
import 'presentation/chat/chat_screen.dart';
import 'presentation/coffee/coffee_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/inbox/inbox_screen.dart';
import 'presentation/motivation/motivation_screen.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/shell/app_shell.dart';
import 'presentation/tarot/tarot_screen.dart';
import 'presentation/tarot/tarot_result_screen.dart';
import 'presentation/tarot/tarot_type_screen.dart';
import 'presentation/tarot/single_tarot_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _inboxKey = GlobalKey<NavigatorState>(debugLabel: 'inbox');

final routerProvider = Provider<GoRouter>((ref) {
  final isOnboarded = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: isOnboarded ? '/home' : '/onboarding',
    redirect: (context, state) {
      final onboarded = ref.read(onboardingCompleteProvider);
      final path = state.uri.path;

      // If not onboarded, only allow /onboarding
      if (!onboarded && path != '/onboarding') return '/onboarding';

      // If already onboarded, redirect away from onboarding
      if (onboarded && path == '/onboarding') return '/home';

      return null;
    },
    routes: [
      // ── Onboarding (standalone, no bottom nav) ───────────────────────────
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ChatScreen(),
      ),

      // ── Main shell (bottom nav: Home + Inbox) ───────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _inboxKey,
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (_, __) => const InboxScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Fullscreen fortune routes (no bottom nav) ────────────────────────
      GoRoute(
        path: '/coffee',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CoffeeScreen(),
      ),
      GoRoute(
        path: '/tarot',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const TarotTypeScreen(),
      ),
      GoRoute(
        path: '/tarot/klasik',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const TarotScreen(),
      ),
      GoRoute(
        path: '/tarot/ask',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SingleTarotScreen(type: 'ask'),
      ),
      GoRoute(
        path: '/tarot/dilek',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SingleTarotScreen(type: 'dilek'),
      ),
      GoRoute(
        path: '/tarot/sans',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SingleTarotScreen(type: 'sans'),
      ),
      GoRoute(
        path: '/astrology',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AstrologyScreen(),
      ),
      GoRoute(
        path: '/motivation',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MotivationScreen(),
      ),
      GoRoute(
        path: '/ozlusoz',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const OzluSozScreen(),
      ),
      GoRoute(
        path: '/olumlama',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const OlumlamaScreen(),
      ),
      GoRoute(
        path: '/inbox-full',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const InboxScreen(),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/tarot_result/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            TarotResultScreen(inboxItemId: state.pathParameters['id']!),
      ),
    ],
  );
});

class MagnusApp extends ConsumerWidget {
  const MagnusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Magnus',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
