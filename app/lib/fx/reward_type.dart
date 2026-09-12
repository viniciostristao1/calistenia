import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// **A IDENTIDADE de uma recompensa — o "QUÊ", nunca o "como".**
///
/// Uma [RewardType] diz *qual* recompensa está sendo celebrada; ela NÃO sabe
/// desenhar nada. A apresentação (a animação) mora em `fx/rewards/` e é ligada
/// ao tipo pelo [RewardRegistry]. Assim dá pra trocar a animação de uma
/// recompensa sem tocar em nenhuma tela — o requisito central desta camada.
///
/// ⚠️ Isto é a camada de APRESENTAÇÃO. A lógica de recompensa (regras de
/// sequência, sorteio de insígnias) continua em `util/gamificacao.dart` e
/// `util/insignias.dart`, e o estado em `services/*_repository.dart`. Um
/// [RewardType] pode espelhar um `TipoConquista` do domínio, mas são coisas
/// diferentes de propósito: domínio ≠ visual.
enum RewardType {
  star,
  chest,
  trophyGold,
  trophySilver,
  medalGold,
  medalSilver,
  xp,
  levelUp,
  streak,
  confetti,
}

/// Ouro/prata das conquistas (mesmos tons de `util/conquista_badge.dart`).
const _ouro = Color(0xFFF4C542);
const _prata = Color(0xFFC0C7D2);

/// Metadados de apresentação de cada tipo: rótulo, ícone e cor. Compartilhados
/// pelo placeholder (Fase 0) e pelas animações reais (Fase 4), pra manter a
/// linguagem visual consistente.
extension RewardTypeInfo on RewardType {
  /// Rótulo curto exibido no Laboratório.
  String get label => switch (this) {
        RewardType.star => 'Estrela',
        RewardType.chest => 'Baú',
        RewardType.trophyGold => 'Troféu de Ouro',
        RewardType.trophySilver => 'Troféu de Prata',
        RewardType.medalGold => 'Medalha de Ouro',
        RewardType.medalSilver => 'Medalha de Prata',
        RewardType.xp => '+XP',
        RewardType.levelUp => 'Subiu de nível',
        RewardType.streak => 'Sequência',
        RewardType.confetti => 'Confete',
      };

  IconData get icon => switch (this) {
        RewardType.star => Icons.star_rounded,
        RewardType.chest => Icons.card_giftcard_rounded,
        RewardType.trophyGold || RewardType.trophySilver =>
          Icons.emoji_events_rounded,
        RewardType.medalGold || RewardType.medalSilver =>
          Icons.military_tech_rounded,
        RewardType.xp => Icons.bolt_rounded,
        RewardType.levelUp => Icons.arrow_circle_up_rounded,
        RewardType.streak => Icons.local_fire_department_rounded,
        RewardType.confetti => Icons.celebration_rounded,
      };

  /// Cor-tema do efeito. Lê a paleta ATUAL (nunca `const` com [AppColors]: os
  /// temas trocam em runtime — ver a nota no `ANIMACOES.md`).
  Color color(BuildContext context) => switch (this) {
        RewardType.star || RewardType.xp => AppColors.estrela,
        RewardType.trophyGold || RewardType.medalGold => _ouro,
        RewardType.trophySilver || RewardType.medalSilver => _prata,
        RewardType.streak => AppColors.exec,
        RewardType.chest ||
        RewardType.levelUp ||
        RewardType.confetti =>
          context.accent,
      };
}
