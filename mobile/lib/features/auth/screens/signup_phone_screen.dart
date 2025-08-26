
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../state/auth_controller.dart';

class SignupPhoneScreen extends ConsumerStatefulWidget {
  const SignupPhoneScreen({super.key});

  @override
  ConsumerState<SignupPhoneScreen> createState() => _SignupPhoneScreenState();
}

class _SignupPhoneScreenState extends ConsumerState<SignupPhoneScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final ProviderSubscription<AuthState> _authSub;

  final _formKey = GlobalKey<FormState>();
  String _countryCode = '+249';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lottie.network(
                'https://assets2.lottiefiles.com/packages/lf20_jcikwtux.json',
                height: 150,
                repeat: true,
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  hintText: 'أدخل اسمك الكامل',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
              ),

              const SizedBox(height: 16),

              // Phone Field
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
                        prefixIcon: const Icon(Icons.phone),
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

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;
                  final phone = '$_countryCode${_phoneCtrl.text.trim()}';
                  final name = _nameCtrl.text.trim();
                  await ref
                      .read(authControllerProvider.notifier)
                      .startSignup(name: name, phone: phone);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('إنشاء الحساب'),
              ),

              if (auth.devOtp != null) ...[
                const SizedBox(height: 12),
                Text(
                  'OTP (dev): ${auth.devOtp}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لديك حساب بالفعل؟ '),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('تسجيل الدخول'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
