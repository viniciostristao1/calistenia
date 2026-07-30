import 'package:flutter/material.dart';

/// Paleta do app (tema escuro). Ponto único de verdade das cores.
abstract final class AppColors {
  static const bg = Color(0xFF0E0F13); // fundo
  static const surface = Color(0xFF191C22); // cards
  static const surface2 = Color(0xFF212530); // elevação / hover
  static const line = Color(0x12FFFFFF); // divisórias ~7% branco
  static const lineStrong = Color(0x1FFFFFFF); // ~12% branco

  static const text = Color(0xFFEDEFF3); // texto principal
  static const dim = Color(0xFF8B93A1); // texto secundário
  static const dim2 = Color(0xFF5F6674); // texto terciário / ícones apagados

  // Cores semânticas das fases do cronômetro.
  static const prep = Color(0xFFF2B84B); // preparação (prepare-se)
  static const exec = Color(0xFF33D17F); // execução (faça o movimento)
  static const rest = Color(0xFF4C8DFF); // descanso

  static const onAccent = Color(0xFF08130C); // texto sobre cor forte
  static const danger = Color(0xFFFF7A7A);
  static const amber = prep;
  static const green = exec;
  static const blue = rest;
}
