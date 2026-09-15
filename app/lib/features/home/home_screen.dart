import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conclusao.dart';
import '../../models/exercicio.dart';
import '../../models/treino.dart';
import '../../services/checkin_repository.dart';
import '../../services/conclusao_repository.dart';
import '../../services/home_layout_pref.dart';
import '../../services/idioma_repository.dart';
import '../../services/insignias_repository.dart';
import '../../services/progressao_repository.dart';
import '../../services/relogio.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/dias.dart';
import '../../util/exportar_treino.dart';
import '../../util/format.dart';
import '../../util/gamificacao.dart';
import '../../util/versao.dart';
import '../../l10n/strings.dart';
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

  /// Aba interna do modo Hoje/Semana (ideia 8).
  bool _verSemana = false;

  Future<void> _novoTreino() async {
    final t = Treino(nome: '', dias: [_dia]);
    await ref.read(treinosProvider.notifier).salvar(t);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TreinoEditorScreen(treinoId: t.id)),
    );
  }

  void _abrirConfig() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ConfigScreen()));

  /// Cicla o layout da página Treinos (mantém o modo atual como padrão).
  Future<void> _trocarModo() async {
    final prox = await ref.read(homeLayoutProvider.notifier).proximo();
    if (!mounted) return;
    final s = Strings(ref.read(idiomaProvider).value ?? Idioma.pt);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(s.modoLayoutNome(prox.label)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _compartilharDia() {
    final treinos = (ref.read(treinosProvider).value ?? const <Treino>[])
        .where((t) => t.dias.contains(_dia))
        .toList();
    final s = Strings(ref.read(idiomaProvider).value ?? Idioma.pt);
    if (treinos.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.nenhumTreinoDiaCompartilhar)));
      return;
    }
    _mostrarCompartilhar(s.compartilharDia, treinosParaTexto(treinos));
  }

  void _compartilharSemana() {
    final todos = ref.read(treinosProvider).value ?? const <Treino>[];
    final s = Strings(ref.read(idiomaProvider).value ?? Idioma.pt);
    if (todos.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.nenhumTreinoCadastrado)));
      return;
    }
    _mostrarCompartilhar(s.compartilharSemana, semanaParaTexto(todos));
  }

  void _mostrarCompartilhar(String titulo, String texto) {
    final s = Strings(ref.read(idiomaProvider).value ?? Idioma.pt);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(titulo),
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
            child: Text(s.fechar),
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(s.copiado)));
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(s.copiar),
          ),
        ],
      ),
    );
  }

  Future<void> _sair() async {
    final s = Strings(ref.read(idiomaProvider).value ?? Idioma.pt);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(s.sairApp),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.sair),
          ),
        ],
      ),
    );
    if (ok == true) SystemNavigator.pop();
  }

  void _mostrarDebug(BuildContext ctx) {
    final treinos = ref.read(treinosProvider).value ?? const <Treino>[];
    final concs = ref.read(conclusaoProvider).value ?? const [];
    final checkins = ref.read(checkinProvider).value ?? const [];
    final agendados = diasAgendados(treinos);
    final diasValidos = checkins
        .map((c) => DateTime(c.data.year, c.data.month, c.data.day))
        .toSet();
    final buf = StringBuffer();
    buf.writeln('DEBUG SEQUÊNCIA — v$kVersao');
    buf.writeln('Agendados (0=seg): $agendados');
    buf.writeln(
      'Treinos: ${treinos.map((t) => "${t.nome}:${t.dias}").join(" | ")}',
    );
    buf.writeln('');
    buf.writeln('Dia | Sem | Ag | Check | Concl | Nivel | Conquistas');
    for (var d = 10; d <= 20; d++) {
      final dt = DateTime(2026, 8, d);
      final wd = dt.weekday - 1;
      final ag = agendados.contains(wd) ? 'S' : '-';
      final ck = checkins
          .where((c) => c.data.day == d && c.data.month == 8)
          .length;
      final co = concs
          .where((c) => c.data.day == d && c.data.month == 8)
          .toList();
      final coTxt = co.isEmpty
          ? '-'
          : co.map((c) => c.completo ? 'C' : 'T').join(',');
      final nivel = nivelInfo(
        concs,
        treinos,
        hoje: dt,
        diasValidos: diasValidos,
      ).atual;
      final at = conquistasAtuais(
        concs,
        treinos,
        [],
        hoje: dt,
        diasValidos: diasValidos,
      );
      final atTxt = at.isEmpty ? '-' : at.map((e) => e.name).join(',');
      buf.writeln(
        '${d.toString().padLeft(2, '0')}/08 | $wd | $ag | $ck | $coTxt | $nivel | $atTxt',
      );
    }
    buf.writeln('');
    buf.writeln('Conclusoes Agosto:');
    for (final c in concs.where((c) => c.data.month == 8)) {
      buf.writeln(
        ' ${c.data.day.toString().padLeft(2, '0')}/08 ${c.treino} completo=${c.completo} id=${c.id.substring(0, 6)}',
      );
    }
    buf.writeln('Check-ins Agosto:');
    for (final c in checkins.where((c) => c.data.month == 8)) {
      buf.writeln(
        ' ${c.data.day.toString().padLeft(2, '0')}/08 ${c.exercicio}',
      );
    }
    final txt = buf.toString();
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Debug sequência 10-20/08'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              txt,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: txt));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Copiado! Cole aqui no chat.')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(treinosProvider);
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    final layout = ref.watch(homeLayoutProvider).value ?? HomeLayout.atual;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/icon/logo.png',
                height: 26,
                width: 26,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            // Nome em DUAS linhas ("Calis" / "Timer"): cabe inteiro mesmo com a
            // barra cheia de botões (antes cortava para "Calis…").
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calis',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: 1.4,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Timer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Número da versão junto do nome: confirma, num relance, que
                    // o build instalado é o mais novo (sobe junto com o pubspec).
                    // Long-press abre diagnóstico da sequência (debug de medalhas).
                    InkWell(
                      onLongPress: () => _mostrarDebug(context),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          'v$kVersao',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dim,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botão de modo: cada toque troca o layout da página Treinos.
          IconButton(
            tooltip: '${s.modoLayout} · ${layout.label}',
            icon: Icon(switch (layout) {
              HomeLayout.atual => Icons.view_quilt_outlined,
              HomeLayout.desempenho => Icons.insights_outlined,
              HomeLayout.abas => Icons.tab_outlined,
              HomeLayout.carrossel => Icons.view_carousel_outlined,
            }),
            onPressed: _trocarModo,
          ),
          IconButton(
            tooltip: s.configTitulo,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _abrirConfig,
          ),
          PopupMenuButton<String>(
            tooltip: s.compartilharDia,
            icon: const Icon(Icons.share_outlined),
            onSelected: (v) =>
                v == 'dia' ? _compartilharDia() : _compartilharSemana(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'dia', child: Text(s.compartilharDia)),
              PopupMenuItem(value: 'semana', child: Text(s.compartilharSemana)),
            ],
          ),
          IconButton(
            tooltip: s.sair,
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
        label: Text(s.novoTreino),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (treinos) {
          final diasComTreino = treinos.expand((t) => t.dias).toSet();
          final seletor = _SeletorDias(
            selecionado: _dia,
            diasComTreino: diasComTreino,
            onSelect: (d) => setState(() => _dia = d),
          );
          return switch (layout) {
            HomeLayout.atual => Column(
              children: [
                seletor,
                Expanded(child: _listaDoDia(treinos, _dia)),
              ],
            ),
            HomeLayout.desempenho => Column(
              children: [
                _FaixaDesempenho(treinos: treinos),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${s.diasLongos[diaDeHoje]}, ${DateTime.now().day}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _listaDoDia(treinos, diaDeHoje)),
              ],
            ),
            HomeLayout.abas => _ModoAbas(
              treinos: treinos,
              verSemana: _verSemana,
              onVerSemana: (v) => setState(() => _verSemana = v),
            ),
            HomeLayout.carrossel => _ModoCarrossel(
              treinos: treinos,
              dia: _dia,
              onDia: (d) => setState(() => _dia = d),
            ),
          };
        },
      ),
    );
  }
}

class _SeletorDias extends ConsumerWidget {
  const _SeletorDias({
    required this.selecionado,
    required this.diasComTreino,
    required this.onSelect,
  });

  final int selecionado;
  final Set<int> diasComTreino;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
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
                  rotulo: s.diasCurtos[d],
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

class _TreinoCard extends ConsumerWidget {
  const _TreinoCard({required this.treino});

  final Treino treino;

  void _abrirEditor(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => TreinoEditorScreen(treinoId: treino.id)),
  );

  /// Roda o treino/exercício. Ao voltar do player, reemite o relógio da UI
  /// (o treino pode ter levado minutos — a previsão "~hora" tem de atualizar).
  Future<void> _rodar(
    BuildContext context,
    WidgetRef ref,
    String titulo,
    List<Exercicio> exs, {
    Treino? treino,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PlayerScreen(titulo: titulo, exercicios: exs, treino: treino),
      ),
    );
    if (context.mounted) ref.invalidate(relogioProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Relógio da UI: sem ele, a previsão "~hora" ficava presa no valor do
    // primeiro build (aparecia no passado depois de um treino longo).
    final agora = ref.watch(relogioProvider).value ?? DateTime.now();
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
                          Padding(
                            padding: EdgeInsets.only(top: 2, right: 6),
                            child: Icon(
                              Icons.drag_indicator,
                              size: 20,
                              color: AppColors.dim2,
                            ),
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
                                    style: TextStyle(
                                      color: AppColors.dim,
                                      fontSize: 13,
                                    ),
                                    children: [
                                      TextSpan(text: base),
                                      if (dur > 0) ...[
                                        const TextSpan(text: ' · '),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Icon(
                                            Icons.access_time,
                                            size: 13,
                                            color: AppColors.dim,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              ' ~${fmtHora(agora.add(Duration(seconds: dur)))}',
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
                  onTap: () => _rodar(
                    context,
                    ref,
                    treino.nome,
                    treino.exercicios,
                    treino: treino,
                  ),
                ),
              ],
            ),
            // Lista de exercícios: toca em um -> roda só ele.
            if (treino.exercicios.isNotEmpty) ...[
              const SizedBox(height: 6),
              // Cor neutra/fraca, igual aos "6 pontinhos" do cabeçalho (dim2).
              Divider(height: 1, thickness: 1, color: AppColors.dim2),
              const SizedBox(height: 2),
              for (final e in treino.exercicios)
                _ExercicioLinha(
                  exercicio: e,
                  onRodar: () => _rodar(context, ref, e.nome, [e]),
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
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detalhe,
                    style: TextStyle(color: AppColors.dim, fontSize: 12),
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
      shape: CircleBorder(side: BorderSide(color: AppColors.line)),
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

class _Vazio extends ConsumerWidget {
  const _Vazio({required this.dia});

  final int dia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 56, color: AppColors.dim2),
            const SizedBox(height: 16),
            Text(
              s.nenhumTreinoEm(s.diasLongos[dia]),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              s.toqueNovoTreino,
              style: TextStyle(color: AppColors.dim),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista (ou vazio) dos treinos de um dia — usada pelos quatro modos.
Widget _listaDoDia(List<Treino> treinos, int dia) {
  final doDia = treinos.where((t) => t.dias.contains(dia)).toList();
  if (doDia.isEmpty) return _Vazio(dia: dia);
  return ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
    itemCount: doDia.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (_, i) => _TreinoCard(treino: doDia[i]),
  );
}

/// **Modo 7** — faixa de desempenho no topo: sequência, Rating (0..100, o
/// mesmo da aba Progressão) e dias treinados na semana (check-in ou conclusão).
class _FaixaDesempenho extends ConsumerWidget {
  const _FaixaDesempenho({required this.treinos});

  final List<Treino> treinos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings(ref.watch(idiomaProvider).value ?? Idioma.pt);
    final concs = ref.watch(conclusaoProvider).value ?? const <Conclusao>[];
    final checkins = ref.watch(checkinProvider).value ?? const [];
    final prog = ref.watch(progressaoProvider).value ?? const [];
    final insignias = ref.watch(insigniasProvider).value ?? const [];

    final agora = DateTime.now();
    final hoje0 = DateTime(agora.year, agora.month, agora.day);
    final segunda = hoje0.subtract(Duration(days: agora.weekday - 1));
    final proxima = segunda.add(const Duration(days: 7));

    // Dias treinados nesta semana: conclusão OU check-in (o check-in é
    // automático por exercício, então reflete atividade mesmo sem responder a
    // pergunta de fim de treino).
    final diasAtivos = <DateTime>{
      for (final c in concs)
        if (!c.data.isBefore(segunda) && c.data.isBefore(proxima)) c.data,
      for (final c in checkins)
        if (!c.data.isBefore(segunda) && c.data.isBefore(proxima))
          DateTime(c.data.year, c.data.month, c.data.day),
    };
    final previstos = diasAgendados(
      treinos,
    ).where((d) => d <= agora.weekday - 1).length;
    final rating = ratingForma(
      concs,
      treinos,
      prog,
      diasInsignia: diasComInsignia(insignias),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _Stat(
            icone: Icons.local_fire_department_rounded,
            valor: '${streakAtual(concs, treinos)}',
            rotulo: s.sequencia,
            cor: AppColors.exec,
          ),
          const SizedBox(width: 8),
          _Stat(
            icone: Icons.speed_rounded,
            valor: '${rating.total}',
            rotulo: 'Rating',
            cor: context.accent,
          ),
          const SizedBox(width: 8),
          _Stat(
            icone: Icons.event_available_rounded,
            valor: previstos == 0 ? '—' : '${diasAtivos.length}/$previstos',
            rotulo: s.semana,
            cor: AppColors.prep,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icone,
    required this.valor,
    required this.rotulo,
    required this.cor,
  });

  final IconData icone;
  final String valor;
  final String rotulo;
  final Color cor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 16, color: cor),
              const SizedBox(width: 4),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.dim, fontSize: 10.5),
          ),
        ],
      ),
    ),
  );
}

/// **Modo 8** — duas visões: Hoje (ação) e Semana (planejamento).
class _ModoAbas extends ConsumerWidget {
  const _ModoAbas({
    required this.treinos,
    required this.verSemana,
    required this.onVerSemana,
  });

  final List<Treino> treinos;
  final bool verSemana;
  final ValueChanged<bool> onVerSemana;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings(ref.watch(idiomaProvider).value ?? Idioma.pt);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _SegBtn(
                rotulo: s.hoje,
                on: !verSemana,
                onTap: () => onVerSemana(false),
              ),
              const SizedBox(width: 8),
              _SegBtn(
                rotulo: s.semana,
                on: verSemana,
                onTap: () => onVerSemana(true),
              ),
            ],
          ),
        ),
        Expanded(
          child: verSemana
              ? _SemanaLista(treinos: treinos)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${s.hoje} · ${s.diasLongos[diaDeHoje]}',
                          style: TextStyle(
                            color: AppColors.dim,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _listaDoDia(treinos, diaDeHoje)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({required this.rotulo, required this.on, required this.onTap});

  final String rotulo;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: on ? context.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? context.accent : AppColors.line),
        ),
        child: Text(
          rotulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: on ? context.onAccent : AppColors.text,
          ),
        ),
      ),
    ),
  );
}

/// Visão da semana inteira (modo 8): cada dia com seus treinos, hoje marcado.
class _SemanaLista extends ConsumerWidget {
  const _SemanaLista({required this.treinos});

  final List<Treino> treinos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings(ref.watch(idiomaProvider).value ?? Idioma.pt);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        for (var d = 0; d < 7; d++)
          _DiaSemana(dia: d, treinos: treinos, hoje: d == diaDeHoje, s: s),
      ],
    );
  }
}

class _DiaSemana extends StatelessWidget {
  const _DiaSemana({
    required this.dia,
    required this.treinos,
    required this.hoje,
    required this.s,
  });

  final int dia;
  final List<Treino> treinos;
  final bool hoje;
  final Strings s;

  @override
  Widget build(BuildContext context) {
    final doDia = treinos.where((t) => t.dias.contains(dia)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              s.diasLongos[dia],
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: hoje ? context.accent : AppColors.text,
              ),
            ),
            if (hoje) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: context.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  s.hoje,
                  style: TextStyle(
                    color: context.accent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              doDia.isEmpty ? '—' : '${doDia.length}',
              style: TextStyle(color: AppColors.dim, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (doDia.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              s.nenhumTreinoEm(s.diasLongos[dia]),
              style: TextStyle(color: AppColors.dim2, fontSize: 12.5),
            ),
          )
        else
          for (final t in doDia)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TreinoLinha(treino: t),
            ),
      ],
    );
  }
}

/// Linha compacta de treino (modo Semana): abre o editor ao tocar; ▶ roda.
class _TreinoLinha extends ConsumerWidget {
  const _TreinoLinha({required this.treino});

  final Treino treino;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = treino.exercicios.length;
    final dur = treino.duracaoTotalSeg;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TreinoEditorScreen(treinoId: treino.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treino.nome.isEmpty ? 'Novo treino' : treino.nome,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$n ${n == 1 ? 'exercício' : 'exercícios'} · ${fmtSeg(dur)}',
                      style: TextStyle(color: AppColors.dim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _PlayCircle(
                grande: false,
                habilitado: treino.exercicios.isNotEmpty,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        titulo: treino.nome,
                        exercicios: treino.exercicios,
                        treino: treino,
                      ),
                    ),
                  );
                  if (context.mounted) ref.invalidate(relogioProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **Modo 9** — carrossel de dias: setas, bolinhas e deslize lateral.
class _ModoCarrossel extends ConsumerWidget {
  const _ModoCarrossel({
    required this.treinos,
    required this.dia,
    required this.onDia,
  });

  final List<Treino> treinos;
  final int dia;
  final ValueChanged<int> onDia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings(ref.watch(idiomaProvider).value ?? Idioma.pt);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: s.diasLongos[(dia + 6) % 7],
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onDia((dia + 6) % 7),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      s.diasLongos[dia],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (dia == diaDeHoje)
                      Text(
                        s.hoje,
                        style: TextStyle(
                          color: context.accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: s.diasLongos[(dia + 1) % 7],
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onDia((dia + 1) % 7),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var d = 0; d < 7; d++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: d == dia ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: d == dia ? context.accent : AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (det) {
              final v = det.primaryVelocity ?? 0;
              if (v <= -250) {
                onDia((dia + 1) % 7);
              } else if (v >= 250) {
                onDia((dia + 6) % 7);
              }
            },
            child: _listaDoDia(treinos, dia),
          ),
        ),
      ],
    );
  }
}
