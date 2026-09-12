import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: aparecer e desaparecer.** Fade in no começo, segura, fade out no
/// fim — ideal para rótulos/carimbos passageiros ("+1 série", "Concluído").
class FadeThrough extends StatelessWidget {
  const FadeThrough({
    super.key,
    required this.child,
    this.params = const FxParams(),
    this.fadeInEnd = 0.15,
    this.fadeOutStart = 0.7,
  });

  final Widget child;
  final FxParams params;

  /// Fração do tempo em que termina de aparecer / começa a sumir.
  final double fadeInEnd;
  final double fadeOutStart;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: params.effectiveDuration,
      builder: (context, t, ch) {
        final fin = Interval(0.0, fadeInEnd).transform(t);
        final fout = 1 - Interval(fadeOutStart, 1.0).transform(t);
        return Opacity(opacity: (fin * fout).clamp(0.0, 1.0), child: ch);
      },
      child: child,
    );
  }
}
