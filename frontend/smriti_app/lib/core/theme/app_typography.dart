import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme getTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.epilogue(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        letterSpacing: -0.02,
        color: AppColors.onSurface,
      ),
      displayMedium: GoogleFonts.epilogue(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 38 / 30,
        letterSpacing: -0.01,
        color: AppColors.onSurface,
      ),
      displaySmall: GoogleFonts.epilogue(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22,
        color: AppColors.onSurface,
      ),
      headlineMedium: GoogleFonts.epilogue(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 26 / 19,
        color: AppColors.onSurface,
      ),
      bodyLarge: GoogleFonts.atkinsonHyperlegible(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        height: 30 / 20,
        letterSpacing: 0.01,
        color: AppColors.onSurface,
      ),
      bodyMedium: GoogleFonts.atkinsonHyperlegible(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        letterSpacing: 0.01,
        color: AppColors.onSurface,
      ),
      bodySmall: GoogleFonts.atkinsonHyperlegible(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.onSurface,
      ),
      labelLarge: GoogleFonts.atkinsonHyperlegible(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 22 / 16,
        letterSpacing: 0.02,
        color: AppColors.onSurface,
      ),
      labelMedium: GoogleFonts.atkinsonHyperlegible(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.02,
        color: AppColors.onSurface,
      ),
      labelSmall: GoogleFonts.atkinsonHyperlegible(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.04,
        color: AppColors.onSurface,
      ),
    );
  }
}
