
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../state/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // bool _navigated = false; // prevent double navigation

  @override
  void initState() {
    super.initState();
    _routeAfterReady();
  }
  Future<void> _routeAfterReady() async {
    // Wait at least 2s
    await Future.delayed(const Duration(seconds: 2));

    // Also wait until auth bootstrap finishes
    while (mounted && !ref.read(authControllerProvider).bootstrapped) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;
    final s = ref.read(authControllerProvider);
    context.go(s.isAuthenticated && s.user != null ? '/home' : '/login');
  }


  // Future<void> _checkAuthStatus() async {
  //   await Future.delayed(const Duration(seconds: 3)); // always wait 2s
  //   if (!mounted || _navigated) return;
  //
  //   final auth = ref.read(authControllerProvider);
  //   final toHome = auth.isAuthenticated && auth.user != null;
  //
  //   _navigated = true;
  //   context.go(toHome ? '/home' : '/login');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // Color(0xFF4CAF50),
              // Color(0xFF2E7D32),
              Color(0xFF2E7D32), // Mahaseel green
              Color(0xFF1976D2), // Mahaseel blue
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Lottie.asset(
                  'assets/splash.json',
                  width: 120,
                  height: 120,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'محاصيل',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'منصة تسويق المحاصيل الزراعية',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
