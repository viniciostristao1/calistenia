import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../effects/delayed.dart';
import '../effects/glow.dart';
import '../effects/rays.dart';
import '../effects/spin3d.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';
import 'star_3d.dart';

/// **Recompensa: estrela.** Molécula = `RadialRays` (holofote girando) +
/// `ParticleBurst` (explode no pouso) + `GlowHalo` + estrela que gira no
/// **próprio eixo** em 3D (`Spin3D`) e pousa com overshoot — o "pop de moeda"
/// da linguagem de jogos mobile.
///
/// Composição de átomos, não um monolito: trocar o glow ou as partículas é
/// mexer só aqui, sem tocar em quem dispara `RewardType.star`.
class StarBurst extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RadialRays(color: color, diameter: size * 2.6, params: params),
          // Partículas explodem quando a estrela "pousa" (fim do giro).
          Delayed(
            delay: Duration(
              milliseconds: (params.effectiveDuration.inMilliseconds * 0.5)
                  .round(),
            ),
            child: ParticleBurst(
              params: params,
              colors: [color, Colors.white, context.accent],
              shapes: const [ParticleShape.spark, ParticleShape.circle],
            ),
          ),
          GlowHalo(color: color, diameter: size * 1.9, params: params),
          Spin3D(
            params: params,
            turns: 3,
            fromScale: 0.15,
            child: Star3D(size: size, color: color),
          ),
        ],
      ),
    );
  }
}
