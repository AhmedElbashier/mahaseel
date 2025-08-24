
import 'package:flutter/material.dart';

class AppTheme {
  static const _primarySeed = Color(0xFF2E7D32); // Agricultural green
  static const _fontFamily = 'Cairo';

  // Light theme
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.light,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // Dark theme
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.dark,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      fontFamily: _fontFamily,
      useMaterial3: true,

      // App bar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: colorScheme.surface.withOpacity(0.95),
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontFamily: _fontFamily,
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 6,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        elevation: 8,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // Text theme with Arabic font support
      textTheme: _buildTextTheme(colorScheme, brightness),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme, Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontFamily: _fontFamily,
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
