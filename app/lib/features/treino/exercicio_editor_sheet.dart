import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercicio.dart';
import '../../models/registro_progressao.dart';
import '../../services/progressao_repository.dart';
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

class _ExercicioEditor extends ConsumerStatefulWidget {
  const _ExercicioEditor({required this.existente});

  final Exercicio? existente;

  @override
  ConsumerState<_ExercicioEditor> createState() => _ExercicioEditorState();
}

class _ExercicioEditorState extends ConsumerState<_ExercicioEditor> {
  late final TextEditingController _nomeCtrl;
  late int _prep;
  late int _exec;
  late int _desc;
  late int _reps;
  late int _series;
  List<int>? _descansos; // descanso por série; null = descanso único (_desc)
  late double _peso;
  late int _cor;

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
    _descansos = e?.descansos == null ? null : List<int>.of(e!.descansos!);
    _peso = e?.pesoKg ?? 0;
    _cor = e?.corIndex ?? 0;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  /// Mantém a lista de descansos por série do tamanho de `_series` (preenche
  /// novos com o descanso padrão, corta os que sobram).
  void _ajustarDescansos() {
    final d = _descansos;
    if (d == null) return;
    if (d.length < _series) {
      d.addAll(List<int>.filled(_series - d.length, _desc));
    } else if (d.length > _series) {
      d.removeRange(_series, d.length);
    }
  }

  void _mudarSeries(int novo) {
    setState(() {
      _series = novo.clamp(1, 99);
      _ajustarDescansos();
    });
  }

  void _salvar() {
    if (_descansos != null) _ajustarDescansos();
    final e = (widget.existente ?? Exercicio(nome: ''))
      ..nome = _nomeCtrl.text.trim().isEmpty
          ? 'Exercício'
          : _nomeCtrl.text.trim()
      ..preparacaoSeg = _prep
      ..execucaoSeg = _exec < 0 ? 0 : _exec // 0 = execução ausente (removida)
      ..descansoSeg = _desc
      ..repeticoes = _reps < 1 ? 1 : _reps
      ..series = _series < 1 ? 1 : _series
      ..descansos = _descansos == null ? null : List<int>.of(_descansos!)
      ..pesoKg = _peso < 0 ? 0 : _peso
      ..corIndex = _cor;
    Navigator.of(context).pop(e);
  }

  String get _nomeExercicio {
    final n = _nomeCtrl.text.trim();
    return n.isEmpty ? 'Exercício' : n;
  }

  /// Registra na Progressão quantas repetições a pessoa fez hoje. Sugere o
  /// número de repetições atual, mas deixa editar (é o desempenho real).
  Future<void> _adicionarProgressao() async {
    final valor = await _pedirNumero(
      context,
      'Quantas você fez? ($_nomeExercicio)',
      _reps,
      0,
    );
    if (valor == null) return;
    await ref.read(progressaoProvider.notifier).adicionar(
          RegistroProgressao(exercicio: _nomeExercicio, valor: valor),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Adicionado à progressão: $valor reps')),
    );
  }

  /// A seção de descanso: um descanso único (padrão) OU um por série.
  List<Widget> _descansoSection() {
    final d = _descansos;
    if (d == null) {
      return [
        _TempoLinha(
          rotulo: 'Descanso (entre séries)',
          cor: AppColors.rest,
          segundos: _desc,
          removivel: true,
          onChanged: (v) => setState(() => _desc = v),
        ),
        if (_series > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.rest),
              onPressed: () =>
                  setState(() => _descansos = List<int>.filled(_series, _desc)),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Descanso diferente por série'),
            ),
          ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration:
                  const BoxDecoration(color: AppColors.rest, shape: BoxShape.circle),
            ),
            const Expanded(
              child: Text('Descanso por série',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => setState(() => _descansos = null),
              child: const Text('Um só'),
            ),
          ],
        ),
      ),
      for (var s = 0; s < d.length; s++)
        _TempoLinha(
          rotulo: 'Após série ${s + 1}',
          cor: AppColors.rest,
          segundos: d[s],
          removivel: false,
          minimo: 0,
          onChanged: (v) => setState(() => d[s] = v),
        ),
    ];
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
              onMenos: () => _mudarSeries(_series - 1),
              onMais: () => _mudarSeries(_series + 1),
              onTapValor: () async {
                final v = await _pedirNumero(context, 'Séries', _series, 1);
                if (v != null) _mudarSeries(v);
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
              removivel: true, // agora pode não ter execução (igual preparação)
              minimo: 0,
              passo: 1, // ajuste fino: uma flexão pode durar 2, 3, 4s…
              onChanged: (v) => setState(() => _exec = v),
            ),
            ..._descansoSection(),
            _PesoLinha(
              peso: _peso,
              onChanged: (v) => setState(() => _peso = v),
              onDigitar: () async {
                final v = await _pedirPeso(context, _peso);
                if (v != null) setState(() => _peso = v);
              },
            ),
            const Divider(height: 24),
            _SeletorCor(
              selecionado: _cor,
              onSelect: (i) => setState(() => _cor = i),
            ),
            const SizedBox(height: 14),
            _Resumo(
              series: _series,
              reps: _reps,
              execSeg: _exec,
              descSeg: _desc,
              descansos: _descansos,
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.accent,
                foregroundColor: context.onAccent,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _salvar,
              child: const Text('Salvar exercício'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.accent,
                side: const BorderSide(color: AppColors.line),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _adicionarProgressao,
              icon: const Icon(Icons.trending_up, size: 20),
              label: const Text('Adicionar à progressão'),
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

  /// Valor sugerido ao (re)adicionar a etapa, por tipo.
  int get _defaultAdd {
    if (rotulo.startsWith('Descanso')) return 60;
    if (rotulo.startsWith('Execução')) return 3;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    if (removivel && segundos <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: cor),
            onPressed: () => onChanged(_defaultAdd),
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
              width: 52,
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
            width: 52,
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
    required this.descansos,
  });

  final int series;
  final int reps;
  final int execSeg;
  final int descSeg;
  final List<int>? descansos;

  String get _serieTxt {
    if (execSeg <= 0) return 'sem execução';
    return reps > 1 ? '$reps reps de ${fmtSeg(execSeg)}' : 'segure ${fmtSeg(execSeg)}';
  }

  String get _descTxt {
    final lista = descansos;
    if (lista != null && lista.isNotEmpty) {
      var mn = 1 << 30, mx = 0, ativos = 0;
      for (final d in lista) {
        if (d > 0) {
          ativos++;
          if (d < mn) mn = d;
          if (d > mx) mx = d;
        }
      }
      if (ativos == 0) return '';
      return mn == mx
          ? ' · descanso ${fmtSeg(mn)}'
          : ' · descanso ${fmtSeg(mn)}–${fmtSeg(mx)}';
    }
    return descSeg > 0 ? ' · descanso ${fmtSeg(descSeg)}' : '';
  }

  @override
  Widget build(BuildContext context) {
    final serieTxt = _serieTxt;
    final descTxt = _descTxt;
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

/// Linha de peso (kg). Quando 0, vira um botão "Adicionar peso".
class _PesoLinha extends StatelessWidget {
  const _PesoLinha({
    required this.peso,
    required this.onChanged,
    required this.onDigitar,
  });

  final double peso;
  final ValueChanged<double> onChanged;
  final VoidCallback onDigitar;

  @override
  Widget build(BuildContext context) {
    if (peso <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.text),
            onPressed: () => onChanged(5),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar peso'),
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
            decoration: const BoxDecoration(
                color: AppColors.dim2, shape: BoxShape.circle),
          ),
          const Expanded(
            child: Text('Peso',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          _Redondo(
            icon: Icons.remove,
            onTap: () => onChanged((peso - 2.5).clamp(0, 999)),
          ),
          GestureDetector(
            onTap: onDigitar,
            child: Container(
              width: 52,
              alignment: Alignment.center,
              child: Text(
                fmtPeso(peso),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
            ),
          ),
          _Redondo(
            icon: Icons.add,
            onTap: () => onChanged((peso + 2.5).clamp(0, 999)),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              tooltip: 'Remover peso',
              icon: const Icon(Icons.close, size: 18, color: AppColors.dim2),
              onPressed: () => onChanged(0),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seletor de cor (marca do exercício): 10 bolinhas.
class _SeletorCor extends StatelessWidget {
  const _SeletorCor({required this.selecionado, required this.onSelect});

  final int selecionado;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cor do exercício',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < AppColors.paletaExercicio.length; i++)
              GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.corExercicio(i),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i == selecionado
                          ? AppColors.text
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: i == selecionado
                      ? const Icon(Icons.check,
                          size: 18, color: Color(0xFF06111F))
                      : null,
                ),
              ),
          ],
        ),
      ],
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

Future<double?> _pedirPeso(BuildContext context, double atual) {
  final txt = atual <= 0
      ? ''
      : (atual == atual.roundToDouble()
          ? atual.toInt().toString()
          : atual.toString().replaceAll('.', ','));
  final ctrl = TextEditingController(text: txt);
  return showDialog<double>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Peso (kg)'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: const InputDecoration(hintText: 'Ex.: 10 ou 2,5'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
            Navigator.pop(context, v == null || v < 0 ? null : v);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
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
