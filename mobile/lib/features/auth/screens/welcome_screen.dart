import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاصيل')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
