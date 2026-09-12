import '../theme/app_colors.dart';
import 'particles/confetti.dart';
import 'reward_registry.dart';
import 'reward_type.dart';
import 'rewards/chest_open.dart';
import 'rewards/icon_reveal.dart';
import 'rewards/star_burst.dart';
import 'rewards/trophy_3d.dart';
import 'rewards/xp_gain.dart';

/// Liga cada [RewardType] à sua molécula de `fx/rewards/` (ou `particles/`).
/// Chamado uma vez no arranque (`main`) e, defensivamente, ao abrir o
/// Laboratório — idempotente.
///
/// Mapa atual (Fase 4 — todas com efeito real; nenhuma no placeholder):
/// - `star`        → `StarBurst`
/// - `xp`          → `XpGain` (usa `value`)
/// - `chest`       → `ChestOpen` (a mais composta)
/// - `trophy*`     → `IconReveal` (troféu, tom ouro/prata)
/// - `medal*`      → `IconReveal` (medalha, tom ouro/prata)
/// - `levelUp`     → `IconReveal` (usa `value` como nº do nível)
/// - `streak`      → `IconReveal` pulsante (usa `value` como nº de dias)
/// - `confetti`    → `ConfettiRain`
bool _registrado = false;

void registerBuiltInRewards() {
  if (_registrado) return;
  _registrado = true;

  RewardRegistry.register(
    RewardType.star,
    (context, params, {value}) => StarBurst(params: params),
  );
  RewardRegistry.register(
    RewardType.xp,
    (context, params, {value}) => XpGain(params: params, value: value ?? 10),
  );
  RewardRegistry.register(
    RewardType.chest,
    (context, params, {value}) => ChestOpen(params: params),
  );
  RewardRegistry.register(
    RewardType.confetti,
    (context, params, {value}) => ConfettiRain(
      params: params,
      colors: [
        AppColors.estrela,
        AppColors.exec,
        AppColors.prep,
        context.accent,
      ],
    ),
  );

  // Troféus — conteúdo desenhado à mão (copo metálico), ouro e prata.
  for (final t in const [RewardType.trophyGold, RewardType.trophySilver]) {
    RewardRegistry.register(
      t,
      (context, params, {value}) => IconReveal(
        color: t.color(context),
        label: t.label,
        params: params,
        size: 112,
        child: Trophy3D(size: 116, metal: t.color(context)),
      ),
    );
  }

  // Medalhas — reveal com o ícone do Material.
  for (final t in const [RewardType.medalGold, RewardType.medalSilver]) {
    RewardRegistry.register(
      t,
      (context, params, {value}) => IconReveal(
        icon: t.icon,
        color: t.color(context),
        label: t.label,
        params: params,
      ),
    );
  }

  RewardRegistry.register(
    RewardType.levelUp,
    (context, params, {value}) => IconReveal(
      icon: RewardType.levelUp.icon,
      color: RewardType.levelUp.color(context),
      label: value != null ? 'Nível ${value.round()}' : 'Subiu de nível',
      params: params,
    ),
  );
  RewardRegistry.register(
    RewardType.streak,
    (context, params, {value}) => IconReveal(
      icon: RewardType.streak.icon,
      color: RewardType.streak.color(context),
      label: value != null ? '${value.round()} dias' : 'Sequência',
      params: params,
      pulse: true,
    ),
  );
}
