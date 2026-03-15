import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/globals.dart';

class AppTheme {
  // Colores inspirados en el PDF (ajustables)

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.white,
    textTheme: GoogleFonts.poppinsTextTheme(),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),
    chipTheme: const ChipThemeData(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    ),
  );

  static ThemeData get dark => ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.secondary,
      brightness: Brightness.dark,
    ),
  );
}
