import 'package:flutter/material.dart';

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
              onPressed: () {
                // TODO: go to login (Day 12)
              },
              child: const Text('ابدأ'),
            ),
          ],
        ),
      ),
    );
  }
}
