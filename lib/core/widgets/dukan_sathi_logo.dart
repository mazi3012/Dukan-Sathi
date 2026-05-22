import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class DukanSathiLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool animate;
  final bool useSolidBg;

  const DukanSathiLogo({
    super.key,
    this.size = 80.0,
    this.showGlow = true,
    this.animate = true,
    this.useSolidBg = false,
  });

  @override
  Widget build(BuildContext context) {
    // If it's a small collapsed logo (e.g., in a narrow sidebar),
    // use a beautifully polished, self-contained circular badge structure
    // that fits perfectly without any overflow clipping.
    final bool isSmall = size <= 48;

    Widget logoWidget = Image.asset(
      useSolidBg ? 'assets/logo_solid.png' : 'assets/logo.png',
      width: isSmall ? size * 0.65 : size,
      height: isSmall ? size * 0.65 : size,
      fit: BoxFit.contain,
    );

    if (isSmall) {
      // Sleek collapsed design: enclosed glassmorphic circular emblem
      Widget badge = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04),
          border: Border.all(
            color: const Color(0xFF32E6FF).withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: Center(
          child: logoWidget,
        ),
      );

      if (animate) {
        badge = badge
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
            )
            .fadeIn(duration: 400.ms);
      }
      return badge;
    }

    if (animate) {
      logoWidget = logoWidget
          .animate()
          .scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
            begin: const Offset(0.7, 0.7),
            end: const Offset(1.0, 1.0),
          )
          .fadeIn(duration: 400.ms);
    }

    return logoWidget;
  }
}

class DukanSathiHeader extends StatelessWidget {
  final double height;
  final bool showGlow;
  final bool animate;

  const DukanSathiHeader({
    super.key,
    this.height = 40.0,
    this.showGlow = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    // Left spacing and ratio calculations
    final double calculatedWidth = height; // horizontal text aspect ratio is now 1:1

    Widget headerWidget = Image.asset(
      'assets/logo_full.png',
      width: calculatedWidth,
      height: height,
      fit: BoxFit.contain,
    );

    if (animate) {
      headerWidget = headerWidget
          .animate()
          .fadeIn(duration: 500.ms, curve: Curves.easeOut)
          .slideX(begin: -0.05, end: 0.0, duration: 500.ms, curve: Curves.easeOut);
    }

    return headerWidget;
  }
}
