// lib/features/auth/screens/login_phone_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_controller.dart';

class LoginPhoneScreen extends ConsumerStatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  ConsumerState<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends ConsumerState<LoginPhoneScreen> {
  late final TextEditingController _phoneCtrl;
  late final ProviderSubscription<AuthState> _authListener;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController();
    _authListener = ref.listen(authControllerProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: ${next.error}')),
        );
      } else if (!next.loading && next.phone != null) {
        context.push('/otp?phone=${next.phone}');
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _authListener.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: auth.loading ? null : () async {
                final phone = _phoneCtrl.text.trim();
                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('أدخل رقم الهاتف')),
                  );
                  return;
                }
                await ref.read(authControllerProvider.notifier).startLogin(phone);
              },
              child: auth.loading
                  ? const CircularProgressIndicator()
                  : const Text('متابعة'),
            ),
            if (auth.devOtp != null) ...[
              const SizedBox(height: 12),
              Text(
                'OTP (dev): ${auth.devOtp}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
