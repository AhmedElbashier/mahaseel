
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../state/auth_controller.dart';

class LoginOptionsScreen extends ConsumerWidget {
  const LoginOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              'اختر طريقة تسجيل الدخول',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Phone Login Button
            _AuthButton(
              onPressed: () => context.push('/login/phone'),
              icon: Icons.phone,
              label: 'رقم الهاتف',
              color: const Color(0xFF4CAF50),
              loading: false,
            ),

            const SizedBox(height: 16),

            // Google Login Button
            _AuthButton(
              onPressed: authState.loading ? null : () => _handleGoogleLogin(ref),
              icon: FontAwesomeIcons.google,
              label: 'Google',
              color: const Color(0xFFDB4437),
              loading: authState.loading,
            ),

            const SizedBox(height: 16),

            // Facebook Login Button
            _AuthButton(
              onPressed: authState.loading ? null : () => _handleFacebookLogin(ref),
              icon: FontAwesomeIcons.facebook,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              loading: authState.loading,
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ليس لديك حساب؟ '),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text('إنشاء حساب جديد'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleLogin(WidgetRef ref) async {
    // TODO: Implement Google OAuth
    await ref.read(authControllerProvider.notifier).loginWithGoogle();
  }

  void _handleFacebookLogin(WidgetRef ref) async {
    // TODO: Implement Facebook OAuth
    await ref.read(authControllerProvider.notifier).loginWithFacebook();
  }
}

class _AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;

  const _AuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: loading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : FaIcon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
