
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/safe_back_button.dart';
import '../state/auth_controller.dart';
import '../../../core/ui/responsive_scaffold.dart';

class LoginPhoneScreen extends ConsumerStatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  ConsumerState<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends ConsumerState<LoginPhoneScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPhoneValid = false;

  // Country codes for Sudan and neighboring countries
  final List<Map<String, String>> _countryCodes = [
    {'code': '+249', 'name': 'السودان', 'flag': '🇸🇩'},
    {'code': '+20', 'name': 'مصر', 'flag': '🇪🇬'},
    {'code': '+966', 'name': 'السعودية', 'flag': '🇸🇦'},
    {'code': '+971', 'name': 'الإمارات', 'flag': '🇦🇪'},
    {'code': '+974', 'name': 'قطر', 'flag': '🇶🇦'},
    {'code': '+965', 'name': 'الكويت', 'flag': '🇰🇼'},
    {'code': '+973', 'name': 'البحرين', 'flag': '🇧🇭'},
    {'code': '+968', 'name': 'عُمان', 'flag': '🇴🇲'},
    {'code': '+962', 'name': 'الأردن', 'flag': '🇯🇴'},
    {'code': '+963', 'name': 'سوريا', 'flag': '🇸🇾'},
    {'code': '+964', 'name': 'العراق', 'flag': '🇮🇶'},
  ];

  String _selectedCountryCode = '+249';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _phoneController.addListener(_onPhoneChanged);
    _controller.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    final isValid = phone.length >= 7;
    if (isValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  void _handleContinue() async {
    if (!_isPhoneValid) return;

    final phone = '$_selectedCountryCode${_phoneController.text.trim()}';
    await ref.read(authControllerProvider.notifier).startLogin(phone);

    if (mounted) {
      context.push('/otp', extra: {'phone': phone});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return ResponsiveScaffold(
      extendBodyBehindAppBar: true,
      safeTop: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SafeBackButton(fallbackPath: '/login'),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF1976D2)],
        ),
      ),
      padding: const EdgeInsets.all(24), // ResponsiveScaffold will add keyboard bottom padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Header
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.login_rounded, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text('أدخل رقم هاتفك للمتابعة',
                    style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
              ],
            ),
          ),

          // Responsive gap
          SizedBox(height: isKeyboardOpen ? 16 : 48),

          // Phone input
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  // Country dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        dropdownColor: const Color(0xFF1976D2),
                        style: const TextStyle(color: Colors.white),
                        items: _countryCodes.map((country) {
                          return DropdownMenuItem<String>(
                            value: country['code'],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(country['code']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedCountryCode = value);
                        },
                      ),
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
                  // Phone field
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: InputDecoration(
                        hintText: '123456789',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      ),
                      onChanged: (_) => _onPhoneChanged(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (authState.error != null) ...[
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(authState.error!, style: const TextStyle(color: Colors.red, fontSize: 14))),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // Continue button
          FadeTransition(
            opacity: _fadeAnimation,
            child: _ContinueButton(
              onPressed: _isPhoneValid && !authState.loading ? _handleContinue : null,
              loading: authState.loading,
              enabled: _isPhoneValid,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }


}

class _ContinueButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;

  const _ContinueButton({
    required this.onPressed,
    required this.loading,
    required this.enabled,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
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
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null ? (_) => _controller.reverse() : null,
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            )
                : null,
            color: widget.enabled ? null : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: widget.enabled
                ? [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ]
                : null,
          ),
          child: widget.loading
              ? const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'متابعة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
