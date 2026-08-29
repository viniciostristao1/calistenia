import 'package:flutter/material.dart';

import '../models/conquista.dart';
import '../theme/app_colors.dart';

const _prata = Color(0xFFC0C7D2);
const _ouro = Color(0xFFF4C542);

/// Cor da conquista (prata/ouro) — para tingir badge e barra de progresso.
Color corConquista(TipoConquista t) => switch (t) {
      TipoConquista.medalhaPrata || TipoConquista.trofeuPrata => _prata,
      TipoConquista.medalhaOuro || TipoConquista.trofeuOuro => _ouro,
    };

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

  final TipoConquista tipo;
  final double size;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final ehTrofeu = tipo == TipoConquista.trofeuPrata ||
        tipo == TipoConquista.trofeuOuro;
    if (ehTrofeu) {
      final trofeuSize = size * 1.4;
      return SizedBox(
        width: trofeuSize,
        height: trofeuSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.emoji_events,
                size: trofeuSize,
                color: ativo ? corConquista(tipo) : AppColors.dim2),
            if (ativo) ...[
              // Brilho diagonal no copo — sensação de metal polido, como nas medalhas.
              Positioned(
                left: trofeuSize * 0.28,
                top: trofeuSize * 0.18,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: trofeuSize * 0.09,
                    height: trofeuSize * 0.32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              // Segundo brilho menor, mais em cima.
              Positioned(
                left: trofeuSize * 0.36,
                top: trofeuSize * 0.16,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: trofeuSize * 0.05,
                    height: trofeuSize * 0.14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              // Linha de luz na base — relevo.
              Positioned(
                bottom: trofeuSize * 0.22,
                left: trofeuSize * 0.32,
                right: trofeuSize * 0.32,
                child: Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Opacity(
      opacity: ativo ? 1 : 0.35,
      child: Text(tipo.emoji, style: TextStyle(fontSize: size)),
    );
  }
}
