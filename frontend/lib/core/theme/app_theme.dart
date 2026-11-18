import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Font bulat & tebal mengikuti banner (Fredoka).
  static ThemeData get light {
    final textTheme = GoogleFonts.fredokaTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.skyBottom,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
      textTheme: textTheme.apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: const StadiumBorder(),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static TextStyle title(BuildContext context, {double size = 32}) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      );
}
