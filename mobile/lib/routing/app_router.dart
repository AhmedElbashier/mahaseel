// lib/routing/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mahaseel/features/favorites/screens/favourites_home_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_phone_screen.dart';
import '../features/auth/screens/signup_phone_screen.dart';
import '../features/auth/screens/login_options_screen.dart' as login_views;
import '../features/auth/screens/signup_options_screen.dart' as signup_views;
import '../features/auth/screens/oauth_details_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/chats/screens/chats_list_screen.dart';
import '../features/home/home_shell.dart';
import '../features/crops/screens/crop_list_screen.dart';
import '../features/crops/screens/crop_details_screen.dart';
import '../features/crops/screens/add_crop_screen.dart';
import '../features/location/map_picker_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';

/// 🔔 Bridge Riverpod -> GoRouter.refreshListenable
/// Whenever AuthState changes, we notify listeners so GoRouter re-evaluates `redirect`.
final routerRefreshListenableProvider = Provider<Listenable>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);

  ref.listen<AuthState>(authControllerProvider, (_, __) {
    notifier.value++; // any change triggers a refresh
  }, fireImmediately: false);

  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  bool requiresAuth(String loc) {
    return loc.startsWith('/home') ||
        loc.startsWith('/chats') ||
        loc.startsWith('/add-crop') ||
        loc.startsWith('/favorites') ||
        loc.startsWith('/menu') ||
        loc.startsWith('/crops');
  }

  bool isPublicAuthFlow(String loc) {
    return loc == '/' ||
        loc.startsWith('/login') ||
        loc.startsWith('/signup') ||
        loc.startsWith('/otp') ||
        loc.startsWith('/oauth');
  }

  return GoRouter(
    initialLocation: '/',
    // ✅ make GoRouter refresh when AuthState changes
    refreshListenable: ref.watch(routerRefreshListenableProvider),

    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // 1) Wait until auth bootstrap finishes (prevents early kicks)
      if (!auth.bootstrapped) {
        return loc == '/' ? null : '/';
      }

      final isAuthed = auth.isAuthenticated;
      final needsAuth = requiresAuth(loc);
      final isPublic = isPublicAuthFlow(loc);

      // 2) Not authenticated → allow public auth flow, block protected
      if (!isAuthed && needsAuth) return '/login';

      // 3) Authenticated → keep out of auth flow (login/signup/otp/oauth/splash)
      if (isAuthed && isPublic) return '/home';

      return null;
    },

    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const login_views.LoginOptionsScreen(),
      ),
      GoRoute(
        path: '/login/phone',
        builder: (context, state) => const LoginPhoneScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const signup_views.SignupOptionsScreen(),
      ),
      GoRoute(
        path: '/signup/phone',
        builder: (context, state) => const SignupPhoneScreen(),
      ),
      GoRoute(
        path: '/oauth/oauth-details',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              String provider = 'unknown';
              Map<String, dynamic> oauthData = const {};

              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                provider = (extra['provider'] as String?) ?? 'unknown';
                oauthData = (extra['oauthData'] as Map<String, dynamic>?) ?? const {};
              } else {
                final pending = ref.read(authControllerProvider).pendingOAuthData;
                if (pending != null) {
                  provider = (pending['provider'] as String?)?.toLowerCase() ?? 'unknown';
                  oauthData = pending;
                }
              }

              return OAuthDetailsScreen(
                provider: provider,
                oauthData: oauthData,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final phone = extra?['phone'] as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),

      // Main App Shell
      ShellRoute(
        builder: (context, state, child) {
          final loc = state.uri.toString();

          int indexFromLocation(String loc) {
            if (loc.startsWith('/chats')) return 1;
            if (loc.startsWith('/add-crop')) return 2;
            if (loc.startsWith('/favorites')) return 3;
            if (loc.startsWith('/menu')) return 4;
            return 0; // home
          }

          final current = indexFromLocation(loc);

          return HomeShell(
            child: child,
            hideTopBar: true,
            currentIndex: current,
            onTabSelected: (index) {
              switch (index) {
                case 0: context.go('/home'); break;
                case 1: context.go('/chats'); break;
                case 2: context.go('/add-crop'); break;
                case 3: context.go('/favorites'); break;
                case 4: context.go('/menu'); break;
              }
            },
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const CropListScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/add-crop',
            builder: (context, state) => const AddCropScreen(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavouritesHomeScreen(),
          ),
          GoRoute(
            path: '/menu',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),

      // Details & misc
      GoRoute(
        path: '/crops/:id',
        name: 'cropDetails',
        builder: (ctx, st) {
          final id = int.parse(st.pathParameters['id']!);
          return CropDetailsScreen(id: id);
        },
      ),
      GoRoute(
        path: '/map-picker',
        builder: (context, state) => const MapPickerScreen(),
      ),
    ],
    debugLogDiagnostics: true,
  );
});
