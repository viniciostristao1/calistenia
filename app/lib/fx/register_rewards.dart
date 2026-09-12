import 'reward_registry.dart';
import 'reward_type.dart';
import 'rewards/star_burst.dart';
import 'rewards/xp_gain.dart';

/// Liga cada [RewardType] à sua molécula de `fx/rewards/`. Chamado uma vez no
/// arranque (`main`) e, defensivamente, ao abrir o Laboratório — idempotente.
///
/// Os tipos ainda não listados aqui continuam mostrando o placeholder até
/// ganharem sua animação (ver fases em `ANIMACOES.md`).
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
}
