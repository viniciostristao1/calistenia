import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medida.dart';
import '../services/idioma_repository.dart';
import '../services/medidas_repository.dart';
import '../services/tema_repository.dart';
import '../theme/app_colors.dart';
import '../l10n/strings.dart';

/// Botão das MEDIDAS do corpo p/ a AppBar do Check-in — fica à ESQUERDA do
/// bloco de notas (pedido do usuário). Abre a folha [_MedidasSheet].
class MedidasButton extends ConsumerWidget {
  const MedidasButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(temaProvider);
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    final qtd = ref.watch(medidasProvider).value?.length ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: s.medidas,
          icon: const Icon(Icons.monitor_weight_outlined),
          onPressed: () => abrirMedidas(context),
        ),
        if (qtd > 0)
          Positioned(
            right: 4,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: context.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$qtd',
                  style: TextStyle(
                    color: context.onAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Abre a folha de medidas do corpo (modal).
Future<void> abrirMedidas(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: AppColors.bg,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (_) => const _MedidasSheet(),
);

String _duas(int n) => n.toString().padLeft(2, '0');
String _fmtData(DateTime d) => '${_duas(d.day)}/${_duas(d.month)}/${d.year}';
String _fmtDataCurta(DateTime d) => '${_duas(d.day)}/${_duas(d.month)}';

/// Número "limpo": sem casa decimal quando é inteiro (72, não 72.0); senão 1
/// casa (72.5). Vírgula como separador (padrão pt).
String _fmtNum(double v) {
  final s = (v == v.roundToDouble())
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1);
  return s.replaceAll('.', ',');
}

String _rotuloMetrica(Strings s, MetricaCorporal m) => switch (m) {
  MetricaCorporal.peso => s.peso,
  MetricaCorporal.cintura => s.cintura,
  MetricaCorporal.braco => s.braco,
  MetricaCorporal.peito => s.peito,
  MetricaCorporal.coxa => s.coxa,
};

/// Folha de MEDIDAS: seletor de métrica + gráfico de aumento/diminuição +
/// resumo da tendência + lista de medições + botão "Nova medição".
class _MedidasSheet extends ConsumerStatefulWidget {
  const _MedidasSheet();

  @override
  ConsumerState<_MedidasSheet> createState() => _MedidasSheetState();
}

class _MedidasSheetState extends ConsumerState<_MedidasSheet> {
  MetricaCorporal _metrica = MetricaCorporal.peso;

  @override
  Widget build(BuildContext context) {
    ref.watch(temaProvider);
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    final async = ref.watch(medidasProvider);
    final todas = async.value ?? const <Medida>[];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.monitor_weight_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.medidasCorpo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${todas.length}',
                  style: TextStyle(color: AppColors.dim, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Seletor de métrica (rola na horizontal se não couber).
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final m in MetricaCorporal.values) ...[
                    _ChipMetrica(
                      rotulo: _rotuloMetrica(s, m),
                      selecionado: _metrica == m,
                      onTap: () => setState(() => _metrica = m),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: async.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(child: Text('$e')),
                data: (_) => todas.isEmpty
                    ? _vazio(s)
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          _PainelMetrica(metrica: _metrica, medidas: todas, s: s),
                          const SizedBox(height: 16),
                          ..._listaMedicoes(s, todas),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.accent,
                side: BorderSide(color: context.accent),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _novaMedicao(s),
              icon: const Icon(Icons.add),
              label: Text(s.novaMedicao),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(Strings s) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.straighten, size: 48, color: AppColors.dim2),
        const SizedBox(height: 12),
        Text(
          s.nenhumaMedida,
          style: TextStyle(color: AppColors.dim),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  List<Widget> _listaMedicoes(Strings s, List<Medida> todas) => [
    for (final m in todas)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _MedicaoCard(
          medida: m,
          s: s,
          onEditar: () => _editar(s, m),
          onExcluir: () => _excluir(s, m),
        ),
      ),
  ];

  Future<void> _novaMedicao(Strings s) async {
    final hoje = DateTime.now();
    // Se já há medição de hoje, edita-a (evita duplicata no mesmo dia).
    final doDia = ref.read(medidasProvider.notifier).doDia(hoje);
    await _abrirEditor(s, inicial: doDia, dataPadrao: hoje);
  }

  Future<void> _editar(Strings s, Medida m) =>
      _abrirEditor(s, inicial: m, dataPadrao: m.data);

  Future<void> _abrirEditor(
    Strings s, {
    Medida? inicial,
    required DateTime dataPadrao,
  }) async {
    final salvou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _EditorMedicaoSheet(inicial: inicial, dataPadrao: dataPadrao),
    );
    if (salvou == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.salvar)));
    }
  }

  Future<void> _excluir(Strings s, Medida m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(s.excluirMedicao),
        content: Text(s.excluirMedicaoDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              s.apagar,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Snapshot p/ o DESFAZER via snackbar.
    final antes = ref.read(medidasProvider).value ?? const <Medida>[];
    await ref.read(medidasProvider.notifier).remover(m.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(s.excluirMedicao),
          action: SnackBarAction(
            label: s.desfazer,
            onPressed: () =>
                ref.read(medidasProvider.notifier).restaurar(antes),
          ),
        ),
      );
  }
}

/// Uma pílula do seletor de métrica.
class _ChipMetrica extends StatelessWidget {
  const _ChipMetrica({
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selecionado ? context.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selecionado ? context.accent : AppColors.line,
          ),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            color: selecionado ? context.onAccent : AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Painel da métrica escolhida: valor atual grande, variações (desde a 1ª e vs.
/// anterior) e o gráfico de aumento/diminuição.
class _PainelMetrica extends StatelessWidget {
  const _PainelMetrica({
    required this.metrica,
    required this.medidas,
    required this.s,
  });

  final MetricaCorporal metrica;
  final List<Medida> medidas; // mais recente primeiro
  final Strings s;

  @override
  Widget build(BuildContext context) {
    // Só as medições que têm a métrica, em ordem CRONOLÓGICA (antiga → nova).
    final pontos =
        medidas.where((m) => m.valorDe(metrica) != null).toList().reversed
            .toList();
    final unidade = metrica.unidade;

    if (pontos.isEmpty) {
      return _box(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            s.nenhumaMedida,
            style: TextStyle(color: AppColors.dim),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final valores = [for (final m in pontos) m.valorDe(metrica)!];
    final atual = valores.last;
    final primeiro = valores.first;
    final deltaInicio = atual - primeiro;
    final deltaAnterior =
        valores.length >= 2 ? atual - valores[valores.length - 2] : null;

    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _rotuloMetrica(s, metrica),
                style: TextStyle(
                  color: AppColors.dim,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _fmtNum(atual),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unidade,
                  style: TextStyle(color: AppColors.dim, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _DeltaChip(
                rotulo: s.desdeInicio,
                delta: deltaInicio,
                unidade: unidade,
              ),
              if (deltaAnterior != null)
                _DeltaChip(
                  rotulo: s.vsAnterior,
                  delta: deltaAnterior,
                  unidade: unidade,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (valores.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                s.precisaDuasMedicoes,
                style: TextStyle(color: AppColors.dim, fontSize: 12.5),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: CustomPaint(
                painter: _GraficoMedidaPainter(
                  valores: valores,
                  datas: [for (final m in pontos) m.data],
                  accent: context.accent,
                ),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _box({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: child,
  );
}

/// Pílula de variação: seta p/ cima (verde) ou p/ baixo (vermelha) + o valor.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.rotulo,
    required this.delta,
    required this.unidade,
  });

  final String rotulo;
  final double delta;
  final String unidade;

  @override
  Widget build(BuildContext context) {
    final sobe = delta > 0.0001;
    final desce = delta < -0.0001;
    final cor = sobe
        ? AppColors.prep
        : desce
        ? AppColors.danger
        : AppColors.dim;
    final icone = sobe
        ? Icons.arrow_upward_rounded
        : desce
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: cor),
          const SizedBox(width: 4),
          Text(
            '${_fmtNum(delta.abs())} $unidade',
            style: TextStyle(
              color: cor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(rotulo, style: TextStyle(color: AppColors.dim, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Card de uma medição na lista: data + os valores preenchidos + editar/excluir.
class _MedicaoCard extends StatelessWidget {
  const _MedicaoCard({
    required this.medida,
    required this.s,
    required this.onEditar,
    required this.onExcluir,
  });

  final Medida medida;
  final Strings s;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final partes = <String>[
      for (final m in MetricaCorporal.values)
        if (medida.valorDe(m) != null)
          '${_rotuloMetrica(s, m)} ${_fmtNum(medida.valorDe(m)!)}${m.unidade}',
    ];
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onEditar,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtData(medida.data),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    partes.join('  ·  '),
                    style: TextStyle(color: AppColors.dim, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: s.editar,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.dim),
              onPressed: onEditar,
            ),
            IconButton(
              tooltip: s.excluirMedicao,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: AppColors.dim,
              ),
              onPressed: onExcluir,
            ),
          ],
        ),
      ),
    );
  }
}

/// Editor de uma medição: data + os 5 campos (todos opcionais). Devolve `true`
/// pelo Navigator quando salvou.
class _EditorMedicaoSheet extends ConsumerStatefulWidget {
  const _EditorMedicaoSheet({required this.inicial, required this.dataPadrao});

  final Medida? inicial;
  final DateTime dataPadrao;

  @override
  ConsumerState<_EditorMedicaoSheet> createState() =>
      _EditorMedicaoSheetState();
}

class _EditorMedicaoSheetState extends ConsumerState<_EditorMedicaoSheet> {
  late DateTime _data;
  late final Map<MetricaCorporal, TextEditingController> _ctls;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _data = DateTime(
      widget.dataPadrao.year,
      widget.dataPadrao.month,
      widget.dataPadrao.day,
    );
    _ctls = {
      for (final m in MetricaCorporal.values)
        m: TextEditingController(
          text: widget.inicial?.valorDe(m) == null
              ? ''
              : _fmtNum(widget.inicial!.valorDe(m)!),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _ctls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Aceita vírgula ou ponto; vazio/invalido → null.
  double? _parse(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2015),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day),
    );
    if (escolhida != null) {
      setState(() => _data = DateTime(
        escolhida.year,
        escolhida.month,
        escolhida.day,
      ));
    }
  }

  Future<void> _salvar(Strings s) async {
    final valores = {
      for (final m in MetricaCorporal.values) m: _parse(_ctls[m]!.text),
    };
    if (valores.values.every((v) => v == null)) {
      setState(() => _erro = s.preenchaAlgo);
      return;
    }
    // Reaproveita o id ao editar; senão, se já há medição deste dia, edita-a.
    final notifier = ref.read(medidasProvider.notifier);
    final existente = widget.inicial ?? notifier.doDia(_data);
    final m = Medida(
      id: existente?.id,
      data: _data,
      peso: valores[MetricaCorporal.peso],
      cintura: valores[MetricaCorporal.cintura],
      braco: valores[MetricaCorporal.braco],
      peito: valores[MetricaCorporal.peito],
      coxa: valores[MetricaCorporal.coxa],
    );
    await notifier.salvar(m);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(temaProvider);
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    final editando = widget.inicial != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                editando ? s.editarMedicao : s.novaMedicao,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              // Data (tocar abre o seletor).
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _escolherData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: context.accent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.data,
                        style: TextStyle(color: AppColors.dim, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        _fmtData(_data),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.dim,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final m in MetricaCorporal.values) ...[
                _CampoMetrica(
                  rotulo: _rotuloMetrica(s, m),
                  unidade: m.unidade,
                  controller: _ctls[m]!,
                ),
                const SizedBox(height: 10),
              ],
              if (_erro != null) ...[
                const SizedBox(height: 2),
                Text(
                  _erro!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: context.onAccent,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () => _salvar(s),
                icon: const Icon(Icons.check_rounded),
                label: Text(s.salvar),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um campo numérico do editor (rótulo + unidade à direita).
class _CampoMetrica extends StatelessWidget {
  const _CampoMetrica({
    required this.rotulo,
    required this.unidade,
    required this.controller,
  });

  final String rotulo;
  final String unidade;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            rotulo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              hintText: '—',
              hintStyle: TextStyle(color: AppColors.dim2),
              suffixText: ' $unidade',
              suffixStyle: TextStyle(color: AppColors.dim, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.accent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gráfico de linha da métrica ao longo do tempo. Cada segmento é colorido pela
/// direção: subida = verde ([AppColors.prep]), descida = vermelho
/// ([AppColors.danger]), igual = cinza. Pontos espaçados por índice (ordem
/// cronológica); rótulos de min/max e das datas das pontas.
class _GraficoMedidaPainter extends CustomPainter {
  _GraficoMedidaPainter({
    required this.valores,
    required this.datas,
    required this.accent,
  });

  final List<double> valores; // cronológico (antigo → novo), >= 2
  final List<DateTime> datas;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 6.0, padR = 6.0, padTop = 18.0, padBot = 22.0;
    final w = size.width - padL - padR;
    final h = size.height - padTop - padBot;

    var vMin = valores.reduce((a, b) => a < b ? a : b);
    var vMax = valores.reduce((a, b) => a > b ? a : b);
    if (vMax == vMin) {
      // Série plana: dá uma folga p/ a linha ficar centralizada.
      vMin -= 1;
      vMax += 1;
    }
    final range = vMax - vMin;
    final n = valores.length;

    double x(int i) => padL + (n == 1 ? w / 2 : w * i / (n - 1));
    double y(double v) => padTop + h - ((v - vMin) / range) * h;

    // Linhas-guia faint no topo (máx) e na base (mín).
    final guia = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padTop), Offset(padL + w, padTop), guia);
    canvas.drawLine(
      Offset(padL, padTop + h),
      Offset(padL + w, padTop + h),
      guia,
    );

    // Segmentos coloridos pela direção.
    for (var i = 0; i < n - 1; i++) {
      final sobe = valores[i + 1] > valores[i];
      final desce = valores[i + 1] < valores[i];
      final cor = sobe
          ? AppColors.prep
          : desce
          ? AppColors.danger
          : AppColors.dim;
      final p = Paint()
        ..color = cor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x(i), y(valores[i])),
        Offset(x(i + 1), y(valores[i + 1])),
        p,
      );
    }

    // Pontos (o último em destaque com o accent).
    for (var i = 0; i < n; i++) {
      final ultimo = i == n - 1;
      final dot = Paint()
        ..color = ultimo ? accent : AppColors.text
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x(i), y(valores[i])), ultimo ? 4.5 : 2.6, dot);
    }

    // Rótulos: máx (topo-esq), mín (base-esq), data da 1ª e da última ponta.
    _texto(canvas, _fmtNum(vMax), Offset(padL, 1), AppColors.dim, 10);
    _texto(
      canvas,
      _fmtNum(vMin),
      Offset(padL, padTop + h + 2),
      AppColors.dim,
      10,
    );
    _texto(
      canvas,
      _fmtDataCurta(datas.first),
      Offset(padL, size.height - 12),
      AppColors.dim2,
      9.5,
    );
    _texto(
      canvas,
      _fmtDataCurta(datas.last),
      Offset(size.width - padR, size.height - 12),
      AppColors.dim2,
      9.5,
      alinharDireita: true,
    );
  }

  void _texto(
    Canvas canvas,
    String txt,
    Offset pos,
    Color cor,
    double tam, {
    bool alinharDireita = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: txt,
        style: TextStyle(color: cor, fontSize: tam, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alinharDireita ? pos.dx - tp.width : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  bool shouldRepaint(_GraficoMedidaPainter old) =>
      old.valores != valores || old.accent != accent;
}
