// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth & Screens
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_phone_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/state/auth_controller.dart';

// Shell + App pages
import '../features/home/home_shell.dart';
import '../features/crops/screens/crop_list_screen.dart';
import '../features/crops/screens/add_crop_screen.dart';
import '../features/crops/screens/crop_details_screen.dart';
import '../features/location/map_picker_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/support/screens/support_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/profile_screen.dart';

// Expose: are we authenticated?
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isAuthenticated;
});

// Two navigator keys:
// - _rootKey: the app-wide root navigator (outside the shell)
// - _shellKey: the shell's internal navigator (for tabbed content)
final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthed = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    // Start at "/" — redirect below will move unauth users to /login.
    initialLocation: '/',

    routes: [
      // ------------------- PUBLIC/AUTH FLOW -------------------
      GoRoute(
        path: '/',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: const LoginPhoneScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: OtpScreen(phone: st.uri.queryParameters['phone'] ?? ''),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // ------------------- SHELL (BOTTOM NAV) -------------------
      // Only the 4 tabs live inside the shell.
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) {
          final here = GoRouterState.of(context).uri.toString();

          // Title per section (Arabic defaults).
          String title = 'محاصيل';
          if (here.startsWith('/crops/add')) title = 'إضافة محصول';
          if (here.startsWith('/crops/')) title = 'تفاصيل المحصول';
          if (here.startsWith('/support')) title = 'الدعم الفني';
          if (here.startsWith('/settings')) title = 'الإعدادات';
          // NOTE: notifications/profile are not in the shell anymore.

          // Map current route -> one of the 4 tab indices (0..3)
          // IMPORTANT: Never return 4 or 5 here since the bar has 4 tabs.
          int index = 0;
          if (here.startsWith('/crops/add')) {
            index = 1;
          } else if (here.startsWith('/support')) {
            index = 2;
          } else if (here.startsWith('/settings')) {
            index = 3;
          } else {
            index = 0; // '/home' and '/crops' stay on tab 0
          }

          void onNav(int idx) {
            switch (idx) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/crops/add');
                break;
              case 2:
                context.go('/support');
                break;
              case 3:
                context.go('/settings');
                break;
            }
          }

          return HomeShell(
            title: title,
            child: child,
            currentIndex: index,
            onTabSelected: onNav,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (_, __) => const CropListScreen(),
          ),
          GoRoute(
            path: '/crops',
            name: 'crops',
            builder: (_, __) => const CropListScreen(),
          ),
          GoRoute(
            path: '/crops/add',
            name: 'addCrop',
            builder: (_, __) => const AddCropScreen(),
          ),
          GoRoute(
            path: '/crops/:id',
            name: 'cropDetails',
            builder: (ctx, st) {
              final id = int.parse(st.pathParameters['id']!);
              return CropDetailsScreen(id: id);
            },
          ),
          GoRoute(
            path: '/support',
            name: 'support',
            builder: (_, __) => const SupportScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/map-picker',
            name: 'map_picker',
            builder: (_, __) => const MapPickerScreen(),
          ),
        ],
      ),

      // ------------------- TOP-LEVEL OVERLAYS -------------------
      // These are OUTSIDE the shell and will be pushed on top (no tab index change).
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],

    // ------------------- REDIRECTS (AUTH GATE) -------------------
    // Keep this pure: only read state, don't do side effects here.
    redirect: (ctx, st) {
      final here = st.matchedLocation;
      final isAuthFlow = here == '/login' || here.startsWith('/otp');
      final isWelcome  = here == '/';

      // Any route that requires auth?
      final isShellRoute = here.startsWith('/home') ||
          here.startsWith('/crops') ||
          here.startsWith('/support') ||
          here.startsWith('/settings') ||
          here.startsWith('/map-picker') ||
          // overlays also require auth
          here.startsWith('/notifications') ||
          here.startsWith('/profile');

      if (!isAuthed && isShellRoute) {
        return '/login';
      }
      if (isAuthed && (isWelcome || isAuthFlow)) {
        return '/home';
      }
      return null;
    },
  );
});
