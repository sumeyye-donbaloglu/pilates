import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,

    // ── FONT
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: AppColors.deepIndigo,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.deepIndigo,
        letterSpacing: 0.3,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.2,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 15,
        color: AppColors.text,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        color: AppColors.text,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
      ),
    ),

    // ── APP BAR
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // ── ELEVATED BUTTON
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.4),
        textStyle: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    ),

    // ── OUTLINED BUTTON
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // ── INPUT
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: GoogleFonts.nunito(
        color: AppColors.lavender,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.nunito(
        color: AppColors.textLight,
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── CARD
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      color: AppColors.surface,
    ),

    // ── DIVIDER
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // ── CHIP
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceTint,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.nunito(
        color: AppColors.deepIndigo,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    // ── BOTTOM NAV
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ── COLOR SCHEME
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.purple,
      surface: AppColors.surface,
      background: AppColors.background,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.text,
      onBackground: AppColors.text,
    ),
  );
}
