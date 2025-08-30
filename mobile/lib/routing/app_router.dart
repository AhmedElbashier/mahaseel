// lib/routing/app_router.dart
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
        path: '/oauth/oauth-details',
        // ✅ null-safe extra + fallback to Riverpod auth state
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              // 1) Try to read from state.extra if present
              String provider = 'unknown';
              Map<String, dynamic> oauthData = const {};

              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                provider   = (extra['provider'] as String?) ?? 'unknown';
                oauthData  = (extra['oauthData'] as Map<String, dynamic>?) ?? const {};
              } else {
                // 2) Fallback: read pending data from the auth controller
                final pending = ref.read(authControllerProvider).pendingOAuthData;
                if (pending != null) {
                  provider  = (pending['provider'] as String?)?.toLowerCase() ?? 'unknown';
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
          // Use state.uri (or state.location depending on your go_router version)
          final loc = state.uri.toString(); // if older go_router: final loc = state.location;

          int indexFromLocation(String loc) {
            if (loc.startsWith('/chats')) return 1;
            if (loc.startsWith('/add-crop')) return 2;
            if (loc.startsWith('/favorites')) return 3;
            if (loc.startsWith('/menu')) return 4;
            // default/home
            return 0;
          }

          final current = indexFromLocation(loc);

          return HomeShell(
            child: child,
            hideTopBar: true,
            currentIndex: current,                         // ✅ dynamic highlight
            onTabSelected: (index) {                       // ✅ navigate within the shell
              switch (index) {
                case 0: context.go('/home'); break;
                case 1: context.go('/chats'); break;
                case 2: context.go('/add-crop'); break;    // keep this consistent
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

          // 🔧 FIX TYPO: make it /add-crop (NOT /add-corp)
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

      // Crop Routes
      GoRoute(
        path: '/crops/:id',
        name: 'cropDetails',
        builder: (ctx, st) {
          final id = int.parse(st.pathParameters['id']!);
          return CropDetailsScreen(id: id);
        },
      ),
      // Map Picker
      GoRoute(
        path: '/map-picker',
        builder: (context, state) => const MapPickerScreen(),
      ),
    ],
  );
});
