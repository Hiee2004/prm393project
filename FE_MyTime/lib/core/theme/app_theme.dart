import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';

@immutable
class AppSceneTheme extends ThemeExtension<AppSceneTheme> {
  const AppSceneTheme({
    required this.id,
    required this.label,
    required this.backgroundGradient,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.overlay,
    required this.cardBorder,
    required this.cardGlow,
    required this.navGlow,
    required this.floatingIcon,
    required this.accentIcon,
    required this.effectStyle,
  });

  final String id;
  final String label;
  final List<Color> backgroundGradient;
  final Color glowPrimary;
  final Color glowSecondary;
  final Color overlay;
  final Color cardBorder;
  final Color cardGlow;
  final Color navGlow;
  final IconData floatingIcon;
  final IconData accentIcon;
  final SceneEffectStyle effectStyle;

  @override
  AppSceneTheme copyWith({
    String? id,
    String? label,
    List<Color>? backgroundGradient,
    Color? glowPrimary,
    Color? glowSecondary,
    Color? overlay,
    Color? cardBorder,
    Color? cardGlow,
    Color? navGlow,
    IconData? floatingIcon,
    IconData? accentIcon,
    SceneEffectStyle? effectStyle,
  }) {
    return AppSceneTheme(
      id: id ?? this.id,
      label: label ?? this.label,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glowPrimary: glowPrimary ?? this.glowPrimary,
      glowSecondary: glowSecondary ?? this.glowSecondary,
      overlay: overlay ?? this.overlay,
      cardBorder: cardBorder ?? this.cardBorder,
      cardGlow: cardGlow ?? this.cardGlow,
      navGlow: navGlow ?? this.navGlow,
      floatingIcon: floatingIcon ?? this.floatingIcon,
      accentIcon: accentIcon ?? this.accentIcon,
      effectStyle: effectStyle ?? this.effectStyle,
    );
  }

  @override
  AppSceneTheme lerp(ThemeExtension<AppSceneTheme>? other, double t) {
    if (other is! AppSceneTheme) return this;
    return AppSceneTheme(
      id: t < 0.5 ? id : other.id,
      label: t < 0.5 ? label : other.label,
      backgroundGradient: List.generate(
        backgroundGradient.length,
        (index) => Color.lerp(
          backgroundGradient[index],
          other.backgroundGradient[index],
          t,
        )!,
      ),
      glowPrimary: Color.lerp(glowPrimary, other.glowPrimary, t)!,
      glowSecondary: Color.lerp(glowSecondary, other.glowSecondary, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardGlow: Color.lerp(cardGlow, other.cardGlow, t)!,
      navGlow: Color.lerp(navGlow, other.navGlow, t)!,
      floatingIcon: t < 0.5 ? floatingIcon : other.floatingIcon,
      accentIcon: t < 0.5 ? accentIcon : other.accentIcon,
      effectStyle: t < 0.5 ? effectStyle : other.effectStyle,
    );
  }
}

enum SceneEffectStyle { snow, wave, lights, petals }

abstract final class AppTheme {
  static const String winter = 'Winter';
  static const String summer = 'Summer';
  static const String christmas = 'Christmas';
  static const String lunarNewYear = 'Lunar New Year';

  static const List<String> selectableModes = [
    winter,
    summer,
    christmas,
    lunarNewYear,
  ];

  static ThemeData get light => forMode(lunarNewYear);

  static String normalizeMode(String mode) {
    switch (mode.trim().toLowerCase()) {
      case 'dark':
      case 'winter':
        return winter;
      case 'light':
      case 'summer':
        return summer;
      case 'christmas':
        return christmas;
      case 'yellow':
      case 'tet':
      case 'lunar new year':
      case 'lunarnewyear':
        return lunarNewYear;
      default:
        return lunarNewYear;
    }
  }

  static String labelForMode(String mode) {
    return _specFor(mode).scene.label;
  }

  static ThemeData forMode(String mode) {
    final spec = _specFor(mode);
    return _build(
      brightness: spec.brightness,
      primary: spec.primary,
      secondary: spec.secondary,
      surface: spec.surface,
      surfaceSoft: spec.surfaceSoft,
      onSurface: spec.onSurface,
      inputFill: spec.inputFill,
      border: spec.border,
      scene: spec.scene,
    );
  }

  static _ThemeSpec _specFor(String mode) {
    switch (normalizeMode(mode)) {
      case winter:
        return _ThemeSpec(
          brightness: Brightness.dark,
          primary: const Color(0xFF7DD3FC),
          secondary: const Color(0xFFBFDBFE),
          surface: const Color(0xCC10203A),
          surfaceSoft: const Color(0xAA183253),
          onSurface: const Color(0xFFF6FBFF),
          inputFill: const Color(0xCC0D1A30),
          border: const Color(0x668DCBFF),
          scene: const AppSceneTheme(
            id: winter,
            label: 'Winter',
            backgroundGradient: [
              Color(0xFF061527),
              Color(0xFF0D2746),
              Color(0xFF153A5D),
            ],
            glowPrimary: Color(0x664DBDFF),
            glowSecondary: Color(0x55D7F4FF),
            overlay: Color(0x220B1628),
            cardBorder: Color(0x668DCBFF),
            cardGlow: Color(0x334DBDFF),
            navGlow: Color(0x403A8DFF),
            floatingIcon: Icons.ac_unit_rounded,
            accentIcon: Icons.cloud_rounded,
            effectStyle: SceneEffectStyle.snow,
          ),
        );
      case summer:
        return _ThemeSpec(
          brightness: Brightness.light,
          primary: const Color(0xFF0EA5E9),
          secondary: const Color(0xFFF59E0B),
          surface: const Color(0xFFFDFCF7),
          surfaceSoft: const Color(0xFFFFF1C6),
          onSurface: const Color(0xFF11314C),
          inputFill: const Color(0xFFFFFBF0),
          border: const Color(0x66F1BE61),
          scene: const AppSceneTheme(
            id: summer,
            label: 'Summer',
            backgroundGradient: [
              Color(0xFF87E8FF),
              Color(0xFF53C6F2),
              Color(0xFFF7C769),
            ],
            glowPrimary: Color(0x5591F0FF),
            glowSecondary: Color(0x44FFE49A),
            overlay: Color(0x12FFF7DD),
            cardBorder: Color(0x66F1BE61),
            cardGlow: Color(0x22F59E0B),
            navGlow: Color(0x2240BFF5),
            floatingIcon: Icons.wb_sunny_rounded,
            accentIcon: Icons.water_drop_rounded,
            effectStyle: SceneEffectStyle.wave,
          ),
        );
      case christmas:
        return _ThemeSpec(
          brightness: Brightness.dark,
          primary: const Color(0xFFE11D48),
          secondary: const Color(0xFF22C55E),
          surface: const Color(0xCC1B1A23),
          surfaceSoft: const Color(0xAA2C2432),
          onSurface: const Color(0xFFFFF7F8),
          inputFill: const Color(0xCC231A27),
          border: const Color(0x66FCA5A5),
          scene: const AppSceneTheme(
            id: christmas,
            label: 'Christmas',
            backgroundGradient: [
              Color(0xFF1A1020),
              Color(0xFF243B2F),
              Color(0xFF7F1D1D),
            ],
            glowPrimary: Color(0x55F43F5E),
            glowSecondary: Color(0x4422C55E),
            overlay: Color(0x220F0A12),
            cardBorder: Color(0x66FCA5A5),
            cardGlow: Color(0x22F43F5E),
            navGlow: Color(0x2222C55E),
            floatingIcon: Icons.star_rounded,
            accentIcon: Icons.celebration_rounded,
            effectStyle: SceneEffectStyle.lights,
          ),
        );
      case lunarNewYear:
      default:
        return _ThemeSpec(
          brightness: Brightness.light,
          primary: AppColors.primaryDark,
          secondary: const Color(0xFFC2410C),
          surface: const Color(0xFFFFFBF2),
          surfaceSoft: const Color(0xFFFFE7B0),
          onSurface: const Color(0xFF4A160A),
          inputFill: const Color(0xFFFFF8EA),
          border: const Color(0x66F6B73C),
          scene: const AppSceneTheme(
            id: lunarNewYear,
            label: 'Lunar New Year',
            backgroundGradient: [
              Color(0xFFFCE7B4),
              Color(0xFFF8BE4B),
              Color(0xFFD9482C),
            ],
            glowPrimary: Color(0x55FFD166),
            glowSecondary: Color(0x44FF6B35),
            overlay: Color(0x12FFF6E0),
            cardBorder: Color(0x66F6B73C),
            cardGlow: Color(0x22D9482C),
            navGlow: Color(0x22D98806),
            floatingIcon: Icons.local_florist_rounded,
            accentIcon: Icons.auto_awesome_rounded,
            effectStyle: SceneEffectStyle.petals,
          ),
        );
    }
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color surface,
    required Color surfaceSoft,
    required Color onSurface,
    required Color inputFill,
    required Color border,
    required AppSceneTheme scene,
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
      canvasColor: surface,
      dividerColor: border.withValues(alpha: 0.9),
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const ['Inter', 'Roboto', 'Arial', 'sans-serif'],
      extensions: [scene],
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
          height: 1.12,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface.withValues(alpha: isDark ? 0.96 : 0.92),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: isDark ? 0.84 : 0.90),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.12,
        ),
        headlineSmall: TextStyle(
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.14,
        ),
        titleLarge: TextStyle(
          color: onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w900,
          height: 1.18,
        ),
        titleMedium: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.24,
        ),
        titleSmall: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          color: isDark ? const Color(0xFFE2E8F0) : onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.42,
        ),
        bodyMedium: TextStyle(
          color: isDark
              ? const Color(0xFFCBD5E1)
              : onSurface.withValues(alpha: 0.70),
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: isDark
              ? const Color(0xFF94A3B8)
              : onSurface.withValues(alpha: 0.58),
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
        fillColor: inputFill.withValues(alpha: isDark ? 0.90 : 0.95),
        labelStyle: TextStyle(
          color: isDark
              ? const Color(0xFFCBD5E1)
              : onSurface.withValues(alpha: 0.74),
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: TextStyle(
          color: isDark
              ? const Color(0xFF94A3B8)
              : onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
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
          side: BorderSide(color: border),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSoft.withValues(alpha: isDark ? 0.55 : 0.85),
        selectedColor: primary.withValues(alpha: 0.16),
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
          fillColor: inputFill.withValues(alpha: isDark ? 0.90 : 0.95),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        subtitleTextStyle: TextStyle(
          color: isDark
              ? const Color(0xFFCBD5E1)
              : onSurface.withValues(alpha: 0.70),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ThemeSpec {
  const _ThemeSpec({
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.surfaceSoft,
    required this.onSurface,
    required this.inputFill,
    required this.border,
    required this.scene,
  });

  final Brightness brightness;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color surfaceSoft;
  final Color onSurface;
  final Color inputFill;
  final Color border;
  final AppSceneTheme scene;
}
