import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color wood = Color(0xFF4B3425);
  static const Color walnut = Color(0xFF2F2118);
  static const Color sand = Color(0xFFF4E7D3);
  static const Color parchment = Color(0xFFF9F3EA);
  static const Color antiqueGold = Color(0xFF9F7842);
  static const Color bronze = Color(0xFF725332);
  static const Color ink = Color(0xFF23170F);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: antiqueGold,
        brightness: Brightness.light,
        primary: wood,
        secondary: antiqueGold,
        surface: parchment,
      ),
      scaffoldBackgroundColor: parchment,
    );

    final textTheme = GoogleFonts.amiriTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: GoogleFonts.amiri(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: GoogleFonts.amiri(
        fontSize: 18,
        height: 1.7,
        color: ink,
      ),
      bodyMedium: GoogleFonts.amiri(
        fontSize: 16,
        height: 1.7,
        color: ink.withValues(alpha: 0.88),
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: const Color(0xFFFDF8F1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFE4D4BE)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: wood,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.amiri(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: wood,
          side: const BorderSide(color: antiqueGold),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.amiri(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: sand,
        selectedColor: wood,
        secondarySelectedColor: wood,
        labelStyle: GoogleFonts.amiri(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        secondaryLabelStyle: GoogleFonts.amiri(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        hintStyle: GoogleFonts.amiri(
          color: ink.withValues(alpha: 0.52),
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.amiri(
          color: bronze,
          fontSize: 16,
        ),
        prefixIconColor: antiqueGold,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9C3A2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9C3A2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: antiqueGold, width: 1.4),
        ),
      ),
      dividerColor: const Color(0xFFE1D2BC),
    );
  }
}
