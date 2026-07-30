import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercicio.dart';
import '../../models/treino.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/dias.dart';
import '../../util/format.dart';
import '../player/player_screen.dart';
import '../treino/treino_editor_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _dia = diaDeHoje;

  Future<void> _novoTreino() async {
    final t = Treino(nome: 'Novo treino', dias: [_dia]);
    await ref.read(treinosProvider.notifier).salvar(t);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TreinoEditorScreen(treinoId: t.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(treinosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calistenia')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoTreino,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add),
        label: const Text('Novo treino'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (treinos) {
          final doDia =
              treinos.where((t) => t.dias.contains(_dia)).toList();
          final diasComTreino =
              treinos.expand((t) => t.dias).toSet();
          return Column(
            children: [
              _SeletorDias(
                selecionado: _dia,
                diasComTreino: diasComTreino,
                onSelect: (d) => setState(() => _dia = d),
              ),
              const Divider(height: 1),
              Expanded(
                child: doDia.isEmpty
                    ? _Vazio(dia: _dia)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: doDia.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _TreinoCard(treino: doDia[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SeletorDias extends StatelessWidget {
  const _SeletorDias({
    required this.selecionado,
    required this.diasComTreino,
    required this.onSelect,
  });

  final int selecionado;
  final Set<int> diasComTreino;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          for (var d = 0; d < 7; d++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _DiaPill(
                rotulo: nomesDiasCurtos[d],
                selecionado: d == selecionado,
                hoje: d == diaDeHoje,
                temTreino: diasComTreino.contains(d),
                onTap: () => onSelect(d),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiaPill extends StatelessWidget {
  const _DiaPill({
    required this.rotulo,
    required this.selecionado,
    required this.hoje,
    required this.temTreino,
    required this.onTap,
  });

  final String rotulo;
  final bool selecionado;
  final bool hoje;
  final bool temTreino;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hoje && !selecionado ? AppColors.accent : AppColors.line,
          ),
        ),
        child: Column(
          children: [
            Text(
              rotulo,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selecionado ? AppColors.onAccent : AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: temTreino
                    ? (selecionado ? AppColors.onAccent : AppColors.accent)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreinoCard extends StatelessWidget {
  const _TreinoCard({required this.treino});

  final Treino treino;

  void _abrirEditor(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TreinoEditorScreen(treinoId: treino.id),
        ),
      );

  void _rodar(BuildContext context, String titulo, List<Exercicio> exs) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(titulo: titulo, exercicios: exs),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final n = treino.exercicios.length;
    final resumo =
        '$n ${n == 1 ? 'exercício' : 'exercícios'} · ${fmtSeg(treino.duracaoTotalSeg)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho: toca no texto -> edita; ▶ grande -> roda o treino todo.
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _abrirEditor(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            treino.nome.isEmpty ? 'Sem nome' : treino.nome,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            resumo,
                            style: const TextStyle(
                                color: AppColors.dim, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _PlayCircle(
                  grande: true,
                  habilitado: treino.exercicios.isNotEmpty,
                  onTap: () =>
                      _rodar(context, treino.nome, treino.exercicios),
                ),
              ],
            ),
            // Lista de exercícios: toca em um -> roda só ele.
            if (treino.exercicios.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Divider(height: 1),
              const SizedBox(height: 2),
              for (final e in treino.exercicios)
                _ExercicioLinha(
                  exercicio: e,
                  onRodar: () => _rodar(context, e.nome, [e]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Uma linha de exercício dentro do card do treino, na home. Tocar roda só
/// este exercício (o "executar separadamente").
class _ExercicioLinha extends StatelessWidget {
  const _ExercicioLinha({required this.exercicio, required this.onRodar});

  final Exercicio exercicio;
  final VoidCallback onRodar;

  @override
  Widget build(BuildContext context) {
    final e = exercicio;
    final detalhe = e.repeticoes > 1
        ? '${e.series}×${e.repeticoes} · ${fmtSeg(e.execucaoSeg)}/rep'
        : '${e.series}× ${fmtSeg(e.execucaoSeg)}';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onRodar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.nome.isEmpty ? 'Sem nome' : e.nome,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detalhe,
                    style:
                        const TextStyle(color: AppColors.dim, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PlayCircle(grande: false, habilitado: true, onTap: onRodar),
          ],
        ),
      ),
    );
  }
}

/// Botão redondo de play. `grande` = accent preenchido (treino todo);
/// pequeno/fantasma = por-exercício.
class _PlayCircle extends StatelessWidget {
  const _PlayCircle({
    required this.grande,
    required this.habilitado,
    required this.onTap,
  });

  final bool grande;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (grande) {
      return Material(
        color: habilitado ? AppColors.accent : AppColors.surface2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: habilitado ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 28,
              color: habilitado ? AppColors.onAccent : AppColors.dim2,
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 20,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.dia});

  final int dia;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 56, color: AppColors.dim2),
            const SizedBox(height: 16),
            Text(
              'Nenhum treino em ${nomesDiasLongos[dia]}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Toque em “Novo treino” para criar.',
              style: TextStyle(color: AppColors.dim),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
