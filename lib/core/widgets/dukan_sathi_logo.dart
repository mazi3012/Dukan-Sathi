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
          boxShadow: showGlow ? [
            BoxShadow(
              color: const Color(0xFF32E6FF).withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ] : null,
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

    // Default regular size implementation
    if (showGlow) {
      logoWidget = Stack(
        alignment: Alignment.center,
        children: [
          // Ambient neon glow backplate
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF32E6FF).withOpacity(0.4),
                  blurRadius: size * 0.4,
                  spreadRadius: size * 0.05,
                ),
              ],
            ),
          ),
          logoWidget,
        ],
      );
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
    final double calculatedWidth = height * 4.0; // horizontal text aspect ratio is ~4:1

    Widget headerWidget = Image.asset(
      'assets/logo_full.png',
      width: calculatedWidth,
      height: height,
      fit: BoxFit.contain,
    );

    if (showGlow) {
      headerWidget = Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Soft backplate glow on the DS icon portion
          Positioned(
            left: height * 0.25,
            child: Container(
              width: height * 0.8,
              height: height * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF32E6FF).withOpacity(0.35),
                    blurRadius: height * 0.5,
                    spreadRadius: height * 0.05,
                  ),
                ],
              ),
            ),
          ),
          headerWidget,
        ],
      );
    }

    if (animate) {
      headerWidget = headerWidget
          .animate()
          .fadeIn(duration: 500.ms, curve: Curves.easeOut)
          .slideX(begin: -0.05, end: 0.0, duration: 500.ms, curve: Curves.easeOut);
    }

    return headerWidget;
  }
}
