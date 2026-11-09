import 'package:flutter/material.dart';

class AppTheme {
  // Beslenme ve Sağlık konseptine uygun modern renkler (Zümrüt Yeşili)
  static const Color primaryColor = Color(0xFF00BFA5); // Zümrüt Yeşili
  static const Color secondaryColor = Color(0xFFE8F8F2);
  static const Color accentColor = Color(0xFF1DE9B6);
  static const Color darkTextColor = Color(0xFF2D3142);
  static const Color lightTextColor = Color(0xFF9098B1);
  static const Color backgroundColor = Color(0xFFF8F9FB);
  static const Color dangerColor = Color(0xFFEB5757); // Kırmızı
  static const Color successColor = Color(0xFF00C48C); // Yeşil

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: TextStyle(
          color: darkTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryColor,
        secondary: accentColor,
      ),
    );
  }
}
