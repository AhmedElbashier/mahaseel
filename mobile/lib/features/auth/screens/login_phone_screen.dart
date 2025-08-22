// lib/features/auth/screens/login_phone_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_controller.dart';

class LoginPhoneScreen extends ConsumerWidget {
  const LoginPhoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final phoneCtrl = TextEditingController();

    ref.listen(authControllerProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${next.error}')));
      } else if (!next.loading && next.phone != null) {
        context.push('/otp?phone=${next.phone}');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: auth.loading ? null : () async {
                final phone = phoneCtrl.text.trim();
                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل رقم الهاتف')));
                  return;
                }
                await ref.read(authControllerProvider.notifier).startLogin(phone);
              },
              child: auth.loading ? const CircularProgressIndicator() : const Text('متابعة'),
            ),
            if (auth.devOtp != null) ...[
              const SizedBox(height: 12),
              Text('OTP (dev): ${auth.devOtp}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}
