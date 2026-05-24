import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/pages/welcome_auth_flow.dart';
import '../../../main.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always use dark brand background to ensure a 100% seamless transition from Android's native dark boot window
    const backgroundColor = AppColors.darkBackground;
    const textColor = Colors.white;
    const taglineColor = Colors.white70;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Radial Glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Central Logo and Tagline - Centered perfectly using Center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rotating & Elastic Scaling Logo Container
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(65),
                    child: Image.asset(
                      'assets/launcher_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                .scale(
                  duration: 900.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(duration: 500.ms)
                .rotate(
                  duration: 900.ms,
                  curve: Curves.easeOutCubic,
                  begin: -0.15,
                  end: 0.0,
                )
                .shimmer(delay: 1.seconds, duration: 1.2.seconds, color: Colors.white24),
                
                const SizedBox(height: 28),
                
                // App Name Text
                Text(
                  'Dukan Sathi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                )
                .animate()
                .fadeIn(delay: 450.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutQuad),
                
                const SizedBox(height: 8),
                
                // tagline: "Smart Retail Assistant"
                Text(
                  'SMART RETAIL ASSISTANT',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: taglineColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                )
                .animate()
                .fadeIn(delay: 750.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutQuad),
              ],
            ),
          ),
          
          // Shimmering progress bar at bottom - Centered perfectly using Align
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: SizedBox(
                width: 140,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 1100.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}
