import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../fx_params.dart';
import '../reward_type.dart';

/// **Placeholder da Fase 0.** Um pop-in genérico (escala + fade com overshoot)
/// do ícone do tipo, só para provar o encanamento fim-a-fim
/// (FxParams → Registry → Overlay/Lab) *sem* nenhum efeito real.
///
/// Cada [RewardType] ganhará sua própria animação em `fx/rewards/` na Fase 4;
/// quando isso acontecer, o [RewardRegistry] passa a apontar para elas e este
/// arquivo pode ser removido. Ele já respeita `speed`, `scale` e `duration` do
/// [FxParams] pra o Laboratório mostrar os sliders funcionando.
class PlaceholderReward extends StatelessWidget {
  const PlaceholderReward({
    super.key,
    required this.type,
    this.params = const FxParams(),
  });

  final RewardType type;
  final FxParams params;

  @override
  Widget build(BuildContext context) {
    final cor = type.color(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: params.effectiveDuration,
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: (0.3 + 0.7 * t).clamp(0.0, 2.0) * params.scale,
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cor.withValues(alpha: 0.14),
              border: Border.all(color: cor, width: 1.5),
            ),
            child: Icon(type.icon, size: 64, color: cor),
          ),
          const SizedBox(height: 10),
          Text(
            type.label,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'placeholder — efeito real vem na Fase 4',
            style: TextStyle(color: AppColors.dim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
