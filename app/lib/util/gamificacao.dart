import '../models/conclusao.dart';
import '../models/conquista.dart';
import '../models/registro_progressao.dart';
import '../models/treino.dart';
import '../services/progressao_repository.dart' show agruparPorExercicio;

/// Lógica (pura) da gamificação: sequência de dias, totais e avaliação das
/// conquistas. Sem estado nem I/O — recebe os dados e devolve números.

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Dias da semana (0=seg..6=dom) que têm algum treino agendado.
Set<int> diasAgendados(List<Treino> treinos) {
  final s = <int>{};
  for (final t in treinos) {
    s.addAll(t.dias);
  }
  return s;
}

/// Sequência ATUAL de dias agendados concluídos (a "corrente").
///
/// Regra (decidida): conta os dias em que há treino agendado; concluir mantém a
/// corrente. Um dia de descanso (sem treino agendado) NÃO quebra; um dia
/// agendado no passado sem conclusão quebra; hoje ainda pendente não quebra.
int streakAtual(List<Conclusao> concs, List<Treino> treinos, {DateTime? hoje}) {
  final hj = _dia(hoje ?? DateTime.now());
  final agendados = diasAgendados(treinos);
  final diasConc = concs.map((c) => _dia(c.data)).toSet();
  var streak = 0;
  var d = hj;
  for (var i = 0; i < 366; i++) {
    final wd = d.weekday - 1; // 0=seg..6=dom
    final concluiu = diasConc.contains(d);
    if (concluiu) {
      streak++;
    } else if (agendados.contains(wd) && d.isBefore(hj)) {
      break; // dia agendado no passado sem conclusão -> quebra a corrente
    }
    // rest day (não agendado) OU hoje ainda pendente -> neutro
    d = d.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Melhor sequência já alcançada (para as medalhas, que são permanentes).
int melhorStreak(List<Conclusao> concs, List<Treino> treinos) {
  final dias = concs.map((c) => _dia(c.data)).toSet().toList()..sort();
  var best = 0;
  for (final d in dias) {
    final s = streakAtual(concs, treinos, hoje: d);
    if (s > best) best = s;
  }
  return best;
}

/// Total de DIAS distintos com treino concluído.
int totalDiasConcluidos(List<Conclusao> concs) =>
    concs.map((c) => _dia(c.data)).toSet().length;

/// Exercícios (por nome, minúsculo) que têm progressão de recorde: pelo menos
/// dois registros e o maior supera o primeiro.
Set<String> exerciciosComRecorde(List<RegistroProgressao> progressao) {
  final grupos = agruparPorExercicio(progressao);
  return grupos
      .where((g) => g.registros.length >= 2 && g.maior > g.primeiro)
      .map((g) => g.exercicio.trim().toLowerCase())
      .where((n) => n.isNotEmpty)
      .toSet();
}

/// Exercícios distintos (por nome, minúsculo) presentes nos treinos.
Set<String> exerciciosDistintos(List<Treino> treinos) {
  final s = <String>{};
  for (final t in treinos) {
    for (final e in t.exercicios) {
      final n = e.nome.trim().toLowerCase();
      if (n.isNotEmpty) s.add(n);
    }
  }
  return s;
}

/// Quantos exercícios distintos precisam de recorde para o Troféu de Ouro
/// (metade, arredondando para cima). 0 se não há exercícios.
int exigenciaRecordeOuro(List<Treino> treinos) {
  final n = exerciciosDistintos(treinos).length;
  return n == 0 ? 0 : (n / 2).ceil();
}

/// Quantos exercícios distintos já têm recorde (o numerador do Troféu de Ouro).
int recordesParaOuro(
    List<Treino> treinos, List<RegistroProgressao> progressao) {
  final distintos = exerciciosDistintos(treinos);
  return exerciciosComRecorde(progressao).intersection(distintos).length;
}

/// Exercícios distintos (nos treinos) cujo RECORDE foi batido nos últimos [dias]
/// dias. Usado na regra "não progressão em N dias" da coroa (que faz o Troféu de
/// Ouro deixar de ser "conquista atual" se a evolução estagnar).
int recordesRecentes(
  List<Treino> treinos,
  List<RegistroProgressao> progressao, {
  int dias = 21,
  DateTime? hoje,
}) {
  final limite = (hoje ?? DateTime.now()).subtract(Duration(days: dias));
  final distintos = exerciciosDistintos(treinos);
  var n = 0;
  for (final g in agruparPorExercicio(progressao)) {
    final nome = g.exercicio.trim().toLowerCase();
    if (!distintos.contains(nome)) continue;
    if (g.registros.length < 2 || g.maior <= g.primeiro) continue;
    // A data em que o maior valor foi atingido (última ocorrência do maior).
    final dataDoMaior = g.registros
        .where((r) => r.valor == g.maior)
        .map((r) => r.data)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    if (dataDoMaior.isAfter(limite)) n++;
  }
  return n;
}

/// Conquistas ATUAIS (sustentadas AGORA). Diferente das obtidas (histórico
/// permanente): as medalhas caem quando a sequência quebra; o Troféu de Prata
/// (acúmulo) permanece; a Coroa cai se a progressão estagnar (>21 dias sem
/// recorde novo em >=50% dos exercícios).
Set<TipoConquista> conquistasAtuais(
  List<Conclusao> concs,
  List<Treino> treinos,
  List<RegistroProgressao> progressao, {
  DateTime? hoje,
}) {
  final atuais = <TipoConquista>{};
  final streak = streakAtual(concs, treinos, hoje: hoje);
  final total = totalDiasConcluidos(concs);
  if (streak >= 4) atuais.add(TipoConquista.medalhaPrata);
  if (streak >= 8) atuais.add(TipoConquista.medalhaOuro);
  if (total >= 15) atuais.add(TipoConquista.trofeuPrata);
  final necessarios = exigenciaRecordeOuro(treinos);
  if (total >= 21 &&
      necessarios > 0 &&
      recordesRecentes(treinos, progressao, hoje: hoje) >= necessarios) {
    atuais.add(TipoConquista.trofeuOuro);
  }
  return atuais;
}

/// Avalia quais conquistas estão satisfeitas AGORA (para registrar novas —
/// histórico permanente, usado no calendário e na celebração de fim de treino).
Set<TipoConquista> conquistasObtidas(
  List<Conclusao> concs,
  List<Treino> treinos,
  List<RegistroProgressao> progressao,
) {
  final obtidas = <TipoConquista>{};
  final melhor = melhorStreak(concs, treinos);
  final totalDias = totalDiasConcluidos(concs);
  if (melhor >= 4) obtidas.add(TipoConquista.medalhaPrata);
  if (melhor >= 8) obtidas.add(TipoConquista.medalhaOuro);
  if (totalDias >= 15) obtidas.add(TipoConquista.trofeuPrata);
  // Ouro (surpresa): 21 dias concluídos + recorde em >=50% (ceil) dos exercícios.
  final necessarios = exigenciaRecordeOuro(treinos);
  final temRecorde = recordesParaOuro(treinos, progressao);
  if (totalDias >= 21 && necessarios > 0 && temRecorde >= necessarios) {
    obtidas.add(TipoConquista.trofeuOuro);
  }
  return obtidas;
}
