import 'package:flutter/material.dart';

class AppColors {
  // --- Dark Mode Palette ---
  static const Color darkBackground = Color(0xFF0F111A);
  static const Color darkSurface = Color(0xFF1C1F2E);
  static const Color darkGlass = Color(0x1AFFFFFF); // 10% white
  static const Color darkGlassBorder = Color(0x33FFFFFF); // 20% white

  // --- Light Mode Palette ---
  static const Color lightBackground = Color(0xFFF8FAFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlass = Color(0x0D000000); // 5% black
  static const Color lightGlassBorder = Color(0x1A000000); // 10% black
  static const Color trustBlue = Color(0xFF0052CC); // Professional Trust Blue

  // --- Brand Colors ---
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryGlow = Color(0x806C63FF);
  static const Color accent = Color(0xFFFF63B8);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4B43E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF63B8), Color(0xFFE043A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
