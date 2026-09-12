import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: entrar quicando.** O elemento cai/entra e assenta com um quique
/// (curva `bounceOut`) — bom para recompensa "pulando" pra fora do baú.
class Bounce extends StatelessWidget {
  const Bounce({
    super.key,
    required this.child,
    this.params = const FxParams(),
    this.drop = 24,
  });

  final Widget child;
  final FxParams params;

  /// De quanto acima ele "cai" (px, × intensidade).
  final double drop;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: params.effectiveDuration,
      curve: Curves.bounceOut,
      builder: (context, t, ch) {
        final dy = -drop * (1 - t) * params.intensity.clamp(0.0, 2.0);
        final scale = ((0.55 + 0.45 * t) * params.scale).clamp(0.0, 3.0);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: ch),
          ),
        );
      },
      child: child,
    );
  }
}
