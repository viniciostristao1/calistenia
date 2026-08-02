import 'package:flutter/material.dart';

/// Tema de destaque (cor da marca/ação). O usuário escolhe nas configurações.
enum TemaApp { azul, ambar }

/// Paleta do app (tema escuro, azul-escuro/navy). Ponto único de verdade das cores.
///
/// `accent`/`onAccent` são a cor de MARCA/AÇÃO e mudam conforme o [TemaApp]
/// escolhido (getters mutáveis — ver [aplicarTema]). As cores de FASE
/// (prep/exec/rest) são semânticas e não mudam com o tema.
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

  // Variantes de accent (marca/ação). O tema escolhe qual está ativa.
  static const accentAzul = Color(0xFF3B82F6);
  static const onAccentAzul = Color(0xFFF2F7FF);
  static const accentAmbar = Color(0xFFF5A524);
  static const onAccentAmbar = Color(0xFF231402); // texto escuro sobre âmbar claro

  // Âmbar é a cor OFICIAL (padrão) do app; azul é opção nas configurações.
  static Color _accent = accentAmbar;
  static Color _onAccent = onAccentAmbar;

  /// Cor de marca/ação atual (muda com o tema).
  static Color get accent => _accent;
  static Color get onAccent => _onAccent;

  /// Aplica o tema de destaque (chamado no build do app conforme a preferência).
  static void aplicarTema(TemaApp t) {
    if (t == TemaApp.ambar) {
      _accent = accentAmbar;
      _onAccent = onAccentAmbar;
    } else {
      _accent = accentAzul;
      _onAccent = onAccentAzul;
    }
  }

  // Cores semânticas das fases do cronômetro (mantidas bem distinguíveis).
  static const prep = Color(0xFF5DE0A0); // preparação (verde claro — "prepare-se")
  static const exec = Color(0xFFFF9538); // execução (laranja — "faça / vai")
  static const rest = Color(0xFF5B9CFF); // descanso (azul claro — "recupere")
  static const onFase = Color(0xFF06111F); // texto sobre uma cor de fase clara

  static const danger = Color(0xFFFF6B6B);

  /// 10 cores para marcar exercícios (o "pontinho" antes do nome).
  static const paletaExercicio = <Color>[
    Color(0xFF5B9CFF), // azul
    Color(0xFF31C971), // verde
    Color(0xFFF5A524), // âmbar
    Color(0xFFFF6B6B), // vermelho
    Color(0xFFB88BFF), // roxo
    Color(0xFF3DD6D0), // ciano
    Color(0xFFFF8FB0), // rosa
    Color(0xFFFF9538), // laranja
    Color(0xFF9CCC65), // lima
    Color(0xFFC0C7D2), // cinza claro
  ];

  /// Cor do exercício pelo índice (com wrap defensivo).
  static Color corExercicio(int i) =>
      paletaExercicio[i % paletaExercicio.length];
}
