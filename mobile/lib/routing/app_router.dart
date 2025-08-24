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
import '../features/settings/screens/settings_screen.dart';
import '../features/support/screens/support_screen.dart';

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isAuthenticated;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthed = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    // Start at "/" — redirect will send unauth users to /login automatically.
    initialLocation: '/',

    routes: [
      // ---------- Auth-only routes ----------
      GoRoute(
        path: '/',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: const LoginPhoneScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: OtpScreen(
            phone: st.uri.queryParameters['phone'] ?? '',
          ),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // ---------- App shell (bottom navigation + app bar) ----------
      ShellRoute(
        builder: (context, state, child) {
          final here = GoRouterState.of(context).uri.toString();
          String title = 'محاصيل'; // default

          if (here.startsWith('/crops/add')) title = 'إضافة محصول';
          if (here.startsWith('/crops/')) title = 'تفاصيل المحصول';
          if (here.startsWith('/support')) title = 'الدعم الفني';
          if (here.startsWith('/settings')) title = 'الإعدادات';

          int index = 0;
          if (here.startsWith('/crops/add')) index = 1;
          else if (here.startsWith('/support')) index = 2;
          else if (here.startsWith('/settings')) index = 3;
          else index = 0; // home & crops routes

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
        ],
      ),
    ],

    // ---------- Redirect rules (auth gate) ----------
    // ❗ Keep this PURE: READ ONLY. No writes/bootstraps here.
    redirect: (ctx, st) {
      final here = st.matchedLocation;
      final isAuthFlow = here == '/login' || here.startsWith('/otp');
      final isWelcome  = here == '/';

      final isShellRoute = here.startsWith('/home') ||
          here.startsWith('/crops') ||
          here.startsWith('/support') ||
          here.startsWith('/settings');

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
