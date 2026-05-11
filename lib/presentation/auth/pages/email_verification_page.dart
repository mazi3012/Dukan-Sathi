import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/session.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        _startResendTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _handleResendEmail() async {
    if (!_canResend || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      // For now, just show a snackbar - in production, implement actual resend logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email has been sent to your email address'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleContinueAnyway() async {
    // Allow users to skip email verification and proceed to shop setup
    // They can always verify later
    Navigator.of(context).pop();
  }

  Future<void> _handleLogout() async {
    await UserSession().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.darkBackground, Color(0xFF1A1D2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Iconsax.sms_notification,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(alignment: Alignment.center),
                  const SizedBox(height: 40),
                  // Title
                  Text(
                    'Verify Your Email',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideX(begin: -0.1),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'We\'ve sent a verification link to:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white54,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms),
                  const SizedBox(height: 8),
                  // Email display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      widget.email,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 40),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Iconsax.info_circle,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Click the verification link in your email to confirm your account.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.blue[200]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.timer_1,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'The link expires in 24 hours.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.blue[200]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms),
                  const SizedBox(height: 40),
                  // Resend button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          _canResend && !_isLoading ? _handleResendEmail : null,
                      icon: const Icon(Iconsax.send_2),
                      label: Text(
                        _canResend
                            ? 'Resend Verification Email'
                            : 'Resend in $_secondsRemaining seconds',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.3),
                        disabledForegroundColor: Colors.white54,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms),
                  const SizedBox(height: 12),
                  // Continue anyway button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _handleContinueAnyway,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.white24,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue to Setup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms),
                  const SizedBox(height: 12),
                  // Logout button
                  TextButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Iconsax.logout, color: Colors.white54),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
