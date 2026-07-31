import 'package:flutter/material.dart';

/// Paleta do app (tema escuro, azul-escuro/navy). Ponto único de verdade das cores.
///
/// Dois papéis distintos, para não se confundirem:
///  - **accent** (azul) = marca / ação (FAB, "iniciar", seleção de dia, botões).
///  - **prep/exec/rest** = cores SEMÂNTICAS das fases do cronômetro (não são a marca).
abstract final class AppColors {
  // Base — azul-escuro profundo (navy). É a "cara" do app.
  static const bg = Color(0xFF0A0F1C); // fundo (navy quase preto)
  static const surface = Color(0xFF121A2E); // cards
  static const surface2 = Color(0xFF1B2540); // elevação / campos / hover
  static const line = Color(0x14FFFFFF); // divisórias ~8% branco
  static const lineStrong = Color(0x26FFFFFF); // ~15% branco

  static const text = Color(0xFFEAF0FB); // texto principal (branco azulado)
  static const dim = Color(0xFF8A96AE); // texto secundário
  static const dim2 = Color(0xFF56607A); // terciário / ícones apagados

  // Accent / marca — azul vivo. Ações e seleção.
  static const accent = Color(0xFF3B82F6);
  static const accentDark = Color(0xFF2563EB);
  static const onAccent = Color(0xFFF2F7FF); // texto/ícone sobre o accent

  // Cores semânticas das fases do cronômetro (mantidas bem distinguíveis).
  static const prep = Color(0xFF5DE0A0); // preparação (verde claro — "prepare-se")
  static const exec = Color(0xFFFF9538); // execução (laranja — "faça / vai")
  static const rest = Color(0xFF5B9CFF); // descanso (azul claro — "recupere")
  static const onFase = Color(0xFF06111F); // texto sobre uma cor de fase clara

  static const danger = Color(0xFFFF6B6B);
}
