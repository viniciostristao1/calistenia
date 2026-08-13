import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema do app (ponto único de verdade visual). Aplica a paleta do [tema]
/// escolhido — inclusive o brilho (Madeira é claro; os demais, escuros).
ThemeData buildAppTheme(TemaApp tema) {
  // Define a paleta atual ANTES de ler os tokens (fundo/superfície/sombra).
  AppColors.aplicarTema(tema);
  final claro = AppColors.brilho == Brightness.light;
  final base = ThemeData(useMaterial3: true, brightness: AppColors.brilho);
  final scheme =
      (claro ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
    primary: AppColors.accentDoTema(tema),
    onPrimary: AppColors.onAccentDoTema(tema),
    secondary: AppColors.rest,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: scheme,
    iconTheme: IconThemeData(color: AppColors.text),
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
        .copyWith(
          titleLarge: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
    appBarTheme: AppBarTheme(
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
        side: BorderSide(color: AppColors.line),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    dividerColor: AppColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      hintStyle: TextStyle(color: AppColors.dim2),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: TextStyle(color: AppColors.text),
      actionTextColor: AppColors.accentDoTema(tema),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
