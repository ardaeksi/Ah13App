import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // AH13 Brand Palette (Red / White / Black shades only)
  static const primary = Color(0xFFE02828); // Bright Red
  static const onPrimary = Color(0xFFFFFFFF);

  // We constrain the palette to monochrome + red accents
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const grey700 = Color(0xFF2A2A2A);
  static const grey800 = Color(0xFF1A1A1A);
  static const grey900 = Color(0xFF0E0E0E);

  // Backgrounds
  static const background = grey900; // Global dark background (transparent scaffold lets backgrounds show through)
  static const surface = grey800; // Cards, app bars, sheets
  static const surfaceVariant = grey700; // Inputs, hovers

  // Text
  static const textPrimary = white;
  static const textSecondary = Color(0xFFCACACA); // Neutral light gray
  static const textTertiary = Color(0xFF9E9E9E);

  // Status (constrained to red/white/black family)
  static const error = primary;
  static const success = white; // neutral success placeholder within allowed palette
  static const warning = Color(0xFF555555); // neutral dark gray as warning tint
}

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.exo2(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  static TextStyle get displayMedium => GoogleFonts.exo2(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineLarge => GoogleFonts.exo2(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.exo2(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => GoogleFonts.exo2(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.exo2(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
  );
}

// Modern Dark Theme
ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  // Make scaffold backgrounds transparent so the global painter shows through
  scaffoldBackgroundColor: Colors.transparent,
    primaryColor: AppColors.primary,
  
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.black,
      onSecondary: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      background: AppColors.background,
    ),

  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.exo2(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
  ),

  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.surfaceVariant, width: 1),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColors.textTertiary),
    hintStyle: const TextStyle(color: AppColors.textTertiary),
    contentPadding: const EdgeInsets.all(16),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: GoogleFonts.exo2(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textTertiary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle: GoogleFonts.exo2(fontSize: 12),
  ),
);
