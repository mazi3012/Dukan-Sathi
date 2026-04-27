import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/session.dart';
import '../../main/pages/main_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final result = await UserSession().verifyCode(_code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const MainLayout(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: 600.ms,
        ),
      );
    } else {
      setState(() => _error = result['error'] ?? 'Invalid code');
      // Shake and clear on error
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    }
  }

  void _onDigitEntered(int index, String value) {
    if (value.isEmpty) {
      // Backspace: go to previous
      if (index > 0) _focusNodes[index - 1].requestFocus();
      return;
    }
    if (value.length > 1) {
      // Pasted a full code
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 6) {
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = digits[i];
        }
        _focusNodes[5].requestFocus();
        _verify();
        return;
      }
      _controllers[index].text = value[value.length - 1];
    }
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Animated background blobs
          _buildBackgroundBlobs(),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 48),
                    _buildCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.primary.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.accent.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: const Icon(Iconsax.shop, size: 42, color: Colors.white),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        const Text(
          'Dukan Sathi Pro',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        const SizedBox(height: 8),
        const Text(
          'Your AI-Powered Shop Assistant',
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Telegram icon pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF229ED9).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF229ED9).withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.message, color: Color(0xFF229ED9), size: 18),
                      SizedBox(width: 8),
                      Text('Login via Telegram', style: TextStyle(color: Color(0xFF229ED9), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 28),

              // Instructions
              _buildStep(1, 'Open your Telegram bot', '@Sathiaibeta_bot'),
              const SizedBox(height: 12),
              _buildStep(2, 'Send the command', '/login'),
              const SizedBox(height: 12),
              _buildStep(3, 'Enter the 6-digit code below', null),
              const SizedBox(height: 32),

              // Code input
              _buildCodeInput(),
              const SizedBox(height: 24),

              // Error
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.warning_2, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ],
                  ),
                ).animate().shakeX(duration: 400.ms),

              if (_error != null) const SizedBox(height: 16),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _code.length == 6 ? AppColors.primaryGradient : null,
                    color: _code.length == 6 ? null : AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _code.length == 6 ? [
                      BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                    ] : [],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Verify & Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Iconsax.login, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2);
  }

  Widget _buildStep(int num, String title, String? highlight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: Center(
            child: Text('$num', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              if (highlight != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkGlassBorder),
                  ),
                  child: Text(
                    highlight,
                    style: const TextStyle(color: AppColors.primary, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: (300 + num * 80).ms).slideX(begin: -0.1);
  }

  Widget _buildCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          height: 60,
          child: AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: _controllers[i].text.isNotEmpty
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.darkSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _controllers[i].text.isNotEmpty
                    ? AppColors.primary
                    : AppColors.darkGlassBorder,
                width: 1.5,
              ),
              boxShadow: _controllers[i].text.isNotEmpty ? [
                BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10),
              ] : [],
            ),
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 1,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (v) {
                setState(() {});
                _onDigitEntered(i, v);
              },
            ),
          ),
        ).animate().scale(delay: (400 + i * 60).ms, duration: 400.ms, curve: Curves.elasticOut);
      }),
    );
  }
}
