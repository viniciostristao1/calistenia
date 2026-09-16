import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../fx_params.dart';

/// **Conteúdo: pontuação subindo** — o número grande com as **três setas
/// subindo** em ciclo (mesma linguagem do "subiu de nível").
class ScoreRising extends StatefulWidget {
  const ScoreRising({
    super.key,
    required this.params,
    required this.valor,
    required this.cor,
    required this.entrada,
  });

  final FxParams params;
  final num valor;
  final Color cor;

  /// 0..1 — entrada do número (pop + fade) sincronizada com o baú.
  final double entrada;

  @override
  State<ScoreRising> createState() => ScoreRisingState();
}

class ScoreRisingState extends State<ScoreRising>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.params.effectiveDuration,
  )..repeat();

  /// Onde cada uma das 3 setas sobe (esquerda, centro, direita).
  static const _setasX = [-58.0, 0.0, 58.0];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _seta(int i) {
    final ph = (_ctrl.value + i / 3) % 1.0;
    final op = sin(pi * ph).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(_setasX[i], 48 - ph * 108),
      child: Transform.scale(
        scale: 0.7 + 0.4 * op,
        child: Opacity(
          opacity: (op * 0.95).clamp(0.0, 1.0),
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 28,
            color: widget.cor,
            shadows: [
              Shadow(color: widget.cor.withValues(alpha: 0.6), blurRadius: 14),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entrada.clamp(0.0, 1.0);
    return SizedBox(
      width: 220,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [_seta(0), _seta(1), _seta(2)],
            ),
          ),
          // A pontuação por cima das setas (entra com pop).
          Opacity(
            opacity: e,
            child: Transform.scale(
              scale: 0.7 + 0.3 * e,
              child: Text(
                '+${widget.valor.round()}',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: widget.cor.withValues(alpha: 0.75),
                      blurRadius: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
