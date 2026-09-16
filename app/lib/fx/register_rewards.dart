import 'reward_registry.dart';
import 'reward_type.dart';
import 'rewards/chest_open2.dart';
import 'rewards/level_up_reveal.dart';

/// Liga cada [RewardType] à sua molécula de `fx/rewards/`. Chamado uma vez no
/// arranque (`main`) e, defensivamente, ao abrir o Laboratório — idempotente.
///
/// Mapa atual (v0.82.0 — só o que o app usa):
/// - `chestEstrela`   → `ChestOpen2` (a estrela sai de dentro do baú)
/// - `chestConquista` → `ChestOpen2(medalha)` (medalha/troféu dourado)
/// - `chestSequencia` → `ChestOpen2(chama)` (o marco de 10 em 10 dias)
/// - `levelUp`        → `LevelUpReveal` (dias comuns: setas + Rating)
bool _registrado = false;

void registerBuiltInRewards() {
  if (_registrado) return;
  _registrado = true;

  // Baú da ESTRELA (o mais completo: estrela sobe + pills de pontos).
  RewardRegistry.register(
    RewardType.chestEstrela,
    (context, params, {value}) => ChestOpen2(params: params, valor: value),
  );
  // Baú da CONQUISTA: abre no toque e a medalha/troféu **sai de dentro** dele,
  // com o nome do prêmio embaixo (no Lab, a dourada).
  RewardRegistry.register(
    RewardType.chestConquista,
    (context, params, {value}) => ChestOpen2(
      params: params,
      item: ChestItem.medalha,
      itemCor: RewardType.chestConquista.color(context),
      label: 'Medalha de Ouro',
    ),
  );
  // Baú da SEQUÊNCIA: a chama **sai de dentro** do baú, com os dias embaixo.
  RewardRegistry.register(
    RewardType.chestSequencia,
    (context, params, {value}) => ChestOpen2(
      params: params,
      item: ChestItem.chama,
      itemCor: RewardType.chestSequencia.color(context),
      valor: value,
      label: value != null ? '${value.round()} dias' : 'Sequência',
    ),
  );
  // Subiu de nível = setas subindo em ciclo + a pontuação (dias comuns).
  RewardRegistry.register(
    RewardType.levelUp,
    (context, params, {value}) => LevelUpReveal(
      params: params,
      color: RewardType.levelUp.color(context),
      value: value ?? 1,
    ),
  );
}
