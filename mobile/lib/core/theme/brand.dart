import 'package:flutter/material.dart';

/// Central brand tokens for colors, radii, spacing, and typography.
class BrandColors {
  // Primary palette (green-based to match agriculture theme)
  static const primary = Color(0xFF2E7D32); // Green 800
  static const primaryDark = Color(0xFF1B5E20); // Green 900
  static const primaryLight = Color(0xFF43A047); // Green 600
  static const accent = Color(0xFF00C853); // Green A700

  // Support colors
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825); // Amber 800
  static const info = Color(0xFF0277BD); // Light Blue 800

  // Neutrals (keep Material defaults via ColorScheme)
}

class BrandRadii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

class BrandSpace {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
}

class Brand {
  static const fontFamily = 'Cairo';
}

