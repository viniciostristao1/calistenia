import 'dart:math';

import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: flash de tela.** Um clarão que sobe rápido e some — reforça o
/// impacto de um momento (abrir baú, subir de nível). Preenche a área e não
/// intercepta toques.
class ScreenFlash extends StatefulWidget {
  const ScreenFlash({
    super.key,
    this.color = Colors.white,
    this.params = const FxParams(),
    this.peak = 0.55,
  });

  final Color color;
  final FxParams params;

  /// Opacidade máxima do clarão (× intensidade).
  final double peak;

  @override
  State<ScreenFlash> createState() => _ScreenFlashState();
}

class _ScreenFlashState extends State<ScreenFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(
        milliseconds:
            (widget.params.effectiveDuration.inMilliseconds * 0.5).round().clamp(120, 2000)),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          // Sobe e desce (sino) ao longo do tempo.
          final a = sin(pi * _ctrl.value) *
              widget.peak *
              widget.params.intensity.clamp(0.0, 2.0);
          return SizedBox.expand(
            child: ColoredBox(
                color: widget.color.withValues(alpha: a.clamp(0.0, 1.0))),
          );
        },
      ),
    );
  }
}
