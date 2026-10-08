import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/escudo.dart';
import '../../models/registro_progressao.dart';
import '../../services/cards_repository.dart';
import '../../services/checkin_repository.dart';
import '../../services/conclusao_repository.dart';
import '../../services/escudo_repository.dart';
import '../../services/gamificacao_pref.dart';
import '../../services/insignias_repository.dart';
import '../../services/moedas_repository.dart';
import '../../services/navegacao.dart';
import '../../services/progressao_repository.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/cards_catalog.dart';
import '../../util/format.dart';
import '../../util/gamificacao.dart';
import '../../util/treinador.dart';
import '../../widgets/moedas_badge.dart';
import '../../widgets/sub_abas.dart';

/// Aba "Progressão" com duas sub-abas: **Desenvolvimento** (barras de reps por
/// exercício) e **Rating** (nível de forma + gráfico de tendência).
class ProgressaoScreen extends ConsumerStatefulWidget {
  const ProgressaoScreen({super.key, this.onIrParaAba});

  /// Troca a aba da barra inferior (0=Treinos, 1=Check-in, 2=Progressão) — usado
  /// pelos botões de ação das dicas do Resumo.
  final void Function(int aba)? onIrParaAba;

  @override
  ConsumerState<ProgressaoScreen> createState() => _ProgressaoScreenState();
}

class _ProgressaoScreenState extends ConsumerState<ProgressaoScreen> {
  int _vista = 0; // 0 = Desenvolvimento, 1 = Rating
  int _animKey = 0;
  bool _semeado = false; // baselines dos exercícios já existentes semeadas?

  @override
  void initState() {
    super.initState();
    progressaoVistaInicial.addListener(_irParaVista);
    _irParaVista();
  }

  @override
  void dispose() {
    progressaoVistaInicial.removeListener(_irParaVista);
    super.dispose();
  }

  /// Deep-link (ex.: tocar na moeda → abre os Cards). Troca o segmento.
  void _irParaVista() {
    final v = progressaoVistaInicial.value;
    if (v == null || !mounted) return;
    setState(() {
      _vista = v;
      _animKey++;
    });
    progressaoVistaInicial.value = null;
  }

  void restartAnimation() {
    if (mounted) setState(() => _animKey++);
  }

  void restartRatingAnimation() => restartAnimation();

  /// Semeia (uma vez) a linha de base dos exercícios já salvos que ainda não
  /// têm registro — migração para quem criou treinos antes desta versão.
  void _talvezSemearBaselines() {
    if (_semeado) return;
    final treinosA = ref.read(treinosProvider);
    final progA = ref.read(progressaoProvider);
    if (!treinosA.hasValue || !progA.hasValue) return;
    _semeado = true;
    final treinos = treinosA.value!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(progressaoProvider.notifier).garantirBaselines(treinos);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gamiOn = ref.watch(gamificacaoProvider).value ?? true;
    // Observa os dois para reconstruir quando carregarem (dispara a semeadura).
    ref.watch(treinosProvider);
    ref.watch(progressaoProvider);
    _talvezSemearBaselines();
    final vista = gamiOn ? _vista : 0;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up, size: 22),
            SizedBox(width: 8),
            Text('Progressão'),
          ],
        ),
        actions: const [MoedasBadge()],
      ),
      body: Column(
        children: [
          if (gamiOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: SubAbas(
                abas: const ['Evolução', 'Rating', 'Cards', 'Coach'],
                selecionado: vista,
                onSelect: (i) => setState(() {
                  _vista = i;
                  _animKey++;
                }),
              ),
            ),
          Expanded(
            child: KeyedSubtree(
              key: ValueKey('$_animKey-$_vista'),
              child: switch (vista) {
                1 => _rating(),
                2 => const _Colecao(),
                3 => _ResumoView(
                  onVerEvolucao: () => setState(() {
                    _vista = 0;
                    _animKey++;
                  }),
                  onIrAba: widget.onIrParaAba,
                ),
                _ => _desenvolvimento(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _desenvolvimento() {
    final async = ref.watch(progressaoProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
      data: (registros) {
        if (registros.isEmpty) return const _Vazio();
        final grupos = agruparPorExercicio(registros);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: grupos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ExercicioProgressoCard(grupo: grupos[i]),
        );
      },
    );
  }

  Widget _rating() {
    final concs = ref.watch(conclusaoProvider).value ?? const [];
    final treinos = ref.watch(treinosProvider).value ?? const [];
    final prog = ref.watch(progressaoProvider).value ?? const [];
    final insignias = ref.watch(insigniasProvider).value ?? const [];
    final diasIns = diasComInsignia(insignias);
    final diasEsc = diasEscudoGanho(
      ref.watch(escudoProvider).value ?? const <Escudo>[],
    );
    final rating = ratingForma(
      concs,
      treinos,
      prog,
      diasInsignia: diasIns,
      diasEscudoGanho: diasEsc,
    );
    final series = seriesRating(
      concs,
      treinos,
      prog,
      diasInsignia: diasIns,
      diasEscudoGanho: diasEsc,
    );
    return KeyedSubtree(
      key: ValueKey(_animKey),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _RatingCard(rating: rating),
          const SizedBox(height: 18),
          const Text(
            'Tendência · Geral',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            'Seu Rating total nas últimas semanas.',
            style: TextStyle(color: AppColors.dim, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _GraficoLinha(pontos: series.total),
          const SizedBox(height: 20),
          const Text(
            'Por categoria',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            'Veja qual parte está puxando (ou segurando) o seu Rating.',
            style: TextStyle(color: AppColors.dim, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _CategoriaRating(
            titulo: 'Consistência',
            atual: rating.consistencia,
            max: 400,
            cor: AppColors.rest,
            pontos: series.consistencia,
          ),
          const SizedBox(height: 10),
          _CategoriaRating(
            titulo: 'Frequência',
            atual: rating.frequencia,
            max: 200,
            cor: AppColors.prep,
            pontos: series.frequencia,
          ),
          const SizedBox(height: 10),
          _CategoriaRating(
            titulo: 'Progressão',
            atual: rating.progressao,
            max: 400,
            cor: AppColors.exec,
            pontos: series.progressao,
          ),
          const SizedBox(height: 16),
          Text(
            'Rating 0–1000 = Consistência (0–400, % dos dias agendados nos últimos '
            '28 dias — hoje é neutro) + Frequência (0–200, seu volume de treino) + '
            'Progressão (0–400, o quanto seus recordes — de repetições OU de peso — '
            'melhoraram nos últimos ~42 dias). Consistência é o alicerce; para '
            'passar do platô, bata recordes.',
            style: TextStyle(color: AppColors.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Um bloco de categoria do Rating: título + valor atual (x/max) + mini-gráfico
/// da tendência daquele componente.
class _CategoriaRating extends StatelessWidget {
  const _CategoriaRating({
    required this.titulo,
    required this.atual,
    required this.max,
    required this.cor,
    required this.pontos,
  });

  final String titulo;
  final int atual;
  final int max;
  final Color cor;
  final List<PontoRating> pontos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const Spacer(),
            Text(
              '$atual',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: cor,
              ),
            ),
            Text(
              ' / $max',
              style: TextStyle(color: AppColors.dim, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _GraficoLinha(pontos: pontos, altura: 86, cor: cor),
      ],
    );
  }
}

class _ExercicioProgressoCard extends ConsumerWidget {
  const _ExercicioProgressoCard({required this.grupo});

  final GrupoProgressao grupo;

  Future<void> _confirmarRemoverRegistro(
    BuildContext context,
    WidgetRef ref,
    RegistroProgressao r,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remover este registro?'),
        content: Text(
          '${fmtDataAno(r.data)} · ${r.valor} reps'
          '${r.peso > 0 ? ' · ${fmtPeso(r.peso)}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remover',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(progressaoProvider.notifier).remover(r.id);
  }

  Future<void> _confirmarLimpar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Limpar progressão?'),
        content: Text('Remove todos os registros de “${grupo.exercicio}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Limpar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(progressaoProvider.notifier).removerExercicio(grupo.exercicio);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = grupo.ultimo - grupo.primeiro;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          grupo.exercicio.isEmpty
                              ? 'Sem nome'
                              : grupo.exercicio,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (delta != 0) ...[
                        const SizedBox(width: 8),
                        _DeltaChip(delta: delta),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Limpar progressão',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.dim2,
                  ),
                  onPressed: () => _confirmarLimpar(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 2),
            _GraficoBarras(
              registros: grupo.registros,
              onTapBarra: (r) => _confirmarRemoverRegistro(context, ref, r),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final sobe = delta > 0;
    final cor = sobe ? AppColors.exec : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${sobe ? '+' : ''}$delta',
        style: TextStyle(
          color: cor,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Gráfico de barras horizontal (uma barra por registro). Rola na horizontal
/// quando há muitos pontos. Tocar numa barra chama [onTapBarra].
class _GraficoBarras extends StatelessWidget {
  const _GraficoBarras({required this.registros, required this.onTapBarra});

  final List<RegistroProgressao> registros;
  final ValueChanged<RegistroProgressao> onTapBarra;

  // Trilho de altura fixa: as bases das barras ficam TODAS na mesma linha
  // (embaixo); só a altura muda com o valor. Espaço reservado no topo p/ o número.
  static const double _trilho = 70;
  static const double _reservaValor = 18;

  @override
  Widget build(BuildContext context) {
    final maxV = registros
        .map((r) => r.valor)
        .fold<int>(1, (a, b) => a > b ? a : b);
    // Recorde = última barra com o maior valor (só destaca se houver ≥2 registros).
    var recordeIdx = -1;
    if (registros.length >= 2) {
      var melhor = -1;
      for (var i = 0; i < registros.length; i++) {
        if (registros[i].valor >= melhor) {
          melhor = registros[i].valor;
          recordeIdx = i;
        }
      }
    }
    return SizedBox(
      height: _trilho + 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < registros.length; i++)
              _Barra(
                idx: i,
                registro: registros[i],
                fracao: registros[i].valor / maxV,
                trilho: _trilho,
                alturaMaxBarra: _trilho - _reservaValor,
                destaque: i == registros.length - 1,
                ehRecorde: i == recordeIdx,
                onTap: () => onTapBarra(registros[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.idx,
    required this.registro,
    required this.fracao,
    required this.trilho,
    required this.alturaMaxBarra,
    required this.destaque,
    required this.ehRecorde,
    required this.onTap,
  });

  static const _corRecorde = Color(0xFFF4C542); // ouro do selo de recorde

  final int idx;
  final RegistroProgressao registro;
  final double fracao;
  final double trilho;
  final double alturaMaxBarra;
  final bool destaque; // último registro em destaque
  final bool ehRecorde; // maior valor de todos = recorde (selo)
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = (alturaMaxBarra * fracao).clamp(6.0, alturaMaxBarra);
    // Cor do número: recorde (ouro) > último (accent) > normal.
    final corValor = ehRecorde
        ? _corRecorde
        : (destaque ? context.accent : AppColors.text);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trilho fixo com o conteúdo colado embaixo -> base alinhada.
            SizedBox(
              height: trilho,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Selo de recorde ao lado do número (não muda a altura).
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ehRecorde) ...[
                        const Icon(
                          Icons.workspace_premium,
                          size: 12,
                          color: _corRecorde,
                        ),
                        const SizedBox(width: 1),
                      ],
                      Text(
                        '${registro.valor}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: ehRecorde
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: corValor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: h),
                    duration: Duration(milliseconds: 700 + idx * 85),
                    curve: Curves.easeOutCubic,
                    builder: (context, ch, _) => Container(
                      width: 14,
                      height: ch,
                      decoration: BoxDecoration(
                        color: destaque
                            ? context.accent
                            : context.accent.withValues(alpha: 0.45),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              fmtDataCurta(registro.data),
              style: TextStyle(color: AppColors.dim, fontSize: 11),
            ),
            // Peso do registro (só quando há carga) — a segunda dimensão.
            if (registro.peso > 0)
              Text(
                fmtPeso(registro.peso),
                style: TextStyle(
                  color: context.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Card do Rating: valor atual + barra + composição (assiduidade / evolução).
/// Números contam de 0 até o valor e a barra preenche em 900ms (um pouco mais lento).
class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final RatingForma rating;

  @override
  Widget build(BuildContext context) {
    final frac = (rating.total / RatingForma.maximo).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Rating',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: rating.total),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '$v',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: context.accent,
                  ),
                ),
              ),
              if (rating.bonusEstrelas > 0) ...[
                const SizedBox(width: 8),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: rating.bonusEstrelas),
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '+$v',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.estrela,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: AppColors.estrela,
                ),
              ],
              if (rating.bonusEscudos > 0) ...[
                const SizedBox(width: 8),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: rating.bonusEscudos),
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '+$v',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.escudo,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.shield_rounded,
                  size: 18,
                  color: AppColors.escudo,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: frac),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 9,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation(context.accent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, t, _) => Opacity(
              opacity: t,
              child: Text(
                'Consistência ${rating.consistencia}/400 · '
                'Frequência ${rating.frequencia}/200 · '
                'Progressão ${rating.progressao}/400'
                '${rating.bonusEstrelas > 0 ? ' · Bônus ⭐ +${rating.bonusEstrelas}' : ''}',
                style: TextStyle(color: AppColors.dim, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de linha (tendência do Rating): traços ligando os pontos, com a área
/// sob a curva. Desenha da esquerda para a direita em 850ms.
class _GraficoLinha extends StatelessWidget {
  const _GraficoLinha({required this.pontos, this.altura = 160, this.cor});

  final List<PontoRating> pontos;
  final double altura;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final c = cor ?? context.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 12, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          SizedBox(
            height: altura,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, prog, _) => CustomPaint(
                size: Size.infinite,
                painter: _LinhaPainter(
                  pontos: pontos,
                  cor: c,
                  corGrade: AppColors.line,
                  corTexto: AppColors.dim2,
                  progresso: prog,
                ),
              ),
            ),
          ),
          if (pontos.length >= 2) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  fmtDataCurta(pontos.first.data),
                  style: TextStyle(color: AppColors.dim, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  fmtDataCurta(pontos.last.data),
                  style: TextStyle(color: AppColors.dim, fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaPainter extends CustomPainter {
  _LinhaPainter({
    required this.pontos,
    required this.cor,
    required this.corGrade,
    required this.corTexto,
    this.progresso = 1.0,
  });

  final List<PontoRating> pontos;
  final Color cor;
  final Color corGrade;
  final Color corTexto;
  final double progresso;

  @override
  void paint(Canvas canvas, Size size) {
    // Topo dinâmico (com folga) p/ a curva preencher a área e a tendência ficar
    // legível mesmo com valores baixos.
    var maxObs = 1;
    for (final p in pontos) {
      if (p.valor > maxObs) maxObs = p.valor;
    }
    final topo = (maxObs * 1.15).ceilToDouble();

    final grade = Paint()
      ..color = corGrade
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = size.height * (1 - f);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grade);
    }

    if (pontos.isEmpty) return;
    final n = pontos.length;
    Offset pos(int i) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      final y = size.height * (1 - (pontos[i].valor / topo).clamp(0.0, 1.0));
      return Offset(x, y);
    }

    if (n >= 2) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progresso, size.height));
      final fill = Path()..moveTo(pos(0).dx, size.height);
      for (var i = 0; i < n; i++) {
        fill.lineTo(pos(i).dx, pos(i).dy);
      }
      fill
        ..lineTo(pos(n - 1).dx, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..color = cor.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );
      final linha = Path()..moveTo(pos(0).dx, pos(0).dy);
      for (var i = 1; i < n; i++) {
        linha.lineTo(pos(i).dx, pos(i).dy);
      }
      canvas.drawPath(
        linha,
        Paint()
          ..color = cor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      final ponto = Paint()..color = cor;
      for (var i = 0; i < n; i++) {
        if (pos(i).dx <= size.width * progresso + 1) {
          canvas.drawCircle(pos(i), i == n - 1 ? 4.0 : 2.5, ponto);
        }
      }
      canvas.restore();
    } else {
      final ponto = Paint()..color = cor;
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(pos(i), 4.0, ponto);
      }
    }

    // Rótulo do topo do eixo Y (o maior valor do desenho).
    final tp = TextPainter(
      text: TextSpan(
        text: '${topo.toInt()}',
        style: TextStyle(color: corTexto, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(2, 0));
  }

  @override
  bool shouldRepaint(_LinhaPainter old) =>
      old.progresso != progresso || old.pontos != pontos;
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up, size: 56, color: AppColors.dim2),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma progressão ainda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Ao editar um exercício, toque em '
              '“Adicionar à progressão” para registrar quantas repetições '
              'você fez. A evolução aparece aqui em barras.',
              style: TextStyle(color: AppColors.dim),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── COLEÇÃO DE CARDS ─────────────────────────────

/// Sub-aba **Cards**: carteira ($) + grade da coleção (16 cards). Os que você tem
/// aparecem de frente (tocar amplia); os que faltam ficam DE COSTAS. Comprar
/// gasta [kCustoCard] e revela um card surpresa (vira a carta).
class _Colecao extends ConsumerWidget {
  const _Colecao();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final possuidos = ref.watch(cardsProvider).value ?? const <String>[];
    final moedas = ref.watch(moedasProvider).value ?? 0;
    final tidos = possuidos.toSet();
    final completa = colecaoCompleta(possuidos);
    final podeComprar = !completa && moedas >= kCustoCard;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$$moedas',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      '${tidos.length}/$totalCardsCatalogo cards',
                      style: TextStyle(color: AppColors.dim, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                if (completa)
                  const Text(
                    'Completa ✨',
                    style: TextStyle(
                      color: AppColors.estrela,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accent,
                      foregroundColor: context.onAccent,
                    ),
                    onPressed: podeComprar
                        ? () => _comprar(context, ref)
                        : null,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text('Comprar \$$kCustoCard'),
                  ),
              ],
            ),
          ),
        ),
        if (!completa && !podeComprar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Complete $kMarcoDias dias seguidos para ganhar \$$kMoedasPorMarco '
              'e trocar por um card surpresa.',
              style: TextStyle(color: AppColors.dim, fontSize: 12),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.60,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: todosCards.length,
            itemBuilder: (_, i) {
              final c = todosCards[i];
              return tidos.contains(c.id)
                  ? _SlotFrente(card: c)
                  : const _CardBack();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _comprar(BuildContext context, WidgetRef ref) async {
    final possuidos = ref.read(cardsProvider).value ?? const <String>[];
    if (colecaoCompleta(possuidos)) return;
    final ok = await ref.read(moedasProvider.notifier).gastar(kCustoCard);
    if (!ok) return;
    final id = await ref.read(cardsProvider.notifier).comprar();
    if (id == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _RevelarCardDialog(id: id),
    );
  }
}

/// Card POSSUÍDO na grade: a arte (tocar amplia).
class _SlotFrente extends StatelessWidget {
  const _SlotFrente({required this.card});

  final CardMotivacao card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _VerCardDialog(card: card),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: Colors.black,
          child: Image.asset(card.asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Card ainda NÃO possuído: de costas (surpresa).
class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface2, AppColors.bg],
        ),
        border: Border.all(color: context.accent.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline_rounded,
              size: 34,
              color: context.accent.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 6),
            Text(
              'surpresa',
              style: TextStyle(
                color: AppColors.dim,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ampliação de um card possuído (toque fora/fecha).
class _VerCardDialog extends StatelessWidget {
  const _VerCardDialog({required this.card});

  final CardMotivacao card;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(card.asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Revelação do card comprado: ele vem DE COSTAS e VIRA (flip em Y).
class _RevelarCardDialog extends StatefulWidget {
  const _RevelarCardDialog({required this.id});

  final String id;

  @override
  State<_RevelarCardDialog> createState() => _RevelarCardDialogState();
}

class _RevelarCardDialogState extends State<_RevelarCardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = cardPorId(widget.id)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_ctrl.value);
          final angle =
              (1 - t) * pi; // começa de costas (pi) e vira p/ frente (0)
          final frente = angle <= pi / 2;
          final revelado = _ctrl.isCompleted;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: const Text(
                  'Novo card!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: SizedBox(
                  width: 230,
                  height: 400,
                  child: frente
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ColoredBox(
                            color: Colors.black,
                            child: Image.asset(card.asset, fit: BoxFit.contain),
                          ),
                        )
                      : const _CardBack(),
                ),
              ),
              const SizedBox(height: 18),
              Opacity(
                opacity: revelado ? 1.0 : 0.0,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: context.onAccent,
                    minimumSize: const Size(180, 48),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('${card.titulo} · ${card.selo}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────────── RESUMO (TREINADOR) ─────────────────────────────

/// Sub-aba **Resumo**: o Treinador on-device — placar da semana + dicas
/// inteligentes (até 3), cada uma com ação de 1 toque quando faz sentido.
class _ResumoView extends ConsumerWidget {
  const _ResumoView({required this.onVerEvolucao, this.onIrAba});

  final VoidCallback onVerEvolucao;
  final void Function(int aba)? onIrAba;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concs = ref.watch(conclusaoProvider).value ?? const [];
    final treinos = ref.watch(treinosProvider).value ?? const [];
    final prog = ref.watch(progressaoProvider).value ?? const [];
    final checkins = ref.watch(checkinProvider).value ?? const [];
    final escudos = ref.watch(escudoProvider).value ?? const <Escudo>[];
    final cobertos = diasCobertosPorEscudo(escudos);
    final r = montarResumo(
      concs,
      treinos,
      prog,
      checkins.map((c) => c.data).toList(),
      diasEscudo: cobertos,
      temEscudoReserva: temEscudoDisponivel(escudos),
    );

    void agir(InsightAcao a) {
      switch (a) {
        case InsightAcao.progressao:
          onVerEvolucao();
        case InsightAcao.conquistas:
          // Deep-link direto na Galeria (sub-aba 1) do Check-in.
          checkinVistaInicial.value = 1;
          onIrAba?.call(1);
        case InsightAcao.treinos:
          onIrAba?.call(0); // Treinos
        case InsightAcao.nenhuma:
          break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const Text(
          'Resumo da semana',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'Calculado no seu aparelho, a partir dos seus treinos.',
          style: TextStyle(color: AppColors.dim, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        if (r.frase.isNotEmpty) ...[
          _FraseTreinador(frase: r.frase),
          const SizedBox(height: 14),
        ],
        _PlacarCompacto(r: r),
        const SizedBox(height: 14),
        _Sparkline8(valores: r.completosPorSemana),
        // "Seu momento (14 dias)": combina CONSISTÊNCIA + PROGRESSÃO recentes =
        // desempenho atual (janela rolante, evita "poucos dias" no começo do mês).
        if (r.temConsistencia || r.temAlta) ...[
          const SizedBox(height: 16),
          Text(
            'Seu momento (14 dias)',
            style: TextStyle(
              color: AppColors.dim,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 8),
          if (r.temConsistencia)
            _MiniResumoCard(
              emoji: '📅',
              titulo: 'Consistência (14 dias)',
              texto:
                  '${r.consistenciaPct}% · ${r.consistenciaFeitos} de ${r.consistenciaTotal} treinos',
              cor: r.consistenciaPct >= 80
                  ? AppColors.prep
                  : (r.consistenciaPct >= 50 ? AppColors.estrela : null),
            ),
          if (r.temAlta)
            _MiniResumoCard(
              emoji: '🔼',
              titulo: 'Em alta (14 dias)',
              texto:
                  '${r.altaNome} · ${r.altaDe} → ${r.altaPara} reps (+${r.altaPct}%)',
              cor: AppColors.prep,
            ),
        ],
        if (r.temProjecao) ...[
          const SizedBox(height: 12),
          _MiniResumoCard(
            emoji: '🎯',
            titulo: 'No seu ritmo',
            texto:
                '${r.projRotulo} em ~${r.projDias} ${r.projDias == 1 ? 'dia' : 'dias'}',
          ),
        ],
        if (r.recordesRecentes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Recordes dos últimos 14 dias',
            style: TextStyle(
              color: AppColors.dim,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rec in r.recordesRecentes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.estrela),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        rec,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        const Text(
          'Dicas pra você',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final ins in r.insights)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InsightCard(insight: ins, onAgir: () => agir(ins.acao)),
          ),
      ],
    );
  }
}

/// Placar da semana numa LINHA só (4 células): Completos · Sequência · Dias ·
/// Rating. Compacto p/ a caixinha ficar baixa.
class _PlacarCompacto extends StatelessWidget {
  const _PlacarCompacto({required this.r});

  final ResumoSemana r;

  @override
  Widget build(BuildContext context) {
    String? deltaTxt(int d) => d == 0 ? null : (d > 0 ? '+$d' : '−${-d}');
    Color deltaCor(int d) => d >= 0 ? AppColors.prep : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _cel(
            '${r.completos}',
            deltaTxt(r.deltaCompletos),
            deltaCor(r.deltaCompletos),
            'completos',
          ),
          _divisor(),
          _cel(
            '${r.sequencia}',
            'rec ${r.recorde}',
            AppColors.dim,
            'sequência',
          ),
          _divisor(),
          _cel('${r.diasTreinados}', null, null, 'dias'),
          _divisor(),
          _cel(
            '${r.rating}',
            deltaTxt(r.deltaRating),
            deltaCor(r.deltaRating),
            'rating',
          ),
        ],
      ),
    );
  }

  Widget _divisor() => Container(width: 1, height: 30, color: AppColors.line);

  Widget _cel(String valor, String? extra, Color? extraCor, String rotulo) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (extra != null) ...[
                const SizedBox(width: 3),
                Text(
                  extra,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: extraCor ?? AppColors.dim,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 1),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.dim, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

/// Frase-resumo do Treinador (voz "inteligente"): ícone de IA + texto natural.
class _FraseTreinador extends StatelessWidget {
  const _FraseTreinador({required this.frase});

  final String frase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 18, color: context.accent),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Treinador',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: context.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'resumo inteligente',
                      style: TextStyle(fontSize: 10.5, color: AppColors.dim),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  frase,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Micro-gráfico: treinos concluídos por semana nas últimas 8 semanas.
class _Sparkline8 extends StatelessWidget {
  const _Sparkline8({required this.valores});

  final List<int> valores; // 8 inteiros, antiga→recente

  @override
  Widget build(BuildContext context) {
    final maxV = valores.fold<int>(1, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Treinos por semana (8 sem.)',
            style: TextStyle(
              color: AppColors.dim,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < valores.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${valores[i]}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: i == valores.length - 1
                                  ? context.accent
                                  : AppColors.dim,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: (valores[i] / maxV * 26).clamp(3.0, 26.0),
                            decoration: BoxDecoration(
                              color: i == valores.length - 1
                                  ? context.accent
                                  : AppColors.dim2,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão compacto de 1 linha (emoji + rótulo + valor) dos destaques do Resumo
/// (em alta / projeção / ranking).
class _MiniResumoCard extends StatelessWidget {
  const _MiniResumoCard({
    required this.emoji,
    required this.titulo,
    required this.texto,
    this.cor,
  });

  final String emoji;
  final String titulo;
  final String texto;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.dim,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: cor ?? AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.onAgir});

  final Insight insight;
  final VoidCallback onAgir;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.texto,
                  style: TextStyle(
                    color: AppColors.dim,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (insight.acao != InsightAcao.nenhuma &&
                    insight.acaoLabel != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: context.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: context.accent.withValues(alpha: 0.12),
                      ),
                      onPressed: onAgir,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            insight.acaoLabel!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
