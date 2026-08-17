import 'package:flutter/material.dart';

/// Tema visual do app. Azul/âmbar = navy escuro (só muda o accent); espresso e
/// madeira = sistemas neumórficos próprios (espresso escuro, madeira claro).
/// O usuário escolhe nas configurações.
enum TemaApp { azul, ambar, espresso, madeira }

/// Uma paleta completa (tokens de cor de um tema). Fundo, superfícies e sombras
/// mudam por tema — por isso `AppColors` os expõe como getters que leem a
/// paleta atual (definida por [AppColors.aplicarTema]).
class Paleta {
  final Color bg, surface, surface2, line, lineStrong, text, dim, dim2;
  final Color accent, onAccent;
  final Color neuHi, neuLo; // sombras neumórficas: luz (topo-esq) / escuro (base-dir)
  final Brightness brilho;
  const Paleta({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.dim,
    required this.dim2,
    required this.accent,
    required this.onAccent,
    required this.neuHi,
    required this.neuLo,
    required this.brilho,
  });
}

/// Paleta do app. Cores de FASE (prep/exec/rest) e a paleta de exercícios são
/// semânticas e constantes; fundo/superfície/texto/sombra vêm da [Paleta] atual.
abstract final class AppColors {
  // ---- tokens dependentes de tema (getters lêem a paleta atual) ----
  static Paleta _pal = _palDe(TemaApp.ambar);

  /// Troca a paleta atual (chamado em `buildAppTheme`, a cada (re)build do tema).
  static void aplicarTema(TemaApp t) => _pal = _palDe(t);

  static Color get bg => _pal.bg;
  static Color get surface => _pal.surface;
  static Color get surface2 => _pal.surface2;
  static Color get line => _pal.line;
  static Color get lineStrong => _pal.lineStrong;
  static Color get text => _pal.text;
  static Color get dim => _pal.dim;
  static Color get dim2 => _pal.dim2;
  static Color get neuHi => _pal.neuHi;
  static Color get neuLo => _pal.neuLo;
  static Brightness get brilho => _pal.brilho;

  // ---- accent (marca/ação) e fundo por tema (p/ preview no seletor) ----
  static Color accentDoTema(TemaApp t) => _palDe(t).accent;
  static Color onAccentDoTema(TemaApp t) => _palDe(t).onAccent;
  static Color fundoDoTema(TemaApp t) => _palDe(t).bg;

  // Constantes de accent (referência/compat).
  static const accentAzul = Color(0xFF3B82F6);
  static const onAccentAzul = Color(0xFFF2F7FF);
  static const accentAmbar = Color(0xFFF5A524);
  static const onAccentAmbar = Color(0xFF231402);

  // ---- cores semânticas das fases do cronômetro (constantes) ----
  static const prep = Color(0xFF5DE0A0); // preparação (verde claro)
  static const exec = Color(0xFFFF9538); // execução (laranja)
  static const rest = Color(0xFF5B9CFF); // descanso (azul claro)
  static const onFase = Color(0xFF06111F); // texto sobre cor de fase clara
  static const danger = Color(0xFFFF6B6B);

  /// Amarelo fixo das INSÍGNIAS (estrela) — não muda com o tema (a estrela é
  /// sempre amarela, por definição do usuário).
  static const estrela = Color(0xFFFFC93C);

  /// 10 cores para marcar exercícios (o "pontinho" antes do nome).
  static const paletaExercicio = <Color>[
    Color(0xFF5B9CFF), Color(0xFF31C971), Color(0xFFF5A524), Color(0xFFFF6B6B),
    Color(0xFFB88BFF), Color(0xFF3DD6D0), Color(0xFFFF8FB0), Color(0xFFFF9538),
    Color(0xFF9CCC65), Color(0xFFC0C7D2),
  ];

  static Color corExercicio(int i) =>
      paletaExercicio[i % paletaExercicio.length];

  // ---- as 5 paletas ----
  static Paleta _palDe(TemaApp t) => switch (t) {
        TemaApp.azul => _navy(const Color(0xFF3B82F6), const Color(0xFFF2F7FF)),
        TemaApp.ambar => _navy(accentAmbar, onAccentAmbar),
        TemaApp.espresso => _espresso,
        TemaApp.madeira => _madeira,
      };

  /// Navy escuro histórico (azul/âmbar): muda só o accent.
  static Paleta _navy(Color accent, Color onAccent) => Paleta(
        bg: const Color(0xFF0A0F1C),
        surface: const Color(0xFF121A2E),
        surface2: const Color(0xFF1B2540),
        line: const Color(0x14FFFFFF),
        lineStrong: const Color(0x26FFFFFF),
        text: const Color(0xFFEAF0FB),
        dim: const Color(0xFF8A96AE),
        dim2: const Color(0xFF56607A),
        accent: accent,
        onAccent: onAccent,
        neuHi: const Color(0xFF141D33),
        neuLo: const Color(0xFF05080A),
        brilho: Brightness.dark,
      );

  static const Paleta _espresso = Paleta(
    bg: Color(0xFF2A2620),
    surface: Color(0xFF322D26),
    surface2: Color(0xFF3A342B),
    line: Color(0x12FFFFFF),
    lineStrong: Color(0x22FFFFFF),
    text: Color(0xFFEFE8DC),
    dim: Color(0xFF9C917E),
    dim2: Color(0xFF6B6152),
    accent: Color(0xFFEBA84C),
    onAccent: Color(0xFF241700),
    neuHi: Color(0xFF342F27),
    neuLo: Color(0xFF1B1813),
    brilho: Brightness.dark,
  );

  static const Paleta _madeira = Paleta(
    bg: Color(0xFFD8C7AC),
    surface: Color(0xFFE0D1B9),
    surface2: Color(0xFFCBB897),
    line: Color(0x14000000),
    lineStrong: Color(0x28000000),
    text: Color(0xFF382E20),
    dim: Color(0xFF8A7A60),
    dim2: Color(0xFFA2916F),
    accent: Color(0xFFB5652E),
    onAccent: Color(0xFFFFF3E7),
    neuHi: Color(0xFFEADCC2),
    neuLo: Color(0xFFB6A07E),
    brilho: Brightness.light,
  );
}

/// Cor de destaque atual, lida via Theme — widgets que a usam rebuildam na hora
/// quando o tema muda.
extension AccentContext on BuildContext {
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get onAccent => Theme.of(this).colorScheme.onPrimary;
}
