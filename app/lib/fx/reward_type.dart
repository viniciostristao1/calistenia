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
///
/// Depois da limpeza da v0.82.0 ficaram só os tipos que o app usa de verdade:
/// os **baús** (estrela, conquista, sequência) e o **subiu de nível** (dias
/// comuns). Tudo o que era protótipo mora no histórico do Git.
enum RewardType { chestEstrela, chestConquista, chestSequencia, levelUp }

/// Ouro das conquistas (mesmo tom de `util/conquista_badge.dart`).
const _ouro = Color(0xFFF4C542);

/// Metadados de apresentação de cada tipo: rótulo, ícone e cor.
extension RewardTypeInfo on RewardType {
  /// Rótulo curto exibido no Laboratório.
  String get label => switch (this) {
    RewardType.chestEstrela => 'Baú da estrela',
    RewardType.chestConquista => 'Baú da conquista',
    RewardType.chestSequencia => 'Baú da sequência',
    RewardType.levelUp => 'Subiu de nível',
  };

  IconData get icon => switch (this) {
    RewardType.chestEstrela => Icons.inventory_2_rounded,
    RewardType.chestConquista => Icons.workspace_premium_rounded,
    RewardType.chestSequencia => Icons.whatshot_rounded,
    RewardType.levelUp => Icons.arrow_circle_up_rounded,
  };

  /// Baús que **esperam um toque** para abrir (o 1º toque não dispensa).
  bool get abreComToque => this != RewardType.levelUp;

  /// Cor-tema do efeito. Lê a paleta ATUAL (nunca `const` com [AppColors]: os
  /// temas trocam em runtime — ver a nota no `ANIMACOES.md`).
  Color color(BuildContext context) => switch (this) {
    RewardType.chestConquista => _ouro,
    RewardType.chestSequencia => AppColors.exec,
    RewardType.chestEstrela || RewardType.levelUp => context.accent,
  };
}
