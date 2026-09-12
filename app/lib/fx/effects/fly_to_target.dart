import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: voar de um ponto a outro.** Move o filho de [begin] até [end]
/// (offsets relativos à posição natural), com fade de entrada. Base de
/// "recompensa voa para o contador" ou "sobe do baú".
class FlyToTarget extends StatelessWidget {
  const FlyToTarget({
    super.key,
    required this.child,
    this.params = const FxParams(),
    this.begin = const Offset(0, 40),
    this.end = Offset.zero,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final FxParams params;
  final Offset begin;
  final Offset end;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: params.effectiveDuration,
      curve: curve,
      builder: (context, t, ch) {
        final o = Offset.lerp(begin, end, t)!;
        final op = Interval(0.0, 0.2).transform(t).clamp(0.0, 1.0);
        return Transform.translate(
          offset: o,
          child: Opacity(opacity: op, child: ch),
        );
      },
      child: child,
    );
  }
}
