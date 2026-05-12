import 'package:go_router/go_router.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/core/widgets/main_shell.dart';
import 'package:vstream/features/auth/presentation/screens/login_screen.dart';
import 'package:vstream/features/browse/presentation/screens/home_screen.dart';
import 'package:vstream/features/browse/presentation/screens/search_screen.dart';
import 'package:vstream/features/browse/presentation/screens/my_list_screen.dart';
import 'package:vstream/features/profile/presentation/screens/profile_screen.dart';
import 'package:vstream/features/profile/presentation/screens/account_settings_screen.dart';
import 'package:vstream/features/player/presentation/screens/player_screen.dart';
import 'package:vstream/shared/services/auth_service.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = AuthService.currentUser() != null;
    final isGoingToLogin = state.matchedLocation == '/login';
    if (!isLoggedIn && !isGoingToLogin) return '/login';
    if (isLoggedIn && isGoingToLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => AppTheme.customTransition(
        context,
        state,
        const LoginScreen(),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => AppTheme.customTransition(
              context,
              state,
              const HomeScreen(),
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => AppTheme.customTransition(
              context,
              state,
              const SearchScreen(),
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/mylist',
            pageBuilder: (context, state) => AppTheme.customTransition(
              context,
              state,
              const MyListScreen(),
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => AppTheme.customTransition(
              context,
              state,
              const ProfileScreen(),
            ),
            routes: [
              GoRoute(
                path: 'account',
                pageBuilder: (context, state) => AppTheme.customTransition(
                  context,
                  state,
                  const AccountSettingsScreen(),
                ),
              ),
            ],
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/player/:id',
      pageBuilder: (context, state) => AppTheme.customTransition(
        context,
        state,
        PlayerScreen(videoId: state.pathParameters['id']!),
      ),
    ),
  ],
);
