import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registro_progressao.dart';
import '../../services/progressao_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';

/// Aba "Progressão": para cada exercício com registros, mostra a evolução das
/// repetições em um gráfico de barras (uma barra por data).
class ProgressaoScreen extends ConsumerWidget {
  const ProgressaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(progressaoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progressão')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (registros) {
          if (registros.isEmpty) return const _Vazio();
          final grupos = agruparPorExercicio(registros);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: grupos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ExercicioProgressoCard(grupo: grupos[i]),
          );
        },
      ),
    );
  }
}

class _ExercicioProgressoCard extends ConsumerWidget {
  const _ExercicioProgressoCard({required this.grupo});

  final GrupoProgressao grupo;

  Future<void> _confirmarRemoverRegistro(
    BuildContext context,
    WidgetRef ref,
    RegistroProgressao r,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remover este registro?'),
        content: Text('${fmtDataAno(r.data)} · ${r.valor} reps'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Remover', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(progressaoProvider.notifier).remover(r.id);
  }

  Future<void> _confirmarLimpar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Limpar progressão?'),
        content: Text('Remove todos os registros de “${grupo.exercicio}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Limpar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(progressaoProvider.notifier).removerExercicio(grupo.exercicio);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = grupo.ultimo - grupo.primeiro;
    final resumo = grupo.registros.length == 1
        ? '${grupo.ultimo} reps'
        : 'de ${grupo.primeiro} → ${grupo.ultimo} reps';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grupo.exercicio.isEmpty ? 'Sem nome' : grupo.exercicio,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(resumo,
                              style: const TextStyle(
                                  color: AppColors.dim, fontSize: 12.5)),
                          if (delta != 0) ...[
                            const SizedBox(width: 6),
                            _DeltaChip(delta: delta),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Limpar progressão',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.dim2),
                  onPressed: () => _confirmarLimpar(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _GraficoBarras(
              registros: grupo.registros,
              onTapBarra: (r) => _confirmarRemoverRegistro(context, ref, r),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final sobe = delta > 0;
    final cor = sobe ? AppColors.exec : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${sobe ? '+' : ''}$delta',
        style: TextStyle(color: cor, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Gráfico de barras horizontal (uma barra por registro). Rola na horizontal
/// quando há muitos pontos. Tocar numa barra chama [onTapBarra].
class _GraficoBarras extends StatelessWidget {
  const _GraficoBarras({required this.registros, required this.onTapBarra});

  final List<RegistroProgressao> registros;
  final ValueChanged<RegistroProgressao> onTapBarra;

  // Trilho de altura fixa: as bases das barras ficam TODAS na mesma linha
  // (embaixo); só a altura muda com o valor. Espaço reservado no topo p/ o número.
  static const double _trilho = 70;
  static const double _reservaValor = 18;

  @override
  Widget build(BuildContext context) {
    final maxV = registros
        .map((r) => r.valor)
        .fold<int>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: _trilho + 30,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < registros.length; i++)
              _Barra(
                registro: registros[i],
                fracao: registros[i].valor / maxV,
                trilho: _trilho,
                alturaMaxBarra: _trilho - _reservaValor,
                destaque: i == registros.length - 1,
                onTap: () => onTapBarra(registros[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.registro,
    required this.fracao,
    required this.trilho,
    required this.alturaMaxBarra,
    required this.destaque,
    required this.onTap,
  });

  final RegistroProgressao registro;
  final double fracao;
  final double trilho;
  final double alturaMaxBarra;
  final bool destaque; // último registro em destaque
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = (alturaMaxBarra * fracao).clamp(6.0, alturaMaxBarra);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trilho fixo com o conteúdo colado embaixo -> base alinhada.
            SizedBox(
              height: trilho,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${registro.valor}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: destaque ? AppColors.accent : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 28,
                    height: h,
                    decoration: BoxDecoration(
                      color: destaque
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.45),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fmtDataCurta(registro.data),
              style: const TextStyle(color: AppColors.dim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, size: 56, color: AppColors.dim2),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma progressão ainda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ao editar um exercício, toque em '
              '“Adicionar à progressão” para registrar quantas repetições '
              'você fez. A evolução aparece aqui em barras.',
              style: TextStyle(color: AppColors.dim),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
