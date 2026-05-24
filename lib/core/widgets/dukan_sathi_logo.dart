import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class DukanSathiLogo extends StatelessWidget {
  final double size;
  final double? width;
  final double? height;
  final bool showGlow;
  final bool animate;
  final bool useSolidBg;

  const DukanSathiLogo({
    super.key,
    this.width,
    this.height,
    this.size = 80.0,
    this.showGlow = true,
    this.animate = true,
    this.useSolidBg = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamically load white text in dark mode and black text in light mode
    final String logoAsset = isDark ? 'assets/logo_dark.png' : 'assets/logo_light.png';
    
    final bool isSmall = (height ?? size) <= 48;

    double? targetWidth = width;
    double? targetHeight = height ?? size;

    if (isSmall && targetWidth == null) {
      targetWidth = size;
      targetHeight = size;
    }

    Widget logoWidget = Image.asset(
      logoAsset,
      width: isSmall ? targetWidth! * 0.85 : targetWidth,
      height: isSmall ? targetHeight! * 0.85 : targetHeight,
      fit: BoxFit.contain,
    );

    if (animate) {
      logoWidget = logoWidget
          .animate()
          .scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
            begin: const Offset(0.8, 0.8),
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
    Widget headerWidget = DukanSathiLogo(
      height: height,
      width: height * 3.3, // Preserves the exact 3.3 aspect ratio of the new logo
      animate: false,      // Handle animation at the parent level
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
