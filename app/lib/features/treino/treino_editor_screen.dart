import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercicio.dart';
import '../../models/treino.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/dias.dart';
import '../../util/format.dart';
import '../../util/messenger.dart';
import '../player/player_screen.dart';
import 'exercicio_editor_sheet.dart';

/// Edição de um treino. Salva ao vivo (cada mudança persiste), então nada
/// se perde ao voltar.
class TreinoEditorScreen extends ConsumerStatefulWidget {
  const TreinoEditorScreen({super.key, required this.treinoId});

  final String treinoId;

  @override
  ConsumerState<TreinoEditorScreen> createState() =>
      _TreinoEditorScreenState();
}

class _TreinoEditorScreenState extends ConsumerState<TreinoEditorScreen> {
  late Treino _t;
  late final TextEditingController _nomeCtrl;
  bool _carregado = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
  }

  void _carregar() {
    final lista = ref.read(treinosProvider).value ?? const <Treino>[];
    final achado = lista.where((t) => t.id == widget.treinoId).firstOrNull;
    _t = (achado ?? Treino(nome: 'Novo treino')).copy();
    _nomeCtrl.text = _t.nome;
    _carregado = true;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    await ref.read(treinosProvider.notifier).salvar(_t);
    if (mounted) setState(() {});
  }

  Future<void> _editarExercicio([Exercicio? existente]) async {
    final resultado = await showExercicioEditor(context, existente);
    if (resultado == null) return;
    final i = _t.exercicios.indexWhere((e) => e.id == resultado.id);
    if (i >= 0) {
      _t.exercicios[i] = resultado;
    } else {
      _t.exercicios.add(resultado);
    }
    await _salvar();
  }

  Future<void> _excluirExercicio(Exercicio e) async {
    final idx = _t.exercicios.indexWhere((x) => x.id == e.id);
    if (idx < 0) return;
    _t.exercicios.removeAt(idx);
    await _salvar();
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Exercício excluído'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            _t.exercicios.insert(idx.clamp(0, _t.exercicios.length), e);
            _salvar();
          },
        ),
      ));
  }

  /// Adiciona uma cópia de um exercício já salvo em outro treino.
  Future<void> _adicionarExistente() async {
    final treinos = ref.read(treinosProvider).value ?? const <Treino>[];
    final mapa = <String, Exercicio>{};
    for (final t in treinos) {
      for (final e in t.exercicios) {
        final nome = e.nome.trim();
        if (nome.isNotEmpty) mapa.putIfAbsent(nome.toLowerCase(), () => e);
      }
    }
    final disponiveis = mapa.values.toList();
    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum exercício salvo ainda.')),
      );
      return;
    }
    final escolhido = await showModalBottomSheet<Exercicio>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Exercícios já salvos',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final e in disponiveis)
              ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.corExercicio(e.corIndex),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(e.nome),
                subtitle: Text(e.resumoCurto,
                    style:
                        const TextStyle(color: AppColors.dim, fontSize: 12.5)),
                onTap: () => Navigator.pop(context, e),
              ),
          ],
        ),
      ),
    );
    if (escolhido != null) {
      _t.exercicios.add(escolhido.duplicar());
      await _salvar();
    }
  }

  Future<void> _excluirTreino() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Excluir treino?'),
        content: Text('“${_t.nome}” será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final removido = _t.copy();
    final notifier = ref.read(treinosProvider.notifier);
    final navigator = Navigator.of(context);
    await notifier.remover(_t.id);
    navigator.pop();
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Treino excluído'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => notifier.salvar(removido),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_carregado) _carregar();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar treino'),
        actions: [
          IconButton(
            tooltip: 'Excluir treino',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: _excluirTreino,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: context.accent,
            foregroundColor: context.onAccent,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: _t.exercicios.isEmpty
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        titulo: _t.nome,
                        exercicios: _t.exercicios,
                      ),
                    ),
                  ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar treino'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _nomeCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome do treino',
              hintText: 'Ex.: Peitoral, Pernas…',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            onChanged: (v) {
              _t.nome = v;
              ref.read(treinosProvider.notifier).salvar(_t);
            },
          ),
          const SizedBox(height: 22),
          const Text('Dias da semana',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 0; d < 7; d++)
                FilterChip(
                  label: Text(nomesDiasCurtos[d]),
                  selected: _t.dias.contains(d),
                  showCheckmark: false,
                  backgroundColor: AppColors.surface,
                  selectedColor: context.accent,
                  labelStyle: TextStyle(
                    color: _t.dias.contains(d)
                        ? context.onAccent
                        : AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                  side: const BorderSide(color: AppColors.line),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _t.dias.add(d);
                      } else {
                        _t.dias.remove(d);
                      }
                    });
                    ref.read(treinosProvider.notifier).salvar(_t);
                  },
                ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Text('Exercícios',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                fmtSeg(_t.duracaoTotalSeg),
                style: const TextStyle(color: AppColors.dim),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_t.exercicios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Nenhum exercício ainda. Adicione o primeiro abaixo.',
                style: TextStyle(color: AppColors.dim),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _t.exercicios.length,
              onReorderItem: (oldI, newI) {
                setState(() {
                  final item = _t.exercicios.removeAt(oldI);
                  _t.exercicios.insert(newI, item);
                });
                ref.read(treinosProvider.notifier).salvar(_t);
              },
              itemBuilder: (context, i) {
                final e = _t.exercicios[i];
                return _ExercicioRow(
                  key: ValueKey(e.id),
                  index: i,
                  exercicio: e,
                  onTap: () => _editarExercicio(e),
                  onDelete: () => _excluirExercicio(e),
                );
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.accent,
              side: BorderSide(color: context.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _editarExercicio(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar exercício'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.dim,
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: _adicionarExistente,
            icon: const Icon(Icons.playlist_add, size: 20),
            label: const Text('Adicionar de exercícios já salvos'),
          ),
        ],
      ),
    );
  }
}

class _ExercicioRow extends StatelessWidget {
  const _ExercicioRow({
    super.key,
    required this.index,
    required this.exercicio,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final Exercicio exercicio;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final e = exercicio;
    final partes = <String>[
      if (e.preparacaoSeg > 0) 'Prep ${fmtSeg(e.preparacaoSeg)}',
      e.resumoCurto,
    ];
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 12, right: 4),
          onTap: onTap,
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator, color: AppColors.dim2),
          ),
          title: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.corExercicio(e.corIndex),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  e.nome.isEmpty ? 'Sem nome' : e.nome,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          subtitle: Text(
            partes.join(' · '),
            style: const TextStyle(color: AppColors.dim, fontSize: 12.5),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: AppColors.dim2, size: 20),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}
