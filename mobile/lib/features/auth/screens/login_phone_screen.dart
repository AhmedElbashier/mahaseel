// lib/features/auth/screens/login_phone_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../state/auth_controller.dart';

class LoginPhoneScreen extends ConsumerStatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  ConsumerState<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends ConsumerState<LoginPhoneScreen> {
  late final TextEditingController _phoneCtrl;
  late final ProviderSubscription<AuthState> _authSub;

  final _formKey = GlobalKey<FormState>();
  String _countryCode = '+970';

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController();
    _authSub = ref.listenManual<AuthState>(
      authControllerProvider,
          (prev, next) {
        if (!mounted) return;

        // When OTP is produced (dev or real), go to OTP screen once
        final becameOtp = (prev?.devOtp == null && next.devOtp != null);
        if (becameOtp) {
          context.push('/otp', extra: {'phone': next.phone});
        }

        // If an error just appeared, show it
        final gotNewError = (prev?.error != next.error) && next.error != null;
        if (gotNewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _authSub.close();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lottie.network(
                'https://assets2.lottiefiles.com/packages/lf20_jcikwtux.json',
                height: 180,
                repeat: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _countryCode,
                      decoration: InputDecoration(
                        labelText: 'الكود',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: '+249', child: Text('+249')),
                        DropdownMenuItem(value: '+970', child: Text('+970')),
                        DropdownMenuItem(value: '+966', child: Text('+966')),
                      ],
                      onChanged: (v) => setState(() => _countryCode = v ?? '+249'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        hintText: '5xxxxxxxx',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'أدخل رقم الهاتف' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final phone = '$_countryCode${_phoneCtrl.text.trim()}';
                        await ref
                            .read(authControllerProvider.notifier)
                            .startLogin(phone);
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
      ),
    );
  }
}
