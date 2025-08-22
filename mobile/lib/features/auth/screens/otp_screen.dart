// lib/features/auth/screens/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_controller.dart';

class OtpScreen extends ConsumerWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final otpCtrl = TextEditingController();

    ref.listen(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدخول')));
        context.go('/home');
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${next.error}')));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('رمز التحقق - $phone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('OTP (dev): ${auth.devOtp}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            TextFormField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'أدخل الرمز'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: auth.loading ? null : () async {
                final code = otpCtrl.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل الرمز')));
                  return;
                }
                await ref.read(authControllerProvider.notifier).verifyOtp(code);
              },
              child: auth.loading ? const CircularProgressIndicator() : const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}
