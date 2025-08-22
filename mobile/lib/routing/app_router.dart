// lib/routing/app_router.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_phone_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/crops/screens/crop_list_screen.dart';
import '../features/auth/state/auth_controller.dart';

/// Minimal Listenable that triggers router refreshes from a Stream.
class StreamRouterRefresh extends ChangeNotifier {
  StreamRouterRefresh(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter(WidgetRef ref) {
  final authNotifier = ref.read(authControllerProvider.notifier);

  return GoRouter(
    // refresh when auth state stream emits
    refreshListenable: StreamRouterRefresh(authNotifier.stream),

    routes: [
      GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, st) => OtpScreen(
          phone: st.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(path: '/home', builder: (_, __) => const CropListScreen()),
    ],

    redirect: (ctx, st) {
      final auth = ref.read(authControllerProvider);

      // current route
      final here = st.matchedLocation; // e.g. '/login', '/home', etc.
      final isAuthFlow = here.startsWith('/login') || here.startsWith('/otp');

      if (!auth.isAuthenticated && here == '/home') {
        return '/login';
      }

      if (auth.isAuthenticated && (here == '/' || isAuthFlow)) {
        return '/home';
      }

      return null; // no redirect
    },
  );
}
