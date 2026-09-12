import 'dart:math';

import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: tremida curta amortecida.** Bom para antecipação (antes do baú
/// abrir) ou reforço de impacto. Oscila e desacelera até parar.
class Shake extends StatefulWidget {
  const Shake({
    super.key,
    required this.child,
    this.params = const FxParams(),
    this.cycles = 4,
    this.amplitude = 8,
    this.rotate = true,
    this.autostart = true,
  });

  final Widget child;
  final FxParams params;

  /// Nº de idas-e-vindas.
  final double cycles;

  /// Deslocamento máximo em px (× intensidade).
  final double amplitude;

  /// Se também gira levemente junto.
  final bool rotate;
  final bool autostart;

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.params.effectiveDuration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.autostart) start();
  }

  /// Dispara (ou re-dispara) a tremida.
  void start() {
    if (widget.params.loopForever) {
      _ctrl.repeat();
    } else {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amp = widget.amplitude * widget.params.intensity.clamp(0.0, 2.0);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final damp = pow(1 - t, 2).toDouble(); // amortece até 0
        final dx = sin(t * widget.cycles * 2 * pi) * amp * damp;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: widget.rotate
              ? Transform.rotate(angle: dx / 220, child: child)
              : child,
        );
      },
      child: widget.child,
    );
  }
}
