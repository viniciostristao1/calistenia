import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registro_progressao.dart';
import '../../services/conclusao_repository.dart';
import '../../services/gamificacao_pref.dart';
import '../../services/progressao_repository.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/gamificacao.dart';

/// Aba "Progressão" com duas sub-abas: **Desenvolvimento** (barras de reps por
/// exercício) e **Rating** (nível de forma + gráfico de tendência).
class ProgressaoScreen extends ConsumerStatefulWidget {
  const ProgressaoScreen({super.key});

  @override
  ConsumerState<ProgressaoScreen> createState() => _ProgressaoScreenState();
}

class _ProgressaoScreenState extends ConsumerState<ProgressaoScreen> {
  int _vista = 0; // 0 = Desenvolvimento, 1 = Rating

  @override
  Widget build(BuildContext context) {
    final gamiOn = ref.watch(gamificacaoProvider).value ?? true;
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
                  ButtonSegment(value: 0, label: Text('Desenvolvimento')),
                  ButtonSegment(value: 1, label: Text('Rating')),
                ],
                selected: {vista},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _vista = s.first),
              ),
            ),
          Expanded(child: vista == 1 ? _rating() : _desenvolvimento()),
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
    final rating = ratingForma(concs, treinos, prog);
    final serie = serieRating(concs, treinos, prog);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _RatingCard(rating: rating),
        const SizedBox(height: 18),
        const Text('Tendência',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        const Text('Seu Rating nas últimas semanas.',
            style: TextStyle(color: AppColors.dim, fontSize: 12)),
        const SizedBox(height: 12),
        _GraficoLinha(pontos: serie),
        const SizedBox(height: 16),
        const Text(
          'Rating = Assiduidade (0–100, últimos 28 dias) + Evolução (0–40, '
          'recordes recentes com ganho decrescente). Cai se você parar de '
          'treinar ou de bater recordes.',
          style: TextStyle(color: AppColors.dim, fontSize: 12),
        ),
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
        content: Text('${fmtDataAno(r.data)} · ${r.valor} reps'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Remover', style: TextStyle(color: AppColors.danger)),
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
            child:
                const Text('Limpar', style: TextStyle(color: AppColors.danger)),
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
                              fontSize: 16, fontWeight: FontWeight.w700),
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
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.dim2),
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
        style: TextStyle(color: cor, fontSize: 11.5, fontWeight: FontWeight.w700),
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
      height: _trilho + 20,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < registros.length; i++)
              _Barra(
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
    required this.registro,
    required this.fracao,
    required this.trilho,
    required this.alturaMaxBarra,
    required this.destaque,
    required this.ehRecorde,
    required this.onTap,
  });

  static const _corRecorde = Color(0xFFF4C542); // ouro do selo de recorde

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
                        const Icon(Icons.workspace_premium,
                            size: 12, color: _corRecorde),
                        const SizedBox(width: 1),
                      ],
                      Text(
                        '${registro.valor}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              ehRecorde ? FontWeight.w800 : FontWeight.w700,
                          color: corValor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 14,
                    height: h,
                    decoration: BoxDecoration(
                      color: destaque
                          ? context.accent
                          : context.accent.withValues(alpha: 0.45),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              fmtDataCurta(registro.data),
              style: const TextStyle(color: AppColors.dim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card do Rating: valor atual + barra + composição (assiduidade / evolução).
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
              const Text('Rating',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text('${rating.total}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: context.accent)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 9,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation(context.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assiduidade ${rating.assiduidade}/100 · Evolução ${rating.evolucao}/40',
            style: const TextStyle(color: AppColors.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de linha (tendência do Rating): traços ligando os pontos, com a área
/// sob a curva. O eixo Y se ajusta ao maior valor para a tendência ficar visível.
class _GraficoLinha extends StatelessWidget {
  const _GraficoLinha({required this.pontos});

  final List<PontoRating> pontos;

  @override
  Widget build(BuildContext context) {
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
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LinhaPainter(
                pontos: pontos,
                cor: context.accent,
                corGrade: AppColors.line,
                corTexto: AppColors.dim2,
              ),
            ),
          ),
          if (pontos.length >= 2) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(fmtDataCurta(pontos.first.data),
                    style: const TextStyle(color: AppColors.dim, fontSize: 10)),
                const Spacer(),
                Text(fmtDataCurta(pontos.last.data),
                    style: const TextStyle(color: AppColors.dim, fontSize: 10)),
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
  });

  final List<PontoRating> pontos;
  final Color cor;
  final Color corGrade;
  final Color corTexto;

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
    }

    final ponto = Paint()..color = cor;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(pos(i), i == n - 1 ? 4.0 : 2.5, ponto);
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
  bool shouldRepaint(_LinhaPainter old) => true;
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
            const Icon(Icons.trending_up, size: 56, color: AppColors.dim2),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma progressão ainda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
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
