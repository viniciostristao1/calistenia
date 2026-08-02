import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema escuro do app. Ponto único de verdade visual.
ThemeData buildAppTheme(TemaApp tema) {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.dark(
      primary: AppColors.accentDoTema(tema),
      onPrimary: AppColors.onAccentDoTema(tema),
      secondary: AppColors.rest,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
    textTheme: base.textTheme
        .apply(
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        )
        .copyWith(
          titleLarge: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dividerColor: AppColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
