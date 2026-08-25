import 'package:flutter/material.dart';

/// Soft, Friendly Artisanal Bakery Palette:
/// - #CCD5AE (Soft Sage Green)
/// - #E9EDC9 (Buttercream)
/// - #FEFAE0 (Warm Vanilla Cream Background)
/// - #FAEDCD (Warm Biscuit Crust)
/// - #D4A373 (Golden Honey / Caramel)
class AppColors {
  // Brand Tones
  static const Color primary = Color(0xFFD4A373); // Warm Golden Caramel
  static const Color primaryDark = Color(0xFFB07D4F); // Rich Golden Brown
  static const Color sage = Color(0xFFCCD5AE); // Soft Sage Green
  static const Color buttercream = Color(0xFFE9EDC9); // Pale Buttercream
  static const Color biscuit = Color(0xFFFAEDCD); // Warm Biscuit
  static const Color background = Color(0xFFFEFAE0); // Soft Vanilla Background

  // Surface & Layout
  static const Color surfaceLight = Color(0xFFFAEDCD);
  static const Color surfaceSecondary = Color(0xFFE9EDC9);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFEADFC7);

  // Typography & Semantics
  static const Color textDark = Color(0xFF3D2B1F); // Warm Roasted Espresso
  static const Color textMuted = Color(0xFF8A7768); // Soft Cocoa Muted
  static const Color error = Color(0xFFD94848); // Gentle Red
  static const Color success = Color(0xFF6B8E23); // Olive Success
}
