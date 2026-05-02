import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_theme.dart';
import 'data/providers.dart';
import 'presentation/astrology/astrology_screen.dart';
import 'presentation/astroloji/astroloji_screen.dart';
import 'presentation/astrotakvim/astro_takvim_screen.dart';
import 'presentation/olumlama/olumlama_screen.dart';
import 'presentation/ozlusoz/ozlusoz_screen.dart';
import 'presentation/chat/chat_screen.dart';
import 'presentation/coffee/coffee_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/inbox/inbox_screen.dart';
import 'presentation/motivation/motivation_screen.dart';
import 'presentation/biyoritim/biyoritim_screen.dart';
import 'presentation/dogumharitasi/dogumharitasi_screen.dart';
import 'presentation/kaderkitabi/kaderkitabi_screen.dart';
import 'presentation/numeroloji/numeroloji_screen.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/shell/app_shell.dart';
import 'presentation/tarot/tarot_screen.dart';
import 'presentation/tarot/tarot_result_screen.dart';
import 'presentation/tarot/tarot_type_screen.dart';
import 'presentation/tarot/single_tarot_screen.dart';
import 'presentation/dertortagi/dertortagi_screen.dart';
import 'presentation/acigercekler/acigercekler_screen.dart';
import 'presentation/kehanet/kehanet_menu_screen.dart';
import 'presentation/kehanet/kahinler_menu_screen.dart';
import 'presentation/kehanet/parmak_surtme_screen.dart';
import 'presentation/kehanet/kahin_metin_screen.dart';
import 'presentation/kehanet/faloya_screen.dart';
import 'presentation/kehanet/maganda_screen.dart';
import 'presentation/kehanet/tamua_screen.dart';
import 'presentation/kehanet/yana_screen.dart';
import 'presentation/kehanet/niyet_screen.dart';
import 'presentation/kehanet/yuz_fali_kimin_screen.dart';
import 'presentation/kehanet/el_fali_screen.dart';
import 'presentation/kehanet/yuz_fali_foto_screen.dart';
import 'presentation/durugoru/durugoru_screen.dart';
import 'presentation/ruya/ruya_yorumu_screen.dart';
import 'presentation/kadercarki/kadercarki_screen.dart';
import 'presentation/askuyumu/askuyumu_screen.dart';
import 'presentation/iching/iching_screen.dart';
import 'presentation/japonfali/japonfali_screen.dart';

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
        path: '/astroloji',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const AstrolojiScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/biyoritim',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const BiyoritimScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/dogumharitasi',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const DogumHaritasiScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/kaderkitabi',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const KaderKitabiScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/numeroloji',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const NumerologiScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/astrotakvim',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const AstroTakvimScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/motivation',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MotivationScreen(),
      ),
      GoRoute(
        path: '/dertortagi',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const DertOrtagiScreen(),
      ),
      GoRoute(
        path: '/acigercekler',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AciGerceklerScreen(),
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
        path: '/kehanet',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const KehanetMenuScreen(),
      ),
      GoRoute(
        path: '/kahinler',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const KahinlerMenuScreen(),
      ),
      GoRoute(
        path: '/parmak_surtme',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final kahinId = state.extra as String? ?? 'derun';
          return ParmakSurtmeScreen(kahinId: kahinId);
        },
      ),
      GoRoute(
        path: '/kahin_metin',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final kahinId = state.extra as String? ?? 'derun';
          return KahinMetinScreen(kahinId: kahinId);
        },
      ),
      GoRoute(
        path: '/faloya',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const FaloyaScreen(),
      ),
      GoRoute(
        path: '/maganda',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MagandaScreen(),
      ),
      GoRoute(
        path: '/tamua',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const TamuaScreen(),
      ),
      GoRoute(
        path: '/yana',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const YanaScreen(),
      ),
      GoRoute(
        path: '/niyet',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NiyetScreen(),
      ),
      GoRoute(
        path: '/yuz_fali_kimin',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const YuzFaliKiminScreen(),
      ),
      GoRoute(
        path: '/yuz_fali_foto',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            YuzFaliFotoScreen(kimin: state.extra as String? ?? 'kullanici'),
      ),
      GoRoute(
        path: '/el_fali',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ElFaliScreen(),
      ),
      GoRoute(
        path: '/ruya_yorumu',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RuyaYorumuScreen(),
      ),
      GoRoute(
        path: '/kadercarki',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const KaderCarkiScreen(),
      ),
      GoRoute(
        path: '/ask_uyumu',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AskUyumuScreen(),
      ),
      GoRoute(
        path: '/iching',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const IChingScreen(),
      ),
      GoRoute(
        path: '/japonfali',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const JaponFaliScreen(),
      ),
      GoRoute(
        path: '/durugoru',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const DurugoruScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
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
