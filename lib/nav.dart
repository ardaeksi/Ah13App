import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'scaffold/app_scaffold.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'portals/challenges_portal.dart';
import 'portals/leaderboard_portal.dart';
import 'portals/tournament_portal.dart';
import 'portals/deed_detail_portal.dart';
import 'models/deed.dart';

/// GoRouter configuration for app navigation
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    routes: [
      // Auth Routes (No Bottom Nav)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main App Routes (With Bottom Nav)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            redirect: (context, state) => AppRoutes.deeds,
          ),
          GoRoute(
            path: AppRoutes.deeds,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AtibaDeedsPortal(),
            ),
          ),
          GoRoute(
            path: '${AppRoutes.deeds}/:id',
            builder: (context, state) {
              final deed = state.extra;
              if (deed is! Deed) return const DeedDetailPortal(deed: null);
              return DeedDetailPortal(deed: deed);
            },
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LeaderboardPortal(),
            ),
          ),
          GoRoute(
            path: AppRoutes.tournament,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TournamentPortal(),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Route path constants
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  /// Root path kept for web deep-linking; it redirects to [deeds].
  static const String home = '/';
  static const String deeds = '/deeds';
  static const String leaderboard = '/leaderboard';
  static const String tournament = '/tournament';
}
