import 'dart:math';

import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: brilho diagonal passando por cima.** Uma faixa de luz varre o
/// elemento da esquerda para a direita — sensação de "polido/desbloqueado".
/// Recortado ao tamanho do filho (não vaza). [cycles] > 1 faz a luz passar
/// várias vezes (movimento contínuo enquanto a recompensa está na tela).
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    required this.child,
    this.params = const FxParams(),
    this.color = Colors.white,
    this.angle = -0.4,
    this.cycles = 1,
  });

  final Widget child;
  final FxParams params;
  final Color color;

  /// Inclinação da faixa (radianos).
  final double angle;

  /// Quantas vezes a luz passa (ignorado no loop infinito, que repete sempre).
  final int cycles;

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (widget.params.effectiveDuration.inMilliseconds * 0.8)
          .round()
          .clamp(200, 4000),
    ),
  );

  int _feitas = 0;

  @override
  void initState() {
    super.initState();
    if (widget.params.loopForever) {
      _ctrl.repeat();
    } else {
      _ctrl.addStatusListener(_aoTerminar);
      _ctrl.forward();
    }
  }

  /// Recomeça a passada até completar [ShineSweep.cycles].
  void _aoTerminar(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    _feitas++;
    if (_feitas < widget.cycles) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_aoTerminar);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth.isFinite ? c.maxWidth : 120.0;
                  return AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      // Vai de bem antes da borda esquerda até bem depois da direita.
                      final dx =
                          (-w) +
                          (2.4 * w) * Curves.easeInOut.transform(_ctrl.value);
                      final alpha =
                          sin(pi * _ctrl.value).clamp(0.0, 1.0) *
                          0.55 *
                          widget.params.intensity.clamp(0.0, 2.0);
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: Transform.rotate(
                          angle: widget.angle,
                          child: Container(
                            width: w * 0.22,
                            height: c.maxHeight.isFinite
                                ? c.maxHeight * 1.6
                                : 200.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.color.withValues(alpha: 0),
                                  widget.color.withValues(
                                    alpha: alpha.clamp(0.0, 1.0),
                                  ),
                                  widget.color.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
