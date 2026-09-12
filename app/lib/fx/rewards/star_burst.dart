import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../effects/glow.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';

/// **Recompensa: estrela.** Molécula = `GlowHalo` + `ParticleBurst` +
/// estrela que surge pequena, cresce com overshoot e gira.
///
/// Composição de átomos, não um monolito: trocar o glow ou as partículas é
/// mexer só aqui, sem tocar em quem dispara `RewardType.star`.
class StarBurst extends StatefulWidget {
  const StarBurst({
    super.key,
    this.params = const FxParams(),
    this.color = AppColors.estrela,
    this.size = 104,
  });

  final FxParams params;
  final Color color;
  final double size;

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
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
    final turns = 1.0; // uma volta enquanto surge
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Partículas atrás (explosão radial, estrelinhas + pontos).
          ParticleBurst(
            params: widget.params,
            colors: [widget.color, Colors.white, context.accent],
            shapes: const [ParticleShape.spark, ParticleShape.circle],
          ),
          // Halo de brilho.
          GlowHalo(
            color: widget.color,
            diameter: widget.size * 1.9,
            params: widget.params,
          ),
          // A estrela: escala com overshoot + giro.
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final v = _ctrl.value;
              final scale = Interval(0.0, 0.6, curve: Curves.elasticOut)
                      .transform(v) *
                  widget.params.scale;
              final spin =
                  Curves.easeOutCubic.transform(v) * 2 * pi * turns;
              final op = Interval(0.0, 0.18).transform(v).clamp(0.0, 1.0);
              return Opacity(
                opacity: op,
                child: Transform.rotate(
                  angle: spin,
                  child: Transform.scale(
                      scale: scale.clamp(0.0, 4.0), child: child),
                ),
              );
            },
            child: Icon(
              Icons.star_rounded,
              size: widget.size,
              color: widget.color,
              shadows: [
                Shadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
