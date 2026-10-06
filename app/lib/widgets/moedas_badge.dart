import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/gamificacao_pref.dart';
import '../services/moedas_repository.dart';
import '../services/navegacao.dart';
import '../theme/app_colors.dart';

/// Pílula "🪙 \$N" com o saldo de moedas — mostrada no topo (Home, Check-in,
/// Progressão). Some com a gamificação desligada.
class MoedasBadge extends ConsumerWidget {
  const MoedasBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamiOn = ref.watch(gamificacaoProvider).value ?? true;
    if (!gamiOn) return const SizedBox.shrink();
    final moedas = ref.watch(moedasProvider).value ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 8, left: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          // Tocar leva à coleção de Cards (Progressão › Cards).
          onTap: () {
            progressaoVistaInicial.value = 2;
            abaSolicitada.value = 2;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  '\$$moedas',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
