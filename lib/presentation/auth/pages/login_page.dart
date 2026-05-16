import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await UserSession().loginWithGoogle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (result['note'] != null) {
          setState(() => _error = result['note'].toString()); // Using _error variable to show info message
        }
        // Navigate to dashboard
        // Note: We don't navigate manually here. UserSession.notifyListeners() will trigger
        // AuthGate (in main.dart) to rebuild and route to ShopSetupPage or MainLayout.
      } else {
        final err = (result is Map) ? (result['error'] ?? 'Authentication failed') : 'No response from authentication';
        setState(() => _error = err.toString());
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString() ?? 'Unknown error during authentication';
      });
      debugPrint('[LoginPage] Google login exception: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
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

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.lightGlass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.12) : AppColors.lightGlassBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderPill(),
              const SizedBox(height: 28),
              
              _buildDescriptionText(),

              if (_error != null) ...[
                const SizedBox(height: 24),
                _buildErrorWidget(),
              ],

              const SizedBox(height: 32),
              _buildGoogleSignInButton(),
              
              const SizedBox(height: 16),
              _buildInfoText(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2);
  }

  Widget _buildHeaderPill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.login, color: Theme.of(context).primaryColor, size: 18),
            const SizedBox(width: 8),
            Text('Welcome Back', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionText() {
    return Center(
      child: Text(
        'Sign in securely with your Google account to access your Dukan Sathi Pro dashboard.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FontAwesomeIcons.google, size: 20, color: Color(0xFFDB4437)), // Google Red
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildInfoText() {
    return Center(
      child: Text(
        'We use Google\'s secure authentication to protect your account.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
          fontSize: 12,
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.warning_2, 
            color: AppColors.error, 
            size: 18
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!, 
              style: TextStyle(
                color: AppColors.error, 
                fontSize: 13
              )
            )
          ),
        ],
      ),
    ).animate().shakeX(duration: 400.ms);
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
                colors: [Theme.of(context).primaryColor.withOpacity(0.15), Colors.transparent],
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
                colors: [AppColors.accent.withOpacity(0.15), Colors.transparent],
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
            borderRadius: BorderRadius.circular(20),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: const Icon(Iconsax.shop, size: 42, color: Colors.white),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        Text(
          'Dukan Sathi Pro',
          style: TextStyle(
            color: Theme.of(context).textTheme.displayLarge?.color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        const SizedBox(height: 8),
        Text(
          'Your AI-Powered Shop Assistant',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), 
            fontSize: 15
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}

