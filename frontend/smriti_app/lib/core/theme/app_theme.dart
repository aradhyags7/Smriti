import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
class AppTheme {
static ThemeData get lightTheme {
return ThemeData(
useMaterial3: true,
colorScheme: ColorScheme.light(
primary: AppColors.primary,
onPrimary: AppColors.onPrimary,
primaryContainer: AppColors.primaryContainer,
onPrimaryContainer: AppColors.onPrimaryContainer,
secondary: AppColors.secondary,
onSecondary: AppColors.onPrimary,
secondaryContainer: AppColors.secondaryContainer,
onSecondaryContainer: AppColors.onSecondaryContainer,
tertiary: AppColors.tertiary,
onTertiary: AppColors.onPrimary,
tertiaryContainer: AppColors.tertiaryContainer,
onTertiaryContainer: AppColors.onTertiaryContainer,
error: AppColors.error,
onError: AppColors.onError,
surface: AppColors.surface,
onSurface: AppColors.onSurface,
onSurfaceVariant: AppColors.onSurfaceVariant,
outline: AppColors.outline,
outlineVariant: AppColors.outlineVariant,
),
scaffoldBackgroundColor: AppColors.canvas,
textTheme: AppTypography.getTextTheme(),
elevatedButtonTheme: ElevatedButtonThemeData(
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: AppColors.onPrimary,
minimumSize: const Size(double.infinity, 56), // 3.5rem min touch
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
textStyle: AppTypography.getTextTheme().bodyMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
),
outlinedButtonTheme: OutlinedButtonThemeData(
style: OutlinedButton.styleFrom(
foregroundColor: AppColors.primary,
backgroundColor: AppColors.paleLinen,
minimumSize: const Size(double.infinity, 56),
side: const BorderSide(color: Color(0xFFD8CFBA), width: 1.5),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
textStyle: AppTypography.getTextTheme().bodyMedium?.copyWith(
fontWeight: FontWeight.w600,
),
),
),
inputDecorationTheme: InputDecorationTheme(
filled: true,
fillColor: AppColors.surfaceContainerLowest,
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(color: AppColors.outlineVariant),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(color: AppColors.outlineVariant),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(color: AppColors.tertiary, width: 2),
),
),
cardTheme: CardThemeData(
color: AppColors.surfaceContainerLowest,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(24),
side: const BorderSide(color: Color(0xFFE8E0CE), width: 1.5),
),
margin: EdgeInsets.zero,
),
);
}
}
