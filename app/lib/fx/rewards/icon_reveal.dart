import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../effects/pulse.dart';
import '../effects/shine_sweep.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';

/// **Reveal genérico de um ícone** — a base de várias recompensas
/// (troféu, medalha, subir de nível, sequência). Compõe átomos:
/// `ParticleBurst` + ícone que surge com overshoot e leve balanço +
/// `ShineSweep` (brilho passando) + rótulo que aparece depois. Opcionalmente
/// `Pulse` (para "respirar", bom na sequência/chama).
///
/// Parametrizado por [icon]/[color]/[label] → o mesmo widget cobre troféu de
/// ouro, medalha de prata, etc., puxando os metadados do `RewardType`.
class IconReveal extends StatefulWidget {
  const IconReveal({
    super.key,
    required this.icon,
    required this.color,
    this.label,
    this.params = const FxParams(),
    this.size = 100,
    this.pulse = false,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final FxParams params;
  final double size;

  /// Se o ícone fica "respirando" (bom para sequência/chama).
  final bool pulse;

  @override
  State<IconReveal> createState() => _IconRevealState();
}

class _IconRevealState extends State<IconReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.params.effectiveDuration,
  );

  @override
  void initState() {
    super.initState();
    widget.params.loopForever ? _ctrl.repeat() : _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = ShineSweep(
      params: widget.params,
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
        shadows: [
          Shadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 22),
        ],
      ),
    );

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ParticleBurst(
            params: widget.params,
            colors: [widget.color, Colors.white, context.accent],
            shapes: const [ParticleShape.spark, ParticleShape.circle],
          ),
          AnimatedBuilder(
            animation: _ctrl,
            child: widget.pulse ? Pulse(params: widget.params, child: icon) : icon,
            builder: (context, child) {
              final v = _ctrl.value;
              final scale = Interval(0.0, 0.55, curve: Curves.elasticOut)
                      .transform(v) *
                  widget.params.scale;
              // Balanço curto que amortece.
              final wobble = sin(v * 3 * pi) * (1 - v) * 0.16;
              final iconOp = Interval(0.0, 0.16).transform(v).clamp(0.0, 1.0);
              final labelOp = Interval(0.4, 0.72).transform(v).clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: iconOp,
                    child: Transform.rotate(
                      angle: wobble,
                      child: Transform.scale(
                          scale: scale.clamp(0.0, 4.0), child: child),
                    ),
                  ),
                  if (widget.label != null) ...[
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: labelOp,
                      child: Text(
                        widget.label!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
