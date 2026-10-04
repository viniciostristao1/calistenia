import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercicio.dart';
import '../../models/treino.dart';
import '../../services/cards_repository.dart';
import '../../services/relogio.dart';
import '../../theme/app_colors.dart';
import '../../util/cards_catalog.dart';
import '../player/player_screen.dart';

String? _ultimoCard; // evita repetir o mesmo card 2× seguidas na sessão

/// Sorteia um card POSSUÍDO p/ o pré-treino, evitando repetir o último.
String? _sortearCard(List<String> possuidos) {
  final cands = possuidos.where((id) => cardPorId(id) != null).toList();
  if (cands.isEmpty) return null;
  var pool = cands.length > 1
      ? cands.where((id) => id != _ultimoCard).toList()
      : cands;
  if (pool.isEmpty) pool = cands;
  final id = pool[Random().nextInt(pool.length)];
  _ultimoCard = id;
  return id;
}

/// Inicia um treino, mostrando ANTES um card motivacional (se for treino inteiro,
/// o toggle estiver ligado e o usuário possuir cards). Depois abre o player e,
/// ao voltar, reemite o relógio da home.
Future<void> iniciarTreinoComCard(
  BuildContext context,
  WidgetRef ref, {
  required String titulo,
  required List<Exercicio> exercicios,
  Treino? treino,
}) async {
  if (treino != null) {
    final ligado = ref.read(cardsPreTreinoProvider).value ?? true;
    final possuidos = ref.read(cardsProvider).value ?? const <String>[];
    if (ligado && possuidos.isNotEmpty) {
      final id = _sortearCard(possuidos);
      if (id != null && context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => _CardPreTreinoDialog(id: id),
        );
      }
    }
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          PlayerScreen(titulo: titulo, exercicios: exercicios, treino: treino),
    ),
  );
  if (context.mounted) ref.invalidate(relogioProvider);
}

/// Mostra um card motivacional (a arte já traz a mensagem) + botão "Começar".
class _CardPreTreinoDialog extends StatelessWidget {
  const _CardPreTreinoDialog({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final card = cardPorId(id)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: (0.8 + 0.2 * t).clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A arte tem ~310×540 px: limitar perto disso evita ampliar (que
            // deixava o card grande e borrado). filterQuality medium suaviza.
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 170,
                  maxHeight: 300,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    card.asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.accent,
                foregroundColor: context.onAccent,
                minimumSize: const Size(220, 52),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Começar treino'),
            ),
          ],
        ),
      ),
    );
  }
}
