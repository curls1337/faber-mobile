import 'dart:ui';
import 'package:flutter/material.dart';

/// VisionOS Dark Graphite Frost & Liquid Glass Design Tokens
/// for Faber Studio Mobile.
class FaberTokens {
  FaberTokens._();

  // ---------------------------------------------------------------------------
  // Background & Glass Surface Hierarchy
  // ---------------------------------------------------------------------------
  static const Color bgPrimary = Color(0xFF07090F);
  static const Color bgSecondary = Color(0xFF0D111A);
  static const Color bgElevated = Color(0xFF131824);

  /// Frosted dark graphite glass surfaces
  static const Color surfaceGlass = Color(0xB3141A26); // ~70% opacity
  static const Color surfaceGlassElevated = Color(0xCC1C2436); // ~80% opacity
  static const Color surfaceGlassLight = Color(0x14FFFFFF); // ~8% white frost
  static const Color surfaceGlassHover = Color(0x24FFFFFF); // ~14% white frost
  static const Color surfaceCard = Color(0xFF111827);
  static const Color surfaceTerminal = Color(0xFF05070B);

  /// Specular & hairline borders
  static const Color borderGlass = Color(0x26FFFFFF); // 15% white
  static const Color borderGlassStrong = Color(0x40FFFFFF); // 25% white
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white

  // ---------------------------------------------------------------------------
  // Brand & Semantic Accents
  // ---------------------------------------------------------------------------
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFEF4444);

  // Soft translucent semantic fills
  static const Color indigoSoft = Color(0x266366F1);
  static const Color violetSoft = Color(0x268B5CF6);
  static const Color cyanSoft = Color(0x2622D3EE);
  static const Color emeraldSoft = Color(0x2610B981);
  static const Color amberSoft = Color(0x26F59E0B);
  static const Color roseSoft = Color(0x26EF4444);

  // ---------------------------------------------------------------------------
  // Typography Colors
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textCode = Color(0xFFE2E8F0);

  // ---------------------------------------------------------------------------
  // Gradients (Liquid Glass & VisionOS Depth)
  // ---------------------------------------------------------------------------
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentIndigo, accentViolet],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1B4B),
      Color(0xFF172554),
      Color(0xFF0F172A),
    ],
  );

  static const LinearGradient glassSpecularGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x24FFFFFF),
      Color(0x0AFFFFFF),
      Color(0x03FFFFFF),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient cyanIndigoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentIndigo],
  );

  static const RadialGradient ambientTopGlow = RadialGradient(
    center: Alignment(-0.6, -0.8),
    radius: 1.2,
    colors: [
      Color(0x336366F1),
      Color(0x1422D3EE),
      Color(0x0007090F),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  // ---------------------------------------------------------------------------
  // Radii & Spacing
  // ---------------------------------------------------------------------------
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radius2xl = 32.0;
  static const double radiusPill = 999.0;

  static final BorderRadius brXs = BorderRadius.circular(radiusXs);
  static final BorderRadius brSm = BorderRadius.circular(radiusSm);
  static final BorderRadius brMd = BorderRadius.circular(radiusMd);
  static final BorderRadius brLg = BorderRadius.circular(radiusLg);
  static final BorderRadius brXl = BorderRadius.circular(radiusXl);
  static final BorderRadius br2xl = BorderRadius.circular(radius2xl);
  static final BorderRadius brPill = BorderRadius.circular(radiusPill);

  static const double spaceXs = 6.0;
  static const double spaceSm = 10.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 28.0;

  // ---------------------------------------------------------------------------
  // Blur & Elevation Shadows
  // ---------------------------------------------------------------------------
  static const double blurSigma = 24.0;
  static const double blurSigmaHeavy = 36.0;

  static ImageFilter get glassBlur =>
      ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);

  static ImageFilter get heavyBlur =>
      ImageFilter.blur(sigmaX: blurSigmaHeavy, sigmaY: blurSigmaHeavy);

  static List<BoxShadow> get glassShadow => [
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
        const BoxShadow(
          color: Color(0x1A6366F1),
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.32),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
      ];

  // ---------------------------------------------------------------------------
  // Glass Container Decoration Helper
  // ---------------------------------------------------------------------------
  static BoxDecoration glassDecoration({
    double radius = radiusLg,
    Color? color,
    Color? borderColor,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: color ?? (elevated ? surfaceGlassElevated : surfaceGlass),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? (elevated ? borderGlassStrong : borderGlass),
        width: 1.0,
      ),
      boxShadow: elevated ? glassShadow : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Material 3 Dark Theme
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: accentIndigo,
      secondary: accentViolet,
      tertiary: accentCyan,
      surface: bgSecondary,
      error: accentRose,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgPrimary,
      canvasColor: bgPrimary,
      dividerColor: borderSubtle,
      splashColor: indigoSoft,
      highlightColor: surfaceGlassLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderGlass, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGlassLight,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderGlass),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderGlass),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentIndigo, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 15,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 13.5,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
