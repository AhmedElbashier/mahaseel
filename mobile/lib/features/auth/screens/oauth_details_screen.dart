
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_controller.dart';

class OAuthDetailsScreen extends ConsumerStatefulWidget {
  final String provider;
  final Map<String, dynamic> oauthData;

  const OAuthDetailsScreen({
    super.key,
    required this.provider,
    required this.oauthData,
  });

  @override
  ConsumerState<OAuthDetailsScreen> createState() => _OAuthDetailsScreenState();
}

class _OAuthDetailsScreenState extends ConsumerState<OAuthDetailsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final ProviderSubscription<AuthState> _authSub;

  final _formKey = GlobalKey<FormState>();
  String _countryCode = '+249';

  @override
  void initState() {
    super.initState();
    // Pre-fill name from OAuth data if available
    _nameCtrl = TextEditingController(text: widget.oauthData['name'] ?? '');
    _phoneCtrl = TextEditingController();

    _authSub = ref.listenManual<AuthState>(
      authControllerProvider,
          (prev, next) {
        if (!mounted) return;

        // When OTP is produced, go to OTP screen
        final becameOtp = (prev?.devOtp == null && next.devOtp != null);
        if (becameOtp) {
          context.push('/otp', extra: {'phone': next.phone, 'isOAuth': true});
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
      appBar: AppBar(
        title: Text('إكمال البيانات - ${widget.provider}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // OAuth Provider Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        widget.provider == 'Google' ? Icons.g_mobiledata : Icons.facebook,
                        size: 48,
                        color: widget.provider == 'Google'
                            ? const Color(0xFFDB4437)
                            : const Color(0xFF1877F2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تم تسجيل الدخول بنجاح عبر ${widget.provider}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.oauthData['email'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'يرجى إكمال بياناتك الشخصية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

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
              const Text(
                'رقم الهاتف (مطلوب للتحقق)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

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
                      .completeOAuthSignup(
                    provider: widget.provider,
                    oauthData: widget.oauthData,
                    name: name,
                    phone: phone,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('تأكيد رقم الهاتف'),
              ),

              if (auth.devOtp != null) ...[
                const SizedBox(height: 12),
                Text(
                  'OTP (dev): ${auth.devOtp}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
