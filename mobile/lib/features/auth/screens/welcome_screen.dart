import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاصيل')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(
              'https://assets2.lottiefiles.com/packages/lf20_jcikwtux.json',
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 24),
            const Text('أهلاً بك في محاصيل'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push('/login'),
              child: const Text('ابدأ'),
            ),
          ],
        ),
      ),
    );
  }
}
