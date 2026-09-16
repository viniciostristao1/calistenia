import 'package:flutter/widgets.dart';

import 'fx_params.dart';
import 'reward_type.dart';

/// Constrói o widget de uma animação a partir dos parâmetros. [value] é opcional
/// e serve aos efeitos que exibem um número (ex.: "+50 XP").
typedef RewardEffectBuilder =
    Widget Function(BuildContext context, FxParams params, {num? value});

/// **A PONTE entre a identidade e a apresentação.**
///
/// Um mapa `RewardType → construtor da animação`. As telas só conhecem
/// [RewardType]; o registry decide qual widget tocar. Substituir a animação de
/// um tipo (ex.: um baú v1 → v2) é mexer só aqui — **nenhuma tela muda**.
/// É o que garante "trocar a implementação interna sem alterar quem chama".
///
/// Um tipo sem animação registrada devolve um `SizedBox` vazio (nunca
/// explode). O registro das animações fica em `register_rewards.dart`
/// (`registerBuiltInRewards`).
class RewardRegistry {
  RewardRegistry._();

  static final Map<RewardType, RewardEffectBuilder> _builders = {};

  /// O construtor de um tipo (vazio se ainda não foi registrado).
  static RewardEffectBuilder builderFor(RewardType type) =>
      _builders[type] ?? (context, params, {value}) => const SizedBox.shrink();

  /// Registra/substitui a animação de um tipo.
  static void register(RewardType type, RewardEffectBuilder builder) =>
      _builders[type] = builder;

  /// Constrói o widget pronto de um tipo.
  static Widget build(
    BuildContext context,
    RewardType type,
    FxParams params, {
    num? value,
  }) => builderFor(type)(context, params, value: value);
}
