import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => forMode('Yellow');

  static ThemeData forMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'dark':
        return _build(
          brightness: Brightness.dark,
          primary: const Color(0xFFFFC83D),
          secondary: const Color(0xFF58B368),
          surface: const Color(0xFF1F2937),
          onSurface: const Color(0xFFF8FAFC),
          inputFill: const Color(0xFF111827),
        );
      case 'light':
        return _build(
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF14B8A6),
          surface: Colors.white,
          onSurface: const Color(0xFF111827),
          inputFill: Colors.white,
        );
      case 'yellow':
      default:
        return _build(
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          inputFill: AppColors.surface,
        );
    }
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color surface,
    required Color onSurface,
    required Color inputFill,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const ['Inter', 'Roboto', 'Arial', 'sans-serif'],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.35,
          height: 1.12,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.65,
          height: 1.12,
        ),
        headlineSmall: TextStyle(
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.45,
          height: 1.14,
        ),
        titleLarge: TextStyle(
          color: onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.25,
          height: 1.18,
        ),
        titleMedium: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.05,
          height: 1.24,
        ),
        titleSmall: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.42,
        ),
        bodyMedium: TextStyle(
          color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.05,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF374151) : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF374151) : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          side: BorderSide(
            color: isDark ? const Color(0xFF374151) : AppColors.border,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF111827)
            : AppColors.surfaceSoft,
        selectedColor: primary.withValues(alpha: 0.14),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF374151) : AppColors.border,
            ),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        subtitleTextStyle: TextStyle(
          color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}
