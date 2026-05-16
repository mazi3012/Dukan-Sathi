import 'package:flutter/material.dart';

class AppColors {
  // --- Dark Mode Palette ---
  static const Color darkBackground = Color(0xFF0F111A);
  static const Color darkSurface = Color(0xFF1C1F2E);
  static const Color darkGlass = Color(0x1AFFFFFF); // 10% white
  static const Color darkGlassBorder = Color(0x33FFFFFF); // 20% white

  // --- Light Mode Palette (Organic Green) ---
  static const Color lightBackground = Color(0xFFEDF7F1); // Stronger green-tinted off-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFD1FAE5);
  static const Color lightSurfaceHighest = Color(0xFFA7F3D0);
  static const Color lightOnSurface = Color(0xFF064E3B); // Very dark green text
  static const Color lightOutline = Color(0xFF6EE7B7);
  static const Color lightGlass = Color(0xD9FFFFFF); // 85% white for clean frosted look
  static const Color lightGlassBorder = Color(0x66059669); // Stronger emerald green edge (40% opacity)
  static const Color lightPrimary = Color(0xFF059669); // Main emerald green
  static const Color lightPrimarySoft = Color(0xFFD1FAE5); // Soft green for icon boxes
  static const Color cyanGlow = Color(0xFF00F0FF); // The "Pulse" of the system

  // --- Brand Colors ---
  static const Color primary = Color(0xFF059669); // Emerald Green as Primary
  static const Color primaryGlow = Color(0x33059669); 
  static const Color accent = Color(0xFF10B981); // Emerald 500
  static const Color cyberPurple = Color(0xFF6C63FF); // Kept for legacy if needed
  
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
