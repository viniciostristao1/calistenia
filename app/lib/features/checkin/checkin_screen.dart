import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/checkin.dart';
import '../../models/conquista.dart';
import '../../models/exercicio.dart';
import '../../models/insignia.dart';
import '../../models/treino.dart';
import '../../services/checkin_repository.dart';
import '../../services/conclusao_repository.dart';
import '../../services/conquistas_repository.dart';
import '../../services/gamificacao_pref.dart';
import '../../services/insignias_repository.dart';
import '../../services/progressao_repository.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/conquista_badge.dart';
import '../../util/dias.dart';
import '../../util/gamificacao.dart';

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Aba "Check-in": calendário mensal de assiduidade. Cada dia mostra os
/// pontinhos das cores dos exercícios feitos naquele dia.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  late DateTime _mes; // primeiro dia do mês exibido
  int _vista = 0; // 0 = calendário, 1 = conquistas

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _mes = DateTime(n.year, n.month, 1);
  }

  void _mudarMes(int delta) =>
      setState(() => _mes = DateTime(_mes.year, _mes.month + delta, 1));

  /// Move para o histórico as conquistas que caíram (e restaura as que voltaram).
  /// Só roda com os dados carregados (senão marcaria tudo como perdido à toa).
  void _reconciliar() {
    final concsA = ref.read(conclusaoProvider);
    final treinosA = ref.read(treinosProvider);
    final progA = ref.read(progressaoProvider);
    final conqA = ref.read(conquistasProvider);
    if (concsA.isLoading ||
        treinosA.isLoading ||
        progA.isLoading ||
        conqA.isLoading) {
      return;
    }
    final atuais = conquistasAtuais(
      concsA.value ?? const [],
      treinosA.value ?? const [],
      progA.value ?? const [],
    );
    ref.read(conquistasProvider.notifier).reconciliar(atuais);
  }

  @override
  Widget build(BuildContext context) {
    final gamiOn = ref.watch(gamificacaoProvider).value ?? true;
    final vista = gamiOn ? _vista : 0;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 22),
            SizedBox(width: 8),
            Text('Check-in'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (gamiOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  selectedForegroundColor: context.onAccent,
                  selectedBackgroundColor: context.accent,
                  foregroundColor: AppColors.dim,
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                segments: const [
                  ButtonSegment(value: 0, label: Text('Calendário')),
                  ButtonSegment(value: 1, label: Text('Galeria')),
                  ButtonSegment(value: 2, label: Text('Histórico')),
                ],
                selected: {vista},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  setState(() => _vista = s.first);
                  if (s.first != 0) _reconciliar();
                },
              ),
            ),
          Expanded(
            child: switch (vista) {
              1 => const _GaleriaConquistas(),
              2 => const _HistoricoConquistas(),
              _ => _calendario(gamiOn),
            },
          ),
        ],
      ),
    );
  }

  Widget _calendario(bool gamiOn) {
    final async = ref.watch(checkinProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
      data: (todos) {
        final hoje = DateTime.now();
        // Conquistas por dia (miniatura no calendário, no lugar dos pontinhos).
        final conquistas = gamiOn
            ? (ref.watch(conquistasProvider).value ?? const <Conquista>[])
            : const <Conquista>[];
        final conqPorDia = <String, List<TipoConquista>>{};
        for (final c in conquistas) {
          final t = tipoConquistaDe(c.tipo);
          if (t == null) continue;
          (conqPorDia['${c.data.year}-${c.data.month}-${c.data.day}'] ??= [])
              .add(t);
        }
        final diasNoMes = DateTime(_mes.year, _mes.month + 1, 0).day;
        final offset = _mes.weekday - 1; // seg=0 .. dom=6
        final feitosNoMes = todos
            .where((c) => c.data.year == _mes.year && c.data.month == _mes.month)
            .map((c) => c.data.day)
            .toSet()
            .length;
        return Column(
          children: [
            _Cabecalho(
              titulo: '${_meses[_mes.month - 1]} ${_mes.year}',
              subtitulo: feitosNoMes == 0
                  ? 'Nenhum dia marcado'
                  : '$feitosNoMes ${feitosNoMes == 1 ? 'dia' : 'dias'} treinados',
              onAnterior: () => _mudarMes(-1),
              onProximo: () => _mudarMes(1),
            ),
            if (gamiOn)
              _QuadroInsignias(onTap: () => setState(() => _vista = 2)),
            const _LinhaDias(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.78,
                ),
                itemCount: offset + diasNoMes,
                itemBuilder: (_, i) {
                  if (i < offset) return const SizedBox.shrink();
                  final dia = DateTime(_mes.year, _mes.month, i - offset + 1);
                  final doDia = checkinsDoDia(todos, dia);
                  return _Celula(
                    dia: dia.day,
                    cores: doDia.map((c) => c.corIndex).toList(),
                    conquistas:
                        conqPorDia['${dia.year}-${dia.month}-${dia.day}'] ??
                            const [],
                    hoje: mesmoDia(dia, hoje),
                    onTap: () => _editarDia(dia),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _editarDia(DateTime dia) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditarDiaSheet(dia: dia),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.titulo,
    required this.subtitulo,
    required this.onAnterior,
    required this.onProximo,
  });

  final String titulo;
  final String subtitulo;
  final VoidCallback onAnterior;
  final VoidCallback onProximo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onAnterior,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(subtitulo,
                    style:
                        TextStyle(color: AppColors.dim, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onProximo,
          ),
        ],
      ),
    );
  }
}

class _LinhaDias extends StatelessWidget {
  const _LinhaDias();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final d in nomesDiasCurtos)
            Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                      color: AppColors.dim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Celula extends StatelessWidget {
  const _Celula({
    required this.dia,
    required this.cores,
    required this.conquistas,
    required this.hoje,
    required this.onTap,
  });

  final int dia;
  final List<int> cores; // corIndex dos check-ins do dia
  final List<TipoConquista> conquistas; // conquistas obtidas nesse dia
  final bool hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mostrar = cores.take(4).toList();
    final extra = cores.length - mostrar.length;
    final temConteudo = cores.isNotEmpty || conquistas.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: temConteudo ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: hoje
              ? Border.all(color: context.accent, width: 1.5)
              : Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dia',
              style: TextStyle(
                fontSize: 13,
                fontWeight: hoje ? FontWeight.w800 : FontWeight.w500,
                color: hoje ? context.accent : AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            // Dia com conquista: mostra a medalha/troféu no lugar dos pontinhos.
            if (conquistas.isNotEmpty)
              Wrap(
                spacing: 1,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in conquistas.take(3))
                    ConquistaBadge(tipo: t, size: 13),
                ],
              )
            else
              Wrap(
                spacing: 2,
                runSpacing: 2,
                alignment: WrapAlignment.center,
                children: [
                  for (final c in mostrar)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.corExercicio(c),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (extra > 0)
                    Text('+$extra',
                        style: TextStyle(
                            color: AppColors.dim, fontSize: 8)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Folha de edição de um dia: lista os check-ins e permite remover/adicionar.
class _EditarDiaSheet extends ConsumerWidget {
  const _EditarDiaSheet({required this.dia});

  final DateTime dia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(checkinProvider).value ?? const <CheckIn>[];
    final doDia = checkinsDoDia(todos, dia);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
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
            '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (doDia.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhum exercício marcado neste dia.',
                  style: TextStyle(color: AppColors.dim)),
            )
          else
            for (final c in doDia)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.corExercicio(c.corIndex),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(c.exercicio),
                trailing: IconButton(
                  icon: Icon(Icons.close,
                      size: 20, color: AppColors.dim2),
                  onPressed: () =>
                      ref.read(checkinProvider.notifier).remover(c.id),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.accent,
              side: BorderSide(color: context.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _adicionar(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Marcar exercício'),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionar(BuildContext context, WidgetRef ref) async {
    final treinos = ref.read(treinosProvider).value ?? const <Treino>[];
    final disponiveis = _exerciciosDisponiveis(treinos);
    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie exercícios nos treinos primeiro.')),
      );
      return;
    }
    final escolhido = await showModalBottomSheet<Exercicio>(
      context: context,
      backgroundColor: AppColors.bg,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Marcar qual exercício?',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final e in disponiveis)
              ListTile(
                leading: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.corExercicio(e.corIndex),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(e.nome),
                onTap: () => Navigator.pop(context, e),
              ),
          ],
        ),
      ),
    );
    if (escolhido != null) {
      await ref
          .read(checkinProvider.notifier)
          .adicionarManual(escolhido.nome, escolhido.corIndex, dia);
    }
  }
}

/// Exercícios distintos (por nome) presentes nos treinos, para marcar manual.
List<Exercicio> _exerciciosDisponiveis(List<Treino> treinos) {
  final mapa = <String, Exercicio>{};
  for (final t in treinos) {
    for (final e in t.exercicios) {
      final nome = e.nome.trim();
      if (nome.isNotEmpty) mapa.putIfAbsent(nome.toLowerCase(), () => e);
    }
  }
  return mapa.values.toList();
}

/// Quadro compacto (baixo e largo) abaixo do calendário: as INSÍGNIAS (estrelas)
/// GANHAS no mês corrente. Mostra só as ganhas — as que faltam ficam em segredo.
/// Tocar leva ao Histórico (onde ficam as estrelas dos meses anteriores).
class _QuadroInsignias extends ConsumerWidget {
  const _QuadroInsignias({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(insigniasProvider).value ?? const <Insignia>[];
    final agora = DateTime.now();
    final doMes = insigniasDoMes(lista, agora.year, agora.month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: AppColors.estrela),
              const SizedBox(width: 8),
              Text('Insígnias do mês',
                  style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
              const Spacer(),
              if (doMes.isEmpty)
                Text('—', style: TextStyle(color: AppColors.dim2, fontSize: 14))
              else
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 1,
                    runSpacing: 1,
                    children: [
                      for (var i = 0; i < doMes.length; i++)
                        Icon(Icons.star_rounded,
                            size: 18, color: AppColors.estrela),
                    ],
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.dim, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Galeria: conquistas atuais, sequência/recorde e as regras (medalhas e
/// troféus), cada uma com o progresso da sequência ("Sequência: X/N").
class _GaleriaConquistas extends ConsumerWidget {
  const _GaleriaConquistas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concs = ref.watch(conclusaoProvider).value ?? const [];
    final treinos = ref.watch(treinosProvider).value ?? const [];
    final prog = ref.watch(progressaoProvider).value ?? const [];

    final nivel = nivelInfo(concs, treinos);
    final total = totalDiasConcluidos(concs);
    final atuais = conquistasAtuais(concs, treinos, prog);

    Widget card(TipoConquista t) => _ConquistaCard(
          tipo: t,
          ativo: atuais.contains(t),
          nivel: nivel.atual,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ConquistasAtuaisBox(atuais: atuais),
        const SizedBox(height: 16),
        _StreakCard(nivel: nivel.atual, recorde: nivel.recorde, total: total),
        const SizedBox(height: 20),
        const _TituloSecao('Medalhas', 'Dias de treino seguidos'),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: card(TipoConquista.medalhaPrata)),
              const SizedBox(width: 12),
              Expanded(child: card(TipoConquista.medalhaOuro)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _TituloSecao('Troféus', 'Sequências mais longas (o Ouro pede progressão)'),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: card(TipoConquista.trofeuPrata)),
              const SizedBox(width: 12),
              Expanded(child: card(TipoConquista.trofeuOuro)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sub-aba "Histórico": as INSÍGNIAS (estrelas) ganhas em meses anteriores e os
/// títulos (medalhas/troféus) PERDIDOS, agrupados por mês (mais recente em cima).
/// O mês corrente das insígnias vive no quadro do calendário, não aqui.
class _HistoricoConquistas extends ConsumerWidget {
  const _HistoricoConquistas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conquistas = ref.watch(conquistasProvider).value ?? const <Conquista>[];
    final insignias = ref.watch(insigniasProvider).value ?? const <Insignia>[];
    final perdidas = conquistas.where((c) => c.perdidaEm != null).toList();

    // Insígnias por mês (só meses PASSADOS — o mês atual está no quadro).
    final agora = DateTime.now();
    final insigniasPorMes = <String, int>{};
    for (final ins in insignias) {
      if (ins.data.year == agora.year && ins.data.month == agora.month) continue;
      final k =
          '${ins.data.year}-${ins.data.month.toString().padLeft(2, '0')}';
      insigniasPorMes[k] = (insigniasPorMes[k] ?? 0) + 1;
    }

    if (perdidas.isEmpty && insigniasPorMes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 56, color: AppColors.dim2),
              SizedBox(height: 16),
              Text('Histórico vazio',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text(
                'As estrelas ganhas em meses anteriores e os títulos perdidos '
                '(quebra de sequência) ficam guardados aqui, por mês.',
                style: TextStyle(color: AppColors.dim),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Títulos perdidos, agrupados pelo mês da perda.
    final mapaConq = <String, List<TipoConquista>>{};
    for (final c in perdidas) {
      final t = tipoConquistaDe(c.tipo);
      if (t == null) continue;
      final d = c.perdidaEm!;
      (mapaConq['${d.year}-${d.month.toString().padLeft(2, '0')}'] ??= [])
          .add(t);
    }
    final chavesIns = insigniasPorMes.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final chavesConq = mapaConq.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (chavesIns.isNotEmpty) ...[
          const _TituloSecao('Insígnias', 'Estrelas ganhas em meses anteriores'),
          const SizedBox(height: 10),
          for (final k in chavesIns) ...[
            _MesInsignias(chaveMes: k, quantas: insigniasPorMes[k]!),
            const SizedBox(height: 12),
          ],
          if (chavesConq.isNotEmpty) const SizedBox(height: 12),
        ],
        if (chavesConq.isNotEmpty) ...[
          const _TituloSecao(
              'Títulos perdidos', 'Medalhas e troféus por quebra de sequência'),
          const SizedBox(height: 10),
          for (final k in chavesConq) ...[
            _MesHistorico(chaveMes: k, tipos: mapaConq[k]!),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

/// Título "Mês Ano" a partir de uma chave 'YYYY-MM'.
String _tituloMes(String chaveMes) {
  final p = chaveMes.split('-');
  final mes = int.tryParse(p[1]) ?? 1;
  return '${_meses[(mes - 1).clamp(0, 11)]} ${p[0]}';
}

/// Linha de um mês no histórico de insígnias: nome do mês + estrelas ganhas.
class _MesInsignias extends StatelessWidget {
  const _MesInsignias({required this.chaveMes, required this.quantas});

  final String chaveMes; // 'YYYY-MM'
  final int quantas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_tituloMes(chaveMes),
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 1,
              runSpacing: 1,
              children: [
                for (var i = 0; i < quantas; i++)
                  Icon(Icons.star_rounded, size: 18, color: AppColors.estrela),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$quantas',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.estrela)),
        ],
      ),
    );
  }
}

class _MesHistorico extends StatelessWidget {
  const _MesHistorico({required this.chaveMes, required this.tipos});

  final String chaveMes; // 'YYYY-MM'
  final List<TipoConquista> tipos;

  String get _titulo {
    final p = chaveMes.split('-');
    final mes = int.tryParse(p[1]) ?? 1;
    return '${_meses[(mes - 1).clamp(0, 11)]} ${p[0]}';
  }

  @override
  Widget build(BuildContext context) {
    // Ordena pela ordem natural das conquistas (prata->ouro->troféus).
    final ordenados = [
      for (final t in TipoConquista.values)
        if (tipos.contains(t)) t,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_titulo,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              for (final t in ordenados)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConquistaBadge(tipo: t, size: 26, ativo: false),
                    const SizedBox(height: 3),
                    Text(t.tituloCurto,
                        style: TextStyle(
                            color: AppColors.dim, fontSize: 10)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Caixa "Conquistas atuais": o que você sustenta AGORA. Tudo é por sequência —
/// se pular um dia agendado, TODAS caem. O Troféu de Ouro também exige progressão
/// recente. Vazia enquanto não houver nenhuma.
class _ConquistasAtuaisBox extends StatelessWidget {
  const _ConquistasAtuaisBox({required this.atuais});

  final Set<TipoConquista> atuais;

  @override
  Widget build(BuildContext context) {
    final tipos = [
      for (final t in TipoConquista.values)
        if (atuais.contains(t)) t,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tipos.isEmpty ? AppColors.line : context.accent,
          width: tipos.isEmpty ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conquistas atuais',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          if (tipos.isEmpty)
            Text(
              'Nenhuma conquista ativa ainda. Complete treinos para conquistar!',
              style: TextStyle(color: AppColors.dim, fontSize: 13),
            )
          else
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                for (final t in tipos)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConquistaBadge(tipo: t, size: 34),
                      const SizedBox(height: 4),
                      Text(t.tituloCurto,
                          style: TextStyle(
                              color: AppColors.dim, fontSize: 11)),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.nivel,
    required this.recorde,
    required this.total,
  });

  final int nivel;
  final int recorde;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sequência atual',
                    style: TextStyle(color: AppColors.dim, fontSize: 12)),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$nivel ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.accent,
                        ),
                      ),
                      TextSpan(
                        text: nivel == 1 ? 'dia' : 'dias',
                        style: TextStyle(color: AppColors.dim),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('🏅 Recorde: $recorde ${recorde == 1 ? 'dia' : 'dias'}',
                    style: TextStyle(color: AppColors.dim, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$total',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              Text('dias no total',
                  style: TextStyle(color: AppColors.dim, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.titulo, this.subtitulo);

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        Text(subtitulo,
            style: TextStyle(color: AppColors.dim, fontSize: 12)),
      ],
    );
  }
}

/// Card de uma conquista (regra): badge + nome + barra de progresso da
/// sequência. Enquanto não bate, a barra fica cinza; ao atingir (ativa), a barra
/// e o badge ganham a cor da conquista (prata/ouro).
class _ConquistaCard extends StatelessWidget {
  const _ConquistaCard({
    required this.tipo,
    required this.ativo,
    required this.nivel,
  });

  final TipoConquista tipo;
  final bool ativo;
  final int nivel;

  @override
  Widget build(BuildContext context) {
    final alvo = limiarSequencia(tipo);
    final fracao = (nivel / alvo).clamp(0.0, 1.0);
    final cor = corConquista(tipo);
    final ouroFaltaProgresso =
        tipo == TipoConquista.trofeuOuro && nivel >= alvo && !ativo;
    final legenda = ativo
        ? 'Conquista ativa ✓'
        : ouroFaltaProgresso
            ? 'Sequência ok · falta progressão'
            : '$nivel/$alvo dias'
                '${tipo == TipoConquista.trofeuOuro ? ' + progressão' : ''}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ativo ? cor : AppColors.line,
          width: ativo ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConquistaBadge(tipo: tipo, size: 38, ativo: ativo),
          const SizedBox(height: 8),
          Text(
            tipo.titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ativo ? AppColors.text : AppColors.dim,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fracao,
              minHeight: 7,
              backgroundColor: AppColors.surface2,
              // Sem cor enquanto não bate; cor da conquista quando ativa.
              valueColor: AlwaysStoppedAnimation(
                  ativo ? cor : AppColors.dim2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            legenda,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ativo ? cor : AppColors.dim,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
