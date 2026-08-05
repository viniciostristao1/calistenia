import 'package:flutter/material.dart';

import '../models/conquista.dart';
import '../theme/app_colors.dart';

/// Ícone visual de uma conquista. Medalhas (🥈/🥇) são emoji; os troféus são
/// desenhados com o ícone de troféu, tintado de PRATA ou OURO (não há emoji de
/// troféu prateado). `ativo=false` deixa apagado (conquista bloqueada/perdida).
class ConquistaBadge extends StatelessWidget {
  const ConquistaBadge({
    super.key,
    required this.tipo,
    this.size = 24,
    this.ativo = true,
  });

  static const _prata = Color(0xFFC0C7D2);
  static const _ouro = Color(0xFFF4C542);

  final TipoConquista tipo;
  final double size;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final cor = switch (tipo) {
      TipoConquista.trofeuPrata => _prata,
      TipoConquista.trofeuOuro => _ouro,
      _ => null, // medalhas usam emoji
    };
    if (cor != null) {
      return Icon(Icons.emoji_events,
          size: size, color: ativo ? cor : AppColors.dim2);
    }
    return Opacity(
      opacity: ativo ? 1 : 0.35,
      child: Text(tipo.emoji, style: TextStyle(fontSize: size)),
    );
  }
}
