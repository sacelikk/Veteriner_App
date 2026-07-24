import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Renk Paleti (Modern Tonlar)
  static const Color primaryColor = Color(0xFF00695C); // Koyu Camgöbeği
  static const Color primaryLight = Color(0xFF4DB6AC); // Açık Camgöbeği
  static const Color accentColor = Color(0xFFFF9800);  // Sıcak Turuncu
  static const Color backgroundColor = Color(0xFFF8F9FA); // Çok Açık Gri (Surface)
  static const Color textDark = Color(0xFF263238); // Koyu Gri-Mavi Metin
  static const Color textLight = Color(0xFF78909C); // Açık Gri-Mavi Metin
  static const Color white = Colors.white;

  // Global Tema Tanımı
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // Google Fonts entegrasyonu (Poppins)
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: textDark, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.poppins(color: textDark, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: textDark),
        bodyMedium: GoogleFonts.poppins(color: textDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: textLight),
        labelStyle: GoogleFonts.poppins(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
