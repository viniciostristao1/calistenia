import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../effects/delayed.dart';
import '../effects/glow.dart';
import '../effects/pulse.dart';
import '../effects/rays.dart';
import '../effects/shine_sweep.dart';
import '../effects/spin3d.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';

/// **Reveal genérico de um ícone** — a base de várias recompensas
/// (troféu, medalha, subir de nível, sequência). O ícone chega girando no
/// **próprio eixo** em 3D (`Spin3D`), sob `RadialRays` + `GlowHalo` +
/// `ParticleBurst` e com `ShineSweep` por cima; o rótulo sobe depois do pouso.
/// Opcionalmente `Pulse` (para "respirar", bom na sequência/chama).
///
/// Parametrizado por [icon]/[color]/[label] → o mesmo widget cobre troféu de
/// ouro, medalha de prata, etc., puxando os metadados do `RewardType`.
class IconReveal extends StatelessWidget {
  const IconReveal({
    super.key,
    this.icon,
    required this.color,
    this.label,
    this.params = const FxParams(),
    this.size = 100,
    this.pulse = false,
    this.child,
  }) : assert(
         icon != null || child != null,
         'informe `icon` ou `child` como conteúdo do reveal',
       );

  final IconData? icon;
  final Color color;
  final String? label;
  final FxParams params;
  final double size;

  /// Se o ícone fica "respirando" (bom para sequência/chama).
  final bool pulse;

  /// Conteúdo próprio (ex.: troféu desenhado à mão). Se nulo, usa [icon].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final iconWidget = ShineSweep(
      params: params,
      child:
          child ??
          Icon(
            icon,
            size: size,
            color: color,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 22),
            ],
          ),
    );

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RadialRays(color: color, diameter: size * 2.6, params: params),
          // Partículas explodem quando o ícone "pousa" (fim do giro).
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
          GlowHalo(color: color, diameter: size * 2.0, params: params),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spin3D(
                params: params,
                turns: 2,
                fromScale: 0.2,
                child: pulse
                    ? Pulse(params: params, child: iconWidget)
                    : iconWidget,
              ),
              if (label != null) ...[
                const SizedBox(height: 12),
                _label(label!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Rótulo que sobe e aparece depois do pouso do ícone.
  Widget _label(String texto) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: params.effectiveDuration,
    builder: (context, t, child) {
      final op = Interval(0.42, 0.75).transform(t).clamp(0.0, 1.0);
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
