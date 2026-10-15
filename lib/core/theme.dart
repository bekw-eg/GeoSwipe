import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0C1425);
  static const surface = Color(0xFF151F35);
  static const elevated = Color(0xFF1C2942);
  static const violet = Color(0xFFA897FF);
  static const blue = Color(0xFF6D9FFF);
  static const mint = Color(0xFF66E3CD);
  static const text = Color(0xFFF4F5FC);
  static const muted = Color(0xFFA4B0C7);
  static const line = Color(0xFF2A3650);
  static const warning = Color(0xFFFFCF91);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.violet,
    secondary: AppColors.mint,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onPrimary: AppColors.background,
  ),
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 27,
      fontWeight: FontWeight.w700,
      letterSpacing: -.7,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      letterSpacing: -.4,
    ),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.background,
    indicatorColor: AppColors.violet.withValues(alpha: .13),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: states.contains(WidgetState.selected)
            ? AppColors.violet
            : AppColors.muted,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.violet
            : AppColors.muted,
      ),
    ),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: AppColors.violet,
    inactiveTrackColor: AppColors.line,
    thumbColor: AppColors.violet,
    trackHeight: 3,
  ),
  dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
);
