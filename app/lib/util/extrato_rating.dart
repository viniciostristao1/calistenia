import '../models/conclusao.dart';
import '../models/registro_progressao.dart';
import '../models/treino.dart';
import '../services/progressao_repository.dart' show agruparPorExercicio;
import 'gamificacao.dart';

/// **Extrato do Rating (on-device, derivado — NÃO guarda histórico).** As últimas
/// "pontuações" que somaram ao seu Rating, montadas a partir dos próprios dados.
/// Lógica pura (sem I/O, sem UI).

/// Uma pontuação do extrato (um evento que somou pontos).
class PontuacaoExtrato {
  final DateTime data;
  final int pontos; // + pontos somados
  final String motivo; // "Treino concluído" / "Recorde · Flexão" / "Insígnia" / "Escudo"
  final String emoji;
  const PontuacaoExtrato(this.data, this.pontos, this.motivo, this.emoji);
}

DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

/// Lista as últimas [max] pontuações (mais recente primeiro), derivadas dos dados:
///  - **dias com GANHO de Rating base** (treino concluído / recorde): o valor é
///    quanto aquele dia somou à nota de hoje — a MESMA conta do "ganho do dia"
///    (`ratingForma(dados até o dia) − até a véspera`, janela fixa em hoje). Rotula
///    "Recorde · <nome>" se bateu recorde naquele dia, senão "Treino concluído";
///  - **insígnias (+10)** e **escudos (+20)** como pontuações próprias.
/// Janela de [janelaDias] p/ limitar o custo (dias sem atividade não pontuam).
List<PontuacaoExtrato> extratoRating(
  List<Conclusao> concs,
  List<Treino> treinos,
  List<RegistroProgressao> prog, {
  Set<DateTime> diasInsignia = const {},
  Set<DateTime> diasEscudo = const {},
  DateTime? hoje,
  int max = 10,
  int janelaDias = 60,
}) {
  final hj = _d(hoje ?? DateTime.now());
  final limite = hj.subtract(Duration(days: janelaDias));
  bool naJanela(DateTime d) => !d.isBefore(limite) && !d.isAfter(hj);

  // Recordes por dia (reps OU peso que superaram o melhor anterior) → rótulo.
  final recordeNomePorDia = <DateTime, String>{};
  for (final g in agruparPorExercicio(prog)) {
    var maxReps = -1;
    var maxPeso = -1.0;
    for (final r in g.registros) {
      final dd = _d(r.data);
      final prReps = maxReps >= 0 && r.valor > maxReps;
      final prPeso = maxPeso >= 0 && r.peso > 0 && r.peso > maxPeso;
      if ((prReps || prPeso) && naJanela(dd)) {
        recordeNomePorDia[dd] = g.exercicio.trim();
      }
      if (r.valor > maxReps) maxReps = r.valor;
      if (r.peso > maxPeso) maxPeso = r.peso;
    }
  }

  // Dias candidatos a ganho base: dias com conclusão completa OU com recorde.
  final diasAtividade = <DateTime>{};
  for (final c in concs) {
    if (c.completo && naJanela(_d(c.data))) diasAtividade.add(_d(c.data));
  }
  diasAtividade.addAll(recordeNomePorDia.keys);

  List<T> ate<T>(List<T> l, DateTime lim, DateTime Function(T) data) => [
    for (final x in l)
      if (!data(x).isAfter(lim)) x,
  ];

  final eventos = <PontuacaoExtrato>[];
  for (final dia in diasAtividade) {
    final vespera = dia.subtract(const Duration(days: 1));
    final antes = ratingForma(
      ate(concs, vespera, (c) => _d(c.data)),
      treinos,
      ate(prog, vespera, (r) => _d(r.data)),
      hoje: hj,
    ).total;
    final agora = ratingForma(
      ate(concs, dia, (c) => _d(c.data)),
      treinos,
      ate(prog, dia, (r) => _d(r.data)),
      hoje: hj,
    ).total;
    final ganho = agora - antes;
    if (ganho <= 0) continue;
    final rec = recordeNomePorDia[dia];
    eventos.add(
      rec != null
          ? PontuacaoExtrato(dia, ganho, 'Recorde · $rec', '🏆')
          : PontuacaoExtrato(dia, ganho, 'Treino concluído', '💪'),
    );
  }

  // Insígnias e escudos como pontuações próprias (valor fixo).
  for (final d in diasInsignia) {
    if (naJanela(_d(d))) eventos.add(PontuacaoExtrato(_d(d), 10, 'Insígnia', '⭐'));
  }
  for (final d in diasEscudo) {
    if (naJanela(_d(d))) eventos.add(PontuacaoExtrato(_d(d), 20, 'Escudo', '🛡️'));
  }

  eventos.sort((a, b) => b.data.compareTo(a.data));
  return eventos.take(max).toList();
}

/// Quanto o Rating base ganharia se você CONCLUÍSSE um treino hoje (0 se já fez
/// hoje ou se não muda). Simulação honesta: rating com uma conclusão de hoje menos
/// o rating atual — é o "+N ao treinar" do extrato.
int ganhoSeTreinarHoje(
  List<Conclusao> concs,
  List<Treino> treinos,
  List<RegistroProgressao> prog, {
  DateTime? hoje,
}) {
  final hj = _d(hoje ?? DateTime.now());
  if (concs.any((c) => c.completo && _d(c.data) == hj)) return 0;
  final atual = ratingForma(concs, treinos, prog, hoje: hj).total;
  final comHoje = ratingForma(
    [...concs, Conclusao(data: hj, treinoId: '', treino: '', completo: true)],
    treinos,
    prog,
    hoje: hj,
  ).total;
  final g = comHoje - atual;
  return g > 0 ? g : 0;
}
