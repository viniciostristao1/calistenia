import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: pulsar (respirar).** Escala vai e volta em loop suave — bom para
/// chamar atenção (chama de sequência, botão "resgatar").
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    this.params = const FxParams(),
    this.min = 0.94,
    this.max = 1.08,
  });

  final Widget child;
  final FxParams params;
  final double min;
  final double max;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(
        milliseconds:
            (widget.params.effectiveDuration.inMilliseconds * 0.7).round().clamp(200, 4000)),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final base = widget.min + (widget.max - widget.min) * t;
        // amplitude segue a intensidade (1 = padrão)
        final amp = 1 + (base - 1) * widget.params.intensity.clamp(0.0, 2.0);
        return Transform.scale(scale: (amp * widget.params.scale).clamp(0.0, 3.0), child: child);
      },
      child: widget.child,
    );
  }
}
