import 'package:flutter/material.dart';

/// Warm Artisanal Bakery Color Palette:
/// - #CCD5AE (Sage Green)
/// - #E9EDC9 (Buttercream Matcha)
/// - #FEFAE0 (Warm Vanilla Cream)
/// - #FAEDCD (Warm Biscuit)
/// - #D4A373 (Golden Crust Caramel)
class AppColors {
  // Requested Brand Palette
  static const Color primary = Color(0xFFD4A373); // Golden Caramel Crust / Main Action
  static const Color primaryDark = Color(0xFF8C5835); // Deep Baked Crust / Headers & Strong Accent
  static const Color sage = Color(0xFFCCD5AE); // Sage Olive
  static const Color buttercream = Color(0xFFE9EDC9); // Light Matcha / Soft highlight
  static const Color biscuit = Color(0xFFFAEDCD); // Warm Biscuit / Card Borders & Chips
  static const Color background = Color(0xFFFEFAE0); // Warm Vanilla Cream Background

  // Legacy mappings for seamless compatibility
  static const Color surfaceLight = Color(0xFFFAEDCD); // Warm Biscuit
  static const Color surfaceSecondary = Color(0xFFCCD5AE); // Sage Green
  static const Color cardBackground = Colors.white;

  // Typography & Semantics
  static const Color textDark = Color(0xFF3B281C); // Deep Roasted Coffee Text
  static const Color textMuted = Color(0xFF7A6B5D); // Warm Cocoa Muted
  static const Color error = Color(0xFFC1121F); // Crisp Baked Red Error
  static const Color success = Color(0xFF606C38); // Forest Olive Green Success
}
