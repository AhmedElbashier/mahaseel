// lib/features/auth/screens/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final TextEditingController _otpCtrl;
  final _formKey = GlobalKey<FormState>();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _otpCtrl = TextEditingController();
    _otpCtrl.addListener(() {
      setState(() {
        _progress = _otpCtrl.text.length / 6;
      });
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم تسجيل الدخول')));
        context.go('/home');
      } else if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل: ${next.error}')));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('رمز التحقق - ${widget.phone}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 24),
              Text(
                'OTP (dev): ${auth.devOtp}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'أدخل الرمز',
                  hintText: '123456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 6) ? 'أدخل الرمز' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final code = _otpCtrl.text.trim();
                        await ref
                            .read(authControllerProvider.notifier)
                            .verifyOtp(code);
                      },
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('تأكيد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

