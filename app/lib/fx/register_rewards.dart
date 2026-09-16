import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'particles/confetti.dart';
import 'reward_registry.dart';
import 'reward_type.dart';
import 'rewards/chest_open.dart';
import 'rewards/chest_open2.dart';
import 'rewards/chest_open3.dart';
import 'rewards/flame_reveal.dart';
import 'rewards/icon_reveal.dart';
import 'rewards/level_up_reveal.dart';
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
/// - `chest3`      → `ChestOpen3` (pontuação + 3 setas subindo)
/// - `chestIntro`  → `ChestOpen2(rapido)` (intro: abre só um pouco, no toque)
/// - `chestConquista` → `ChestOpen2(medalha)` (a medalha sai de dentro)
/// - `chestSequencia` → `ChestOpen2(chama)` (a chama sai de dentro)
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
    RewardType.chest2,
    (context, params, {value}) =>
        ChestOpen2(params: params, valor: value),
  );
  // Baú 3: sobe a PONTUAÇÃO com as 3 setas animadas (sem estrela).
  RewardRegistry.register(
    RewardType.chest3,
    (context, params, {value}) => ChestOpen3(params: params, valorScore: value),
  );
  // Baú rápido: o MESMO baú 3/4, mas só a intro (fechado → toque → abre pouco).
  RewardRegistry.register(
    RewardType.chestIntro,
    (context, params, {value}) => ChestOpen2(params: params, rapido: true),
  );
  // Baú de CONQUISTA: abre no toque e a medalha/troféu **sai de dentro**
  // dele, com o nome do prêmio embaixo (no Lab, a dourada).
  RewardRegistry.register(
    RewardType.chestConquista,
    (context, params, {value}) => ChestOpen2(
      params: params,
      item: ChestItem.medalha,
      itemCor: RewardType.medalGold.color(context),
      label: RewardType.medalGold.label,
    ),
  );
  // Baú de SEQUÊNCIA: a chama **sai de dentro** do baú, com os dias embaixo.
  RewardRegistry.register(
    RewardType.chestSequencia,
    (context, params, {value}) => ChestOpen2(
      params: params,
      item: ChestItem.chama,
      itemCor: RewardType.streak.color(context),
      valor: value,
      label: value != null ? '${value.round()} dias' : 'Sequência',
    ),
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

  // Medalhas — MESMO desenho do app (os emojis 🥇 nº 1 / 🥈 nº 2, como na
  // galeria de conquistas do Check-in), agora em tamanho de reveal.
  for (final t in const [RewardType.medalGold, RewardType.medalSilver]) {
    RewardRegistry.register(
      t,
      (context, params, {value}) => IconReveal(
        color: t.color(context),
        label: t.label,
        params: params,
        size: 104,
        child: Text(
          t == RewardType.medalGold ? '🥇' : '🥈',
          style: const TextStyle(fontSize: 100),
        ),
      ),
    );
  }

  // Subiu de nível = setas subindo em ciclo + a pontuação (quantos níveis).
  RewardRegistry.register(
    RewardType.levelUp,
    (context, params, {value}) => LevelUpReveal(
      params: params,
      color: RewardType.levelUp.color(context),
      value: value ?? 1,
    ),
  );
  // Sequência = chama desenhada à mão, com as pontas balançando.
  RewardRegistry.register(
    RewardType.streak,
    (context, params, {value}) => FlameReveal(
      params: params,
      color: RewardType.streak.color(context),
      label: value != null ? '${value.round()} dias' : 'Sequência',
    ),
  );
}
