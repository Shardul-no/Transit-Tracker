import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF08111F);
  static const Color surface = Color(0xFF0F1A2B);
  static const Color surfaceElevated = Color(0xFF16243A);
  static const Color accent = Color(0xFF6CF0C2);
  static const Color accentBlue = Color(0xFF67A7FF);
  static const Color accentGold = Color(0xFFF2B66D);
  static const Color textPrimary = Color(0xFFF6FAFF);
  static const Color textSecondary = Color(0xFF9CB0CA);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    ).copyWith(
      primary: accent,
      secondary: accentBlue,
      tertiary: accentGold,
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.manrope(color: textPrimary),
        bodyMedium: GoogleFonts.manrope(
          color: textPrimary.withValues(alpha: 0.84),
        ),
        bodySmall: GoogleFonts.manrope(
          color: textPrimary.withValues(alpha: 0.72),
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          color: textPrimary.withValues(alpha: 0.94),
        ),
        labelMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          color: textPrimary.withValues(alpha: 0.80),
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w500,
          color: textPrimary.withValues(alpha: 0.68),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.manrope(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
