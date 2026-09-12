import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: halo de brilho pulsante.** Um disco de luz radial que respira
/// (escala + opacidade) atrás de um elemento. Fica bem sob estrela/troféu/baú.
class GlowHalo extends StatefulWidget {
  const GlowHalo({
    super.key,
    required this.color,
    this.diameter = 160,
    this.params = const FxParams(),
    this.child,
  });

  final Color color;
  final double diameter;
  final FxParams params;

  /// Opcional: colocado centralizado sobre o halo.
  final Widget? child;

  @override
  State<GlowHalo> createState() => _GlowHaloState();
}

class _GlowHaloState extends State<GlowHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(
        milliseconds:
            (widget.params.effectiveDuration.inMilliseconds * 0.9).round().clamp(200, 4000)),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.params.intensity.clamp(0.0, 2.0);
    final d = widget.diameter * widget.params.scale;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value); // 0..1..0
        final scale = 0.85 + 0.30 * t * intensity;
        final alpha = (0.18 + 0.30 * t) * intensity;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: alpha.clamp(0.0, 1.0)),
                      widget.color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            ?child,
          ],
        );
      },
      child: widget.child,
    );
  }
}
