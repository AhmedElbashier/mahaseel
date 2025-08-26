// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_phone_screen.dart';
import '../features/auth/screens/signup_phone_screen.dart';
import '../features/auth/screens/login_options_screen.dart' as login_views;
import '../features/auth/screens/signup_options_screen.dart' as signup_views;
import '../features/auth/screens/oauth_details_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/home/home_shell.dart';
import '../features/crops/screens/crop_list_screen.dart';
import '../features/crops/screens/crop_details_screen.dart';
import '../features/crops/screens/add_crop_screen.dart';
import '../features/location/map_picker_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/support/screens/support_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // // Welcome Screen
      // GoRoute(
      //   path: '/welcome',
      //   builder: (context, state) => const WelcomeScreen(),
      // ),

      // Auth Routes
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
        path: '/oauth/details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OAuthDetailsScreen(
            provider: extra['provider'] as String,
            oauthData: extra['oauthData'] as Map<String, dynamic>,
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
          return HomeShell(
            currentIndex: 0, // or map from state.location
            onTabSelected: (index) {
              switch (index) {
                case 0: context.go('/home'); break;
                case 1: context.go('/profile'); break;
                case 2: context.go('/settings'); break;
                case 3: context.go('/support'); break;
                case 4: context.go('/notifications'); break;
              }
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const CropListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),

      // Crop Routes
      GoRoute(
        path: '/crops/:id',
        name: 'cropDetails',
        builder: (ctx, st) {
          final id = int.parse(st.pathParameters['id']!);
          return CropDetailsScreen(id: id);
        },
      ),

      GoRoute(
        path: '/add-crop',
        builder: (context, state) => const AddCropScreen(),
      ),

      // Map Picker
      GoRoute(
        path: '/map-picker',
        builder: (context, state) => const MapPickerScreen(),
      ),
    ],
  );
});
