import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/safe_back_button.dart';
import '../state/auth_controller.dart';
import 'package:mahaseel/core/ui/responsive_scaffold.dart';

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
    _nameCtrl = TextEditingController(text: widget.oauthData['name'] ?? '');
    _phoneCtrl = TextEditingController();

    _authSub = ref.listenManual<AuthState>(
      authControllerProvider,
          (prev, next) {
        if (!mounted) return;

        final becameOtp = (prev?.devOtp == null && next.devOtp != null);
        if (becameOtp) {
          context.push('/otp', extra: {'phone': next.phone, 'isOAuth': true});
        }

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

  bool get _isGoogle => widget.provider.toLowerCase().contains('google');

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.white) : null,
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.35), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return ResponsiveScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إكمال البيانات', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: const SafeBackButton(fallbackPath: '/login'),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF1976D2)],
        ),
      ),
      padding: const EdgeInsets.all(24), // keyboard padding added by wrapper
      // 👇 Only pass a Column/Form here — NO extra SafeArea/ScrollView wrappers
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header badge
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Icon(
                  _isGoogle ? Icons.g_mobiledata : Icons.facebook,
                  size: 48,
                  color: _isGoogle ? const Color(0xFFDB4437) : const Color(0xFF1877F2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title & subtitle
            const Text(
              'أكمل بياناتك لإرسال رمز التحقق',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'تم تسجيل الدخول عبر ${widget.provider}. نحتاج رقم هاتفك لتأكيد الحساب.',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isKeyboardOpen ? 16 : 28),

            // Provider/email info (translucent card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    'مزود الدخول: ${widget.provider}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.oauthData['email'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(label: 'الاسم الكامل', hint: 'أدخل اسمك الكامل', icon: Icons.person),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 12),

            // Phone Row: Country + Number
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<String>(
                    value: _countryCode,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF1976D2),
                    iconEnabledColor: Colors.white,
                    decoration: _inputDecoration(label: 'الكود'),
                    items: const [
                      DropdownMenuItem(value: '+249', child: Text('+249')),
                      DropdownMenuItem(value: '+971', child: Text('+971')),
                      DropdownMenuItem(value: '+966', child: Text('+966')),
                      DropdownMenuItem(value: '+20', child: Text('+20')),
                    ],
                    onChanged: (v) => setState(() => _countryCode = v ?? '+249'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'رقم الهاتف',
                      hint: '5xxxxxxxx',
                      icon: Icons.phone,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رقم الهاتف' : null,
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Submit button (matches other gradient buttons)
            _GradientPrimaryButton(
              text: 'تأكيد رقم الهاتف',
              loading: auth.loading,
              onPressed: auth.loading
                  ? null
                  : () async {
                if (!_formKey.currentState!.validate()) return;
                final phone = '$_countryCode${_phoneCtrl.text.trim()}';
                final name = _nameCtrl.text.trim();
                await ref.read(authControllerProvider.notifier).completeOAuthSignup(
                  provider: widget.provider,
                  oauthData: widget.oauthData,
                  name: name,
                  phone: phone,
                );
              },
            ),

            const SizedBox(height: 12),

            if (auth.devOtp != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  'OTP (dev): ${auth.devOtp}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Reusable gradient button that matches your login/OTP style.
class _GradientPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const _GradientPrimaryButton({
    required this.text,
    required this.onPressed,
    required this.loading,
  });

  @override
  State<_GradientPrimaryButton> createState() => _GradientPrimaryButtonState();
}

class _GradientPrimaryButtonState extends State<_GradientPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  late final Animation<double> _scale =
  Tween<double>(begin: 1, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _enabled ? (_) => _controller.forward() : null,
      onTapUp: _enabled ? (_) => _controller.reverse() : null,
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: _enabled
                ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)])
                : null,
            color: _enabled ? null : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: _enabled
                ? [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.text,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
