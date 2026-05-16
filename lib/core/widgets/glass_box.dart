import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;

  const GlassBox({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.borderRadius = 12.0,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? 
              (isDark 
                ? Colors.white.withOpacity(opacity) 
                : AppColors.lightGlass),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: isDark 
                ? AppColors.darkGlassBorder 
                : AppColors.lightGlassBorder,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
