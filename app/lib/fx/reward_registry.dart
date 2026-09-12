import 'package:flutter/widgets.dart';

import 'fx_params.dart';
import 'reward_type.dart';
import 'rewards/placeholder_reward.dart';

/// Constrói o widget de uma animação a partir dos parâmetros.
typedef RewardEffectBuilder = Widget Function(
    BuildContext context, FxParams params);

/// **A PONTE entre a identidade e a apresentação.**
///
/// Um mapa `RewardType → construtor da animação`. As telas só conhecem
/// [RewardType]; o registry decide qual widget tocar. Substituir a animação de
/// um tipo (ex.: `StarBurst` v1 → v2) é mexer só aqui — **nenhuma tela muda**.
/// É o que garante "trocar a implementação interna sem alterar quem chama".
///
/// Fase 0: todos os tipos apontam para o [PlaceholderReward]. Nas fases
/// seguintes cada tipo é [register]ado com sua molécula de `fx/rewards/`.
class RewardRegistry {
  RewardRegistry._();

  static final Map<RewardType, RewardEffectBuilder> _builders = {
    for (final t in RewardType.values)
      t: (context, params) => PlaceholderReward(type: t, params: params),
  };

  /// O construtor de um tipo (cai no placeholder se ainda não foi registrado).
  static RewardEffectBuilder builderFor(RewardType type) =>
      _builders[type] ??
      (context, params) => PlaceholderReward(type: type, params: params);

  /// Registra/substitui a animação de um tipo. Chamado pelas fases seguintes
  /// (idealmente uma vez, no arranque, por um `registerRewards()`).
  static void register(RewardType type, RewardEffectBuilder builder) =>
      _builders[type] = builder;

  /// Constrói o widget pronto de um tipo.
  static Widget build(BuildContext context, RewardType type, FxParams params) =>
      builderFor(type)(context, params);
}
