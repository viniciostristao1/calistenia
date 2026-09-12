import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: surgir com escala + overshoot.** O elemento nasce pequeno e "salta"
/// até o tamanho final (curva elástica por padrão), com fade. Base de quase todo
/// reveal de recompensa.
class PopIn extends StatelessWidget {
  const PopIn({
    super.key,
    required this.child,
    this.params = const FxParams(),
    this.curve = Curves.elasticOut,
    this.from = 0.35,
  });

  final Widget child;
  final FxParams params;
  final Curve curve;

  /// Escala inicial (0..1) de onde o pop começa.
  final double from;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: params.effectiveDuration,
      curve: curve,
      builder: (context, t, ch) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: ((from + (1 - from) * t) * params.scale).clamp(0.0, 4.0),
          child: ch,
        ),
      ),
      child: child,
    );
  }
}
