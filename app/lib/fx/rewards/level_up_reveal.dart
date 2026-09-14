import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../effects/delayed.dart';
import '../effects/glow.dart';
import '../effects/rays.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';

/// **Recompensa: subiu de nível (veio do Lab).** Duas setas sobem em ciclo —
/// aparecem, sobem e somem, uma defasada da outra — e no meio aparece a
/// **pontuação** (quantos níveis subiu). Compõe holofote + halo + partículas
/// subindo + as setas + o número.
class LevelUpReveal extends StatefulWidget {
  const LevelUpReveal({
    super.key,
    this.params = const FxParams(),
    this.color = const Color(0xFFF4C542),
    this.value = 1,
  });

  final FxParams params;
  final Color color;
  final num value;

  @override
  State<LevelUpReveal> createState() => _LevelUpRevealState();
}

class _LevelUpRevealState extends State<LevelUpReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.params.effectiveDuration,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _seta(int i) {
    final ph = (_ctrl.value + i * 0.5) % 1.0;
    final op = sin(pi * ph).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(i == 0 ? -60 : 60, 62 - ph * 128),
      child: Transform.scale(
        scale: 0.7 + 0.4 * op,
        child: Opacity(
          opacity: op,
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 30,
            color: widget.color,
            shadows: [
              Shadow(
                color: widget.color.withValues(alpha: 0.65),
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pontuacao() => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: widget.params.effectiveDuration,
    curve: Curves.elasticOut,
    builder: (context, t, child) => Transform.scale(
      scale: t.clamp(0.0, 1.4),
      child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+${widget.value.round()}',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 54,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: [
              Shadow(
                color: widget.color.withValues(alpha: 0.7),
                blurRadius: 22,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RadialRays(color: widget.color, diameter: 220, params: widget.params),
          Delayed(
            delay: Duration(
              milliseconds:
                  (widget.params.effectiveDuration.inMilliseconds * 0.35)
                      .round(),
            ),
            child: ParticleBurst(
              params: widget.params,
              colors: [widget.color, Colors.white],
              shapes: const [ParticleShape.spark, ParticleShape.circle],
              direction: -pi / 2,
              spread: 1.0,
              gravity: -140,
            ),
          ),
          GlowHalo(color: widget.color, diameter: 190, params: widget.params),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [_seta(0), _seta(1)],
            ),
          ),
          _pontuacao(),
        ],
      ),
    );
  }
}
