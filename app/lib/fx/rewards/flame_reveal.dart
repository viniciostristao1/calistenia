import 'dart:math';

import 'package:flutter/material.dart';

import 'flame_3d.dart';

import '../effects/delayed.dart';
import '../effects/glow.dart';
import '../effects/pop_in.dart';
import '../effects/rays.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';
import '../../theme/app_colors.dart';

/// **Recompensa: sequência (chama).** A chama é desenhada à mão e **anima de
/// verdade**: cada língua balança no próprio ritmo (senos com fases diferentes)
/// e o corpo pulsa como fogo. Compõe holofote + halo + faíscas subindo + a
/// chama + o rótulo.
class FlameReveal extends StatelessWidget {
  const FlameReveal({
    super.key,
    this.params = const FxParams(),
    this.color = const Color(0xFFFF7A1A),
    this.label,
  });

  final FxParams params;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final cor = color;
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RadialRays(color: cor, diameter: 220, params: params),
          // Faíscas subindo (gravidade negativa = sobem e aceleram).
          Delayed(
            delay: Duration(
              milliseconds: (params.effectiveDuration.inMilliseconds * 0.35)
                  .round(),
            ),
            child: ParticleBurst(
              params: params,
              colors: [cor, const Color(0xFFFFD43B), Colors.white],
              shapes: const [ParticleShape.spark, ParticleShape.circle],
              direction: -pi / 2,
              spread: 1.2,
              gravity: -140,
            ),
          ),
          GlowHalo(color: cor, diameter: 190, params: params),
          PopIn(
            params: params,
            child: Flame3D(
              size: 150,
              color: cor,
              duracao: params.effectiveDuration,
            ),
          ),
          if (label != null) ...[
            Positioned(
              bottom: 8,
              child: _Label(texto: label!, params: params),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.texto, required this.params});

  final String texto;
  final FxParams params;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: params.effectiveDuration,
    builder: (context, t, child) {
      final op = Interval(0.35, 0.7).transform(t).clamp(0.0, 1.0);
      return Opacity(
        opacity: op,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - op)),
          child: child,
        ),
      );
    },
    child: Text(
      texto,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// Pinta a chama: 3 línguas + núcleo, com as pontas balançando.
