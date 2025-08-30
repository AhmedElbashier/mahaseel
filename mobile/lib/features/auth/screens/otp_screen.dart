import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/safe_back_button.dart';
import '../state/auth_controller.dart';
import 'package:mahaseel/core/ui/responsive_scaffold.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> with TickerProviderStateMixin {
  static const int _otpLen = 4;

  final List<TextEditingController> _controllers =
  List.generate(_otpLen, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLen, (_) => FocusNode());

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _resendCountdown = 0;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _focusNodes[0].requestFocus();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendCountdown--);
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1) {
      if (index < _otpLen - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit typed: just unfocus. DO NOT auto-verify here.
        _focusNodes[index].unfocus();
        // _verifyOtp();  // ❌ remove this line
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Keep paste handling if you like, but don’t auto-verify there either
    if (value.length > 1) {
      _handlePaste(value, index);
      // Do not call _verifyOtp() here automatically
    }
  }


  void _handlePaste(String pastedText, int startIndex) {
    final digits = pastedText.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < digits.length && (startIndex + i) < _otpLen; i++) {
      _controllers[startIndex + i].text = digits[i];
    }

    final nextIndex = (startIndex + digits.length).clamp(0, _otpLen - 1);
    if (nextIndex < _otpLen) {
      _focusNodes[nextIndex].requestFocus();
    } else {
      _focusNodes[_otpLen - 1].unfocus();
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_submitting) return;
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != _otpLen) return;

    setState(() => _submitting = true);
    final ok = await ref.read(authControllerProvider.notifier).verifyOtp(otp);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok)
    {
      context.go('/home');
    }
  }

  void _resendOtp() async {
    if (_resendCountdown > 0) return;

    final authState = ref.read(authControllerProvider);
    final phone = widget.phone.isNotEmpty ? widget.phone : (authState.phone ?? '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رقم هاتف لإعادة الإرسال')),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).startLogin(phone);
    _startResendCountdown();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال رمز التحقق مرة أخرى')),
    );
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('+249')) {
      return phone.replaceFirst('+249', '+249 ').replaceAllMapped(
        RegExp(r'(\d{3})(\d{3})(\d+)'),
            (m) => '${m.group(1)} ${m.group(2)} ${m.group(3)}',
      );
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      final wasAuthed = prev?.isAuthenticated ?? false;
      if (!wasAuthed && next.isAuthenticated) {
        if (!mounted) return;
        context.go('/home');
      }
      if (next.error != null && next.error != prev?.error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return ResponsiveScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SafeBackButton(fallbackPath: '/login/phone'),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF1976D2)],
        ),
      ),
      padding: const EdgeInsets.all(24), // ResponsiveScaffold adds keyboard bottom padding automatically
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Header
              Text(
                'تأكيد رقم الهاتف',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'تم إرسال رمز التحقق إلى\n'),
                    TextSpan(
                      text: _formatPhone(widget.phone),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isKeyboardOpen ? 20 : 50),

              // OTP panel
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
                ),
                child: Column(
                  children: [
                    const Text(
                      'أدخل رمز التحقق',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_otpLen, _buildOtpField),
                      ),
                    ),
                    if (authState.devOtp != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          'OTP (dev): ${authState.devOtp}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Verify
              _VerifyButton(
                onPressed: (authState.loading || _submitting) ? null : _verifyOtp,
                loading: authState.loading || _submitting,
              ),

              const SizedBox(height: 24),

              // Resend
              Center(
                child: Column(
                  children: [
                    const Text('لم تستلم الرمز؟', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_resendCountdown > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Text(
                          'يمكن إعادة الإرسال خلال $_resendCountdown ثانية',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _resendOtp,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إعادة إرسال الرمز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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

  Widget _buildOtpField(int index) {
    final focused = _focusNodes[index].hasFocus;
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12), // ✅ subtle fill
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? Colors.white : Colors.white.withOpacity(0.5), // ✅
          width: focused ? 2 : 1,
        ),
        boxShadow: focused
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white, // ✅
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onDigitChanged(value, index),
        onTap: () {
          if (_controllers[index].text.isNotEmpty) {
            _controllers[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _controllers[index].text.length),
            );
          }
        },
      ),
    );
  }
}

/// Gradient button that matches Login's "Continue" button style.
class _VerifyButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const _VerifyButton({
    required this.onPressed,
    required this.loading,
  });

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _enabled ? (_) => _controller.forward() : null,
      onTapUp: _enabled ? (_) => _controller.reverse() : null,
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: _enabled
                ? const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // ✅ same as login button
            )
                : null,
            color: _enabled ? null : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
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
                'تأكيد الرمز',
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
