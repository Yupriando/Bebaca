import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Ganti font di sini kalau mau (mis. GoogleFonts.fredokaTextTheme).
  static ThemeData get light {
    final textTheme = GoogleFonts.itimTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      textTheme: textTheme,
    );
  }

  static TextStyle title(BuildContext context, {double size = 32}) =>
      GoogleFonts.itim(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      );
}
