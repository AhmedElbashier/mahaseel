
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../state/auth_controller.dart';
import '../../../core/ui/responsive_scaffold.dart';

class LoginOptionsScreen extends ConsumerStatefulWidget {
  const LoginOptionsScreen({super.key});

  @override
  ConsumerState<LoginOptionsScreen> createState() => _LoginOptionsScreenState();
}

class _LoginOptionsScreenState extends ConsumerState<LoginOptionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return ResponsiveScaffold(
      extendBodyBehindAppBar: true,
      safeTop: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Mahaseel green
              Color(0xFF1976D2), // Mahaseel blue
              // Color(0xFF4CAF50),
              // Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.login_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'مرحباً بعودتك!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'سجل دخولك للوصول إلى حسابك',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Login Options
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _GlassMorphicAuthButton(
                        onPressed: () => context.push('/login/phone'),
                        icon: Icons.smartphone_rounded,
                        label: 'رقم الهاتف',
                        subtitle: 'سجل دخولك برقم هاتفك',
                        color: const Color(0xFF4CAF50),
                        loading: false,
                      ),

                      const SizedBox(height: 20),

                      _GlassMorphicAuthButton(
                        onPressed: authState.loading ? null : () => _handleGoogleLogin(ref),
                        icon: FontAwesomeIcons.google,
                        label: 'Google',
                        subtitle: 'استخدم حساب Google الخاص بك',
                        color: const Color(0xFFDB4437),
                        loading: authState.loading,
                      ),

                      const SizedBox(height: 20),

                      _GlassMorphicAuthButton(
                        onPressed: authState.loading ? null : () => _handleFacebookLogin(ref),
                        icon: FontAwesomeIcons.facebook,
                        label: 'Facebook',
                        subtitle: 'استخدم حساب Facebook الخاص بك',
                        color: const Color(0xFF1877F2),
                        loading: authState.loading,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Sign up button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'ليس لديك حساب؟',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'إنشاء حساب جديد',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _handleGoogleLogin(WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).loginWithGoogle();
    final pending = ref.read(authControllerProvider).pendingOAuthData;
    if (!mounted || pending == null) return;

    context.go('/oauth/oauth-details', extra: {
      'provider': 'google',    // normalize to lowercase
      'oauthData': pending,
    });
  }

  void _handleFacebookLogin(WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).loginWithFacebook();
    final pending = ref.read(authControllerProvider).pendingOAuthData;
    if (!mounted || pending == null) return;

    context.go('/oauth/oauth-details', extra: {
      'provider': 'facebook',
      'oauthData': pending,
    });
  }

}

class _GlassMorphicAuthButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool loading;

  const _GlassMorphicAuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.loading,
  });

  @override
  State<_GlassMorphicAuthButton> createState() => _GlassMorphicAuthButtonState();
}

class _GlassMorphicAuthButtonState extends State<_GlassMorphicAuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.loading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
