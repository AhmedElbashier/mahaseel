import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/crops/ui/crop_list_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (ctx, st) => const WelcomeScreen()),
    GoRoute(path: '/home', builder: (ctx, st) => const CropListScreen()),


  ],
);
