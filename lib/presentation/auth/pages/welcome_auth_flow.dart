import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_page.dart';
import 'login_page.dart';

class WelcomeAuthFlow extends StatefulWidget {
  const WelcomeAuthFlow({super.key});

  @override
  State<WelcomeAuthFlow> createState() => _WelcomeAuthFlowState();
}

class _WelcomeAuthFlowState extends State<WelcomeAuthFlow> {
  bool _showLogin = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.05),
          end: Offset.zero,
        ).animate(animation);
        
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: !_showLogin
          ? LandingPage(
              key: const ValueKey('landing_page_slide'),
              onGetStarted: () {
                setState(() {
                  _showLogin = true;
                });
              },
            )
          : LoginPage(
              key: const ValueKey('login_page_slide'),
              onBack: () {
                setState(() {
                  _showLogin = false;
                });
              },
            ),
    );
  }
}
