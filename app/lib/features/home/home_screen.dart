import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        backgroundColor: AppColors.exec,
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
          color: selecionado ? AppColors.exec : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hoje && !selecionado ? AppColors.exec : AppColors.line,
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
                    ? (selecionado ? AppColors.onAccent : AppColors.exec)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreinoCard extends ConsumerWidget {
  const _TreinoCard({required this.treino});

  final Treino treino;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = treino.exercicios.length;
    final resumo =
        '$n ${n == 1 ? 'exercício' : 'exercícios'} · ${fmtSeg(treino.duracaoTotalSeg)}';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TreinoEditorScreen(treinoId: treino.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
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
                      style: const TextStyle(color: AppColors.dim, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _BotaoIniciar(
                habilitado: treino.exercicios.isNotEmpty,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(treino: treino),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoIniciar extends StatelessWidget {
  const _BotaoIniciar({required this.habilitado, required this.onTap});

  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: habilitado ? AppColors.exec : AppColors.surface2,
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
