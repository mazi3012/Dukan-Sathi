import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/session.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onBack;

  const LoginPage({super.key, this.onBack});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  String? _infoMessage;
  
  // Tab controller for custom segmented switch
  int _activeTab = 0; // 0 for Google, 1 for Email Link
  
  // Email controller for Magic Link
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _infoMessage = null;
    });

    try {
      final result = await UserSession().loginWithGoogle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (result['note'] != null) {
          setState(() => _infoMessage = result['note'].toString());
        }
      } else {
        final err = result['error'] ?? 'Google authentication failed';
        setState(() => _error = err.toString());
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'An unexpected error occurred during Google sign-in.';
      });
      debugPrint('[LoginPage] Google login exception: $e\n$st');
    }
  }

  Future<void> _handleEmailOtpLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      // Direct integration with Supabase for Passwordless Email OTP (Magic Link)
      // Redirect back to standard scheme or domain
      final String redirectTo = kIsWeb ? Uri.base.origin : 'dukansathi://auth/callback';
      
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectTo,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _infoMessage = 'Magic login link sent! Please check your email inbox and click the link to sign in.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('AuthException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNavigation(context, isDark),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogo(isDark),
                          const SizedBox(height: 36),
                          _buildCard(context, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context, bool isDark) {
    if (widget.onBack == null) return const SizedBox(height: 16);
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: IconButton(
        onPressed: widget.onBack,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : AppColors.lightGlassBorder.withOpacity(0.2),
            ),
          ),
          child: Icon(
            Iconsax.arrow_left_2,
            color: isDark ? Colors.white : AppColors.lightOnSurface,
            size: 20,
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : AppColors.lightGlass,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightGlassBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : AppColors.primary.withOpacity(0.05)),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegmentedControl(isDark),
                const SizedBox(height: 28),
                
                if (_infoMessage != null) ...[
                  _buildSuccessWidget(),
                  const SizedBox(height: 20),
                ],

                if (_error != null) ...[
                  _buildErrorWidget(),
                  const SizedBox(height: 20),
                ],

                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _activeTab == 0
                      ? _buildGoogleLoginView(isDark)
                      : _buildEmailLoginView(isDark),
                ),
                
                const SizedBox(height: 24),
                _buildInfoFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildSegmentedControl(bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _activeTab = 0;
                _error = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _activeTab == 0
                      ? (isDark ? AppColors.primary : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTab == 0
                      ? [
                          BoxShadow(
                            color: isDark
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.user,
                      size: 16,
                      color: _activeTab == 0
                          ? (isDark ? Colors.white : AppColors.lightOnSurface)
                          : (isDark ? Colors.white38 : Colors.black45),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Google',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _activeTab == 0
                            ? (isDark ? Colors.white : AppColors.lightOnSurface)
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _activeTab = 1;
                _error = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _activeTab == 1
                      ? (isDark ? AppColors.primary : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTab == 1
                      ? [
                          BoxShadow(
                            color: isDark
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.sms,
                      size: 16,
                      color: _activeTab == 1
                          ? (isDark ? Colors.white : AppColors.lightOnSurface)
                          : (isDark ? Colors.white38 : Colors.black45),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email Link',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _activeTab == 1
                            ? (isDark ? Colors.white : AppColors.lightOnSurface)
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleLoginView(bool isDark) {
    return Column(
      key: const ValueKey('google_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fast & Secure Sign In',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightOnSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with Google to securely synchronize your store data, AI inventory metrics, and billing invoices in real-time.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleGoogleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : AppColors.primary,
              foregroundColor: isDark ? Colors.black87 : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.black87 : Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.google, size: 18, color: Color(0xFFDB4437)),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ).animate().scale(delay: 150.ms),
      ],
    );
  }

  Widget _buildEmailLoginView(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('email_view'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Magic Login Link',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will send a secure validation link directly to your business email. Tap the link to sign in automatically.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 24),
          // Email Text Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business email';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface),
            decoration: InputDecoration(
              hintText: 'name@business.com',
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
              prefixIcon: Icon(Iconsax.sms, color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.7), size: 18),
              filled: true,
              fillColor: isDark ? Colors.black.withOpacity(0.24) : Colors.black.withOpacity(0.02),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailOtpLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                shadowColor: AppColors.primary.withOpacity(0.3),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.send_2, size: 18),
                        const SizedBox(width: 10),
                        const Text(
                          'Send Magic Link',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.tick_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _infoMessage!,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.warning_2, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().shakeX(duration: 400.ms);
  }

  Widget _buildInfoFooter(bool isDark) {
    return Center(
      child: Text(
        'Secured with corporate-grade OAuth encryption',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? Colors.white30 : Colors.black38,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Pulse glow background
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Iconsax.shop, size: 36, color: Colors.white),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Dukan Sathi Pro',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightOnSurface,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15),
        const SizedBox(height: 6),
        Text(
          'Enter your digital retail companion',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black45,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 250.ms),
      ],
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
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  Colors.transparent,
                ],
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
                colors: [
                  AppColors.accent.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
