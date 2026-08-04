import 'package:flutter/material.dart';

import '../models/conquista.dart';
import '../theme/app_colors.dart';

/// Ícone visual de uma conquista. Medalhas (🥈/🥇) e coroa (👑) são emoji; o
/// Troféu de Prata é um ícone PRATEADO (não existe emoji de troféu de prata).
/// `ativo=false` deixa apagado (conquista bloqueada/perdida).
class ConquistaBadge extends StatelessWidget {
  const ConquistaBadge({
    super.key,
    required this.tipo,
    this.size = 24,
    this.ativo = true,
  });

  final TipoConquista tipo;
  final double size;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    if (tipo == TipoConquista.trofeuPrata) {
      return Icon(
        Icons.emoji_events,
        size: size,
        color: ativo ? const Color(0xFFC0C7D2) : AppColors.dim2, // prata
      );
    }
    return Opacity(
      opacity: ativo ? 1 : 0.35,
      child: Text(tipo.emoji, style: TextStyle(fontSize: size)),
    );
  }
}
