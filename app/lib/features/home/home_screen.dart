import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercicio.dart';
import '../../models/treino.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/dias.dart';
import '../../util/exportar_treino.dart';
import '../../util/format.dart';
import '../config/config_screen.dart';
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
    final t = Treino(nome: '', dias: [_dia]);
    await ref.read(treinosProvider.notifier).salvar(t);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TreinoEditorScreen(treinoId: t.id)),
    );
  }

  void _abrirConfig() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConfigScreen()),
      );

  void _compartilharDia() {
    final treinos = (ref.read(treinosProvider).value ?? const <Treino>[])
        .where((t) => t.dias.contains(_dia))
        .toList();
    if (treinos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum treino neste dia para compartilhar.')),
      );
      return;
    }
    final texto = treinosParaTexto(treinos);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Compartilhar treino'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              texto,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: context.accent,
              foregroundColor: context.onAccent,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: texto));
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Treino copiado!')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sair() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sair do app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(treinosProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 26),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('Calis Timer', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _abrirConfig,
          ),
          IconButton(
            tooltip: 'Compartilhar treino',
            icon: const Icon(Icons.share_outlined),
            onPressed: _compartilharDia,
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _sair,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoTreino,
        backgroundColor: context.accent,
        foregroundColor: context.onAccent,
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
    // Todos os 7 dias cabem na largura (cada um em um Expanded), sem scroll.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Row(
        children: [
          for (var d = 0; d < 7; d++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _DiaPill(
                  rotulo: nomesDiasCurtos[d],
                  selecionado: d == selecionado,
                  hoje: d == diaDeHoje,
                  temTreino: diasComTreino.contains(d),
                  onTap: () => onSelect(d),
                ),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? context.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hoje && !selecionado ? context.accent : AppColors.line,
          ),
        ),
        child: Column(
          children: [
            Text(
              rotulo,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selecionado ? context.onAccent : AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: temTreino
                    ? (selecionado ? context.onAccent : context.accent)
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
    final dur = treino.duracaoTotalSeg;
    final base = '$n ${n == 1 ? 'exercício' : 'exercícios'} · ${fmtSeg(dur)}';
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "6 pontinhos": pista de que o título abre a edição.
                          const Padding(
                            padding: EdgeInsets.only(top: 2, right: 6),
                            child: Icon(Icons.drag_indicator,
                                size: 20, color: AppColors.dim2),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  treino.nome.isEmpty
                                      ? 'Novo treino'
                                      : treino.nome,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    // nome vazio = sugestão neutra (cor fraca)
                                    color: treino.nome.isEmpty
                                        ? AppColors.dim
                                        : AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                        color: AppColors.dim, fontSize: 13),
                                    children: [
                                      TextSpan(text: base),
                                      if (dur > 0) ...[
                                        const TextSpan(text: '   '),
                                        const WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Icon(Icons.access_time,
                                              size: 13, color: AppColors.dim),
                                        ),
                                        TextSpan(
                                          text:
                                              ' ~${fmtHora(DateTime.now().add(Duration(seconds: dur)))}',
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
    final detalhe = e.resumoCurto;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onRodar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.corExercicio(e.corIndex),
                shape: BoxShape.circle,
              ),
            ),
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
        color: habilitado ? context.accent : AppColors.surface2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: habilitado ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 28,
              color: habilitado ? context.onAccent : AppColors.dim2,
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
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 20,
            color: context.accent,
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
