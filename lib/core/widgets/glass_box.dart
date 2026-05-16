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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: AppColors.lightPrimary.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: color ?? 
                (isDark 
                  ? Colors.white.withOpacity(opacity) 
                  : AppColors.lightSurface.withOpacity(0.85)),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: isDark 
                  ? AppColors.darkGlassBorder 
                  : AppColors.lightGlassBorder,
                width: isDark ? 1.0 : 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
