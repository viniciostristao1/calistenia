import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/checkin.dart';
import '../../models/conquista.dart';
import '../../models/exercicio.dart';
import '../../models/treino.dart';
import '../../services/checkin_repository.dart';
import '../../services/conclusao_repository.dart';
import '../../services/conquistas_repository.dart';
import '../../services/gamificacao_pref.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/dias.dart';
import '../../util/format.dart';
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

  @override
  Widget build(BuildContext context) {
    final gamiOn = ref.watch(gamificacaoProvider).value ?? true;
    final mostrarConquistas = gamiOn && _vista == 1;
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
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Calendário'),
                    icon: Icon(Icons.calendar_month, size: 18),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Conquistas'),
                    icon: Icon(Icons.emoji_events, size: 18),
                  ),
                ],
                selected: {_vista},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _vista = s.first),
              ),
            ),
          Expanded(
            child: mostrarConquistas
                ? const _GaleriaConquistas()
                : _calendario(gamiOn),
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
              _TeaserConquistas(onTap: () => setState(() => _vista = 1)),
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
                        const TextStyle(color: AppColors.dim, fontSize: 12)),
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
                  style: const TextStyle(
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
    required this.hoje,
    required this.onTap,
  });

  final int dia;
  final List<int> cores; // corIndex dos check-ins do dia
  final bool hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mostrar = cores.take(4).toList();
    final extra = cores.length - mostrar.length;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cores.isNotEmpty ? AppColors.surface : Colors.transparent,
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
                      style: const TextStyle(
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
            const Padding(
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
                  icon: const Icon(Icons.close,
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

/// Faixa compacta abaixo do calendário: sequência atual + medalhas já obtidas.
/// Tocar leva à galeria de Conquistas.
class _TeaserConquistas extends ConsumerWidget {
  const _TeaserConquistas({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concs = ref.watch(conclusaoProvider).value ?? const [];
    final treinos = ref.watch(treinosProvider).value ?? const [];
    final conquistas = ref.watch(conquistasProvider).value ?? const [];
    final streak = streakAtual(concs, treinos);
    final emojis = [
      for (final t in TipoConquista.values)
        if (conquistas.any((c) => c.tipo == t.chave)) t.emoji,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$streak ',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: context.accent),
                    ),
                    TextSpan(
                      text: streak == 1 ? 'dia seguido' : 'dias seguidos',
                      style: const TextStyle(color: AppColors.dim),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (emojis.isNotEmpty)
                Text(emojis.join(' '), style: const TextStyle(fontSize: 16))
              else
                const Text('Conquistas',
                    style: TextStyle(color: AppColors.dim, fontSize: 12)),
              const Icon(Icons.chevron_right, color: AppColors.dim, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Galeria de conquistas: sequência, total, medalhas e troféus (o de Ouro fica
/// oculto — "conquista secreta" — até ser desbloqueado).
class _GaleriaConquistas extends ConsumerWidget {
  const _GaleriaConquistas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concs = ref.watch(conclusaoProvider).value ?? const [];
    final treinos = ref.watch(treinosProvider).value ?? const [];
    final conquistas = ref.watch(conquistasProvider).value ?? const [];

    final streak = streakAtual(concs, treinos);
    final melhor = melhorStreak(concs, treinos);
    final total = totalDiasConcluidos(concs);

    bool tem(TipoConquista t) => conquistas.any((c) => c.tipo == t.chave);
    DateTime? quando(TipoConquista t) => quandoConquistou(conquistas, t);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _StreakCard(streak: streak, melhor: melhor, total: total),
        const SizedBox(height: 20),
        const _TituloSecao('Medalhas', 'Prêmio por dias de treino seguidos'),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ConquistaCard(
                  tipo: TipoConquista.medalhaPrata,
                  earned: tem(TipoConquista.medalhaPrata),
                  quando: quando(TipoConquista.medalhaPrata),
                  progresso: 'Melhor sequência: $melhor/4',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ConquistaCard(
                  tipo: TipoConquista.medalhaOuro,
                  earned: tem(TipoConquista.medalhaOuro),
                  quando: quando(TipoConquista.medalhaOuro),
                  progresso: 'Melhor sequência: $melhor/8',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _TituloSecao('Troféus', 'Marcos que ficam para sempre'),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ConquistaCard(
                  tipo: TipoConquista.trofeuPrata,
                  earned: tem(TipoConquista.trofeuPrata),
                  quando: quando(TipoConquista.trofeuPrata),
                  progresso: 'Concluídos: $total/15',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ConquistaCard(
                  tipo: TipoConquista.trofeuOuro,
                  earned: tem(TipoConquista.trofeuOuro),
                  quando: quando(TipoConquista.trofeuOuro),
                  progresso: '',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.streak,
    required this.melhor,
    required this.total,
  });

  final int streak;
  final int melhor;
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
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$streak ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.accent,
                        ),
                      ),
                      TextSpan(
                        text: streak == 1 ? 'dia seguido' : 'dias seguidos',
                        style: const TextStyle(color: AppColors.dim),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('Melhor sequência: $melhor',
                    style: const TextStyle(color: AppColors.dim, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$total',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const Text('dias concluídos',
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
            style: const TextStyle(color: AppColors.dim, fontSize: 12)),
      ],
    );
  }
}

/// Um card de conquista: se obtida, mostra emoji + data; se bloqueada, mostra
/// o progresso; a conquista-surpresa fica oculta ("???") até desbloquear.
class _ConquistaCard extends StatelessWidget {
  const _ConquistaCard({
    required this.tipo,
    required this.earned,
    required this.quando,
    required this.progresso,
  });

  final TipoConquista tipo;
  final bool earned;
  final DateTime? quando;
  final String progresso;

  @override
  Widget build(BuildContext context) {
    final oculta = tipo.surpresa && !earned;
    final titulo = oculta ? '???' : tipo.titulo;
    final subtitulo = earned
        ? (quando != null ? 'Conquista em ${fmtDataCurta(quando!)}' : 'Conquistada')
        : (oculta ? 'Conquista secreta' : progresso);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned ? context.accent : AppColors.line,
          width: earned ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: earned ? 1 : 0.35,
            child: oculta
                ? const Icon(Icons.help_outline, size: 38, color: AppColors.dim)
                : Text(tipo.emoji, style: const TextStyle(fontSize: 38)),
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: earned ? AppColors.text : AppColors.dim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.dim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
