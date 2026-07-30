import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/exercicio.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';

/// Abre a folha de edição de um exercício. Retorna o exercício editado
/// (ou `null` se cancelado). Passe `existente` para editar; `null` para criar.
Future<Exercicio?> showExercicioEditor(
  BuildContext context,
  Exercicio? existente,
) {
  return showModalBottomSheet<Exercicio>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ExercicioEditor(existente: existente),
  );
}

class _ExercicioEditor extends StatefulWidget {
  const _ExercicioEditor({required this.existente});

  final Exercicio? existente;

  @override
  State<_ExercicioEditor> createState() => _ExercicioEditorState();
}

class _ExercicioEditorState extends State<_ExercicioEditor> {
  late final TextEditingController _nomeCtrl;
  late int _prep;
  late int _exec;
  late int _desc;
  late int _reps;
  late int _series;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _nomeCtrl = TextEditingController(text: e?.nome ?? '');
    _prep = e?.preparacaoSeg ?? 10;
    _exec = e?.execucaoSeg ?? 3;
    _desc = e?.descansoSeg ?? 60;
    _reps = e?.repeticoes ?? 10;
    _series = e?.series ?? 3;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    final e = (widget.existente ?? Exercicio(nome: ''))
      ..nome = _nomeCtrl.text.trim().isEmpty
          ? 'Exercício'
          : _nomeCtrl.text.trim()
      ..preparacaoSeg = _prep
      ..execucaoSeg = _exec < 1 ? 1 : _exec
      ..descansoSeg = _desc
      ..repeticoes = _reps < 1 ? 1 : _reps
      ..series = _series < 1 ? 1 : _series;
    Navigator.of(context).pop(e);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existente == null ? 'Novo exercício' : 'Editar exercício',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nomeCtrl,
              autofocus: widget.existente == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do exercício',
                hintText: 'Ex.: Flexão, Agachamento, Prancha…',
              ),
            ),
            const SizedBox(height: 20),
            _StepperLinha(
              rotulo: 'Séries',
              cor: AppColors.text,
              valorTexto: '$_series',
              onMenos: () =>
                  setState(() => _series = (_series - 1).clamp(1, 99)),
              onMais: () =>
                  setState(() => _series = (_series + 1).clamp(1, 99)),
              onTapValor: () async {
                final v = await _pedirNumero(context, 'Séries', _series, 1);
                if (v != null) setState(() => _series = v);
              },
            ),
            const SizedBox(height: 6),
            _StepperLinha(
              rotulo: 'Repetições (por série)',
              cor: AppColors.text,
              valorTexto: '$_reps',
              onMenos: () => setState(() => _reps = (_reps - 1).clamp(1, 999)),
              onMais: () => setState(() => _reps = (_reps + 1).clamp(1, 999)),
              onTapValor: () async {
                final v = await _pedirNumero(context, 'Repetições', _reps, 1);
                if (v != null) setState(() => _reps = v);
              },
            ),
            const Divider(height: 24),
            _TempoLinha(
              rotulo: 'Preparação',
              cor: AppColors.prep,
              segundos: _prep,
              removivel: true,
              onChanged: (v) => setState(() => _prep = v),
            ),
            _TempoLinha(
              rotulo: 'Execução (por rep)',
              cor: AppColors.exec,
              segundos: _exec,
              removivel: false,
              minimo: 1,
              passo: 1, // ajuste fino: uma flexão pode durar 2, 3, 4s…
              onChanged: (v) => setState(() => _exec = v),
            ),
            _TempoLinha(
              rotulo: 'Descanso (entre séries)',
              cor: AppColors.rest,
              segundos: _desc,
              removivel: true,
              onChanged: (v) => setState(() => _desc = v),
            ),
            const SizedBox(height: 14),
            _Resumo(
              series: _series,
              reps: _reps,
              execSeg: _exec,
              descSeg: _desc,
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _salvar,
              child: const Text('Salvar exercício'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de um tempo (preparação/execução/descanso), em segundos.
/// Quando `removivel` e o valor é 0, vira um botão "adicionar".
class _TempoLinha extends StatelessWidget {
  const _TempoLinha({
    required this.rotulo,
    required this.cor,
    required this.segundos,
    required this.removivel,
    required this.onChanged,
    this.minimo = 0,
    this.passo = 5,
  });

  final String rotulo;
  final Color cor;
  final int segundos;
  final bool removivel;
  final int minimo;
  final int passo;
  final ValueChanged<int> onChanged;

  /// Primeira palavra do rótulo ("Descanso (entre séries)" -> "descanso").
  String get _rotuloCurto => rotulo.split(' ').first.toLowerCase();

  @override
  Widget build(BuildContext context) {
    if (removivel && segundos <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: cor),
            onPressed: () =>
                onChanged(rotulo.startsWith('Descanso') ? 60 : 10),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Adicionar $_rotuloCurto'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(rotulo,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          _Redondo(
            icon: Icons.remove,
            onTap: () =>
                onChanged((segundos - passo).clamp(minimo, 3600)),
          ),
          GestureDetector(
            onTap: () async {
              final v = await _pedirNumero(
                  context, '$rotulo (segundos)', segundos, minimo);
              if (v != null) onChanged(v.clamp(minimo, 3600));
            },
            child: Container(
              width: 84,
              alignment: Alignment.center,
              child: Text(
                fmtSeg(segundos),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: cor),
              ),
            ),
          ),
          _Redondo(
            icon: Icons.add,
            onTap: () => onChanged((segundos + passo).clamp(minimo, 3600)),
          ),
          SizedBox(
            width: 40,
            child: removivel
                ? IconButton(
                    tooltip: 'Remover $rotulo',
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.dim2),
                    onPressed: () => onChanged(0),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StepperLinha extends StatelessWidget {
  const _StepperLinha({
    required this.rotulo,
    required this.cor,
    required this.valorTexto,
    required this.onMenos,
    required this.onMais,
    required this.onTapValor,
  });

  final String rotulo;
  final Color cor;
  final String valorTexto;
  final VoidCallback onMenos;
  final VoidCallback onMais;
  final VoidCallback onTapValor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(rotulo,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        _Redondo(icon: Icons.remove, onTap: onMenos),
        GestureDetector(
          onTap: onTapValor,
          child: Container(
            width: 84,
            alignment: Alignment.center,
            child: Text(
              valorTexto,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: cor),
            ),
          ),
        ),
        _Redondo(icon: Icons.add, onTap: onMais),
        const SizedBox(width: 40),
      ],
    );
  }
}

/// Resuminho em linguagem natural do que o cronômetro vai fazer.
class _Resumo extends StatelessWidget {
  const _Resumo({
    required this.series,
    required this.reps,
    required this.execSeg,
    required this.descSeg,
  });

  final int series;
  final int reps;
  final int execSeg;
  final int descSeg;

  @override
  Widget build(BuildContext context) {
    final serieTxt = reps > 1
        ? '$reps reps de ${fmtSeg(execSeg)}'
        : 'segure ${fmtSeg(execSeg)}';
    final descTxt = descSeg > 0 ? ' · descanso ${fmtSeg(descSeg)}' : '';
    final vezes = series > 1 ? '$series séries' : '1 série';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: AppColors.dim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$vezes de ($serieTxt)$descTxt',
              style: const TextStyle(color: AppColors.dim, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Redondo extends StatelessWidget {
  const _Redondo({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.text),
        ),
      ),
    );
  }
}

Future<int?> _pedirNumero(
  BuildContext context,
  String titulo,
  int atual,
  int minimo,
) {
  final ctrl = TextEditingController(text: '$atual');
  return showDialog<int>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(titulo),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: 'Digite um número'),
        onSubmitted: (_) => _confirmarNumero(context, ctrl, minimo),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => _confirmarNumero(context, ctrl, minimo),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void _confirmarNumero(
    BuildContext context, TextEditingController ctrl, int minimo) {
  final v = int.tryParse(ctrl.text);
  Navigator.pop(context, v == null ? null : (v < minimo ? minimo : v));
}
