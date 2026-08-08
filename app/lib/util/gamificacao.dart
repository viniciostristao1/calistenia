import 'dart:math' show max;

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

/// Limiares dos prêmios (dias de sequência): 🥈4 · 🥇8 · 🏆Prata15 · 🏆Ouro21.
const tiersPremios = <int>[4, 8, 15, 21];

/// Ao pular um dia agendado, o nível cai para o degrau do prêmio ANTERIOR
/// (perde só o último prêmio), não para 0. Ex.: 8→4, 15→8, 21→15, 4→0.
int _dropTier(int nivel) {
  var h = -1;
  for (var i = 0; i < tiersPremios.length; i++) {
    if (nivel >= tiersPremios[i]) h = i;
  }
  if (h <= 0) return 0;
  return tiersPremios[h - 1];
}

/// Nível atual (o que dá prêmio) + recorde de todos os tempos. Diferente de uma
/// sequência crua: +1 por dia agendado concluído; ao pular um dia agendado, cai
/// UM degrau de prêmio (perda escalonada), não zera.
class NivelInfo {
  final int atual;
  final int recorde;
  const NivelInfo(this.atual, this.recorde);
}

NivelInfo nivelInfo(List<Conclusao> concs, List<Treino> treinos,
    {DateTime? hoje}) {
  final hj = _dia(hoje ?? DateTime.now());
  final agendados = diasAgendados(treinos);
  final diasConc = concs.map((c) => _dia(c.data)).toSet();
  if (diasConc.isEmpty) return const NivelInfo(0, 0);
  final inicio = diasConc.reduce((a, b) => a.isBefore(b) ? a : b);
  var nivel = 0, recorde = 0, i = 0;
  var d = inicio;
  while (!d.isAfter(hj) && i < 4000) {
    final wd = d.weekday - 1;
    if (diasConc.contains(d)) {
      nivel += 1;
      if (nivel > recorde) recorde = nivel;
    } else if (agendados.contains(wd) && d.isBefore(hj)) {
      nivel = _dropTier(nivel); // pulou um dia agendado -> cai um degrau
    }
    // dia de descanso (não agendado) ou hoje ainda pendente -> sem mudança
    d = d.add(const Duration(days: 1));
    i++;
  }
  return NivelInfo(nivel, recorde);
}

/// Total de DIAS distintos com treino concluído.
int totalDiasConcluidos(List<Conclusao> concs) =>
    concs.map((c) => _dia(c.data)).toSet().length;

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

/// Exercícios distintos (nos treinos) cujo RECORDE foi batido nos últimos [dias]
/// dias. Usado na regra "não progressão em N dias" do Troféu de Ouro (que deixa
/// de ser "conquista atual" se a evolução estagnar).
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

/// Limiar de sequência (dias agendados seguidos) de cada conquista de sequência.
int limiarSequencia(TipoConquista t) => switch (t) {
      TipoConquista.medalhaPrata => 4,
      TipoConquista.medalhaOuro => 8,
      TipoConquista.trofeuPrata => 15,
      TipoConquista.trofeuOuro => 21,
    };

/// Conquistas ATUAIS (sustentadas AGORA). Tudo é por SEQUÊNCIA de dias agendados
/// (consecutivos): 🥈4 · 🥇8 · 🏆Prata15 · 🏆Ouro21. Se pular um dia agendado, a
/// sequência quebra e TODAS caem. O Ouro exige ainda progressão em >=50% dos
/// exercícios nos últimos 21 dias — cai também se a evolução estagnar.
Set<TipoConquista> conquistasAtuais(
  List<Conclusao> concs,
  List<Treino> treinos,
  List<RegistroProgressao> progressao, {
  DateTime? hoje,
}) {
  final atuais = <TipoConquista>{};
  final nivel = nivelInfo(concs, treinos, hoje: hoje).atual;
  if (nivel >= 4) atuais.add(TipoConquista.medalhaPrata);
  if (nivel >= 8) atuais.add(TipoConquista.medalhaOuro);
  if (nivel >= 15) atuais.add(TipoConquista.trofeuPrata);
  final necessarios = exigenciaRecordeOuro(treinos);
  if (nivel >= 21 &&
      necessarios > 0 &&
      recordesRecentes(treinos, progressao, hoje: hoje) >= necessarios) {
    atuais.add(TipoConquista.trofeuOuro);
  }
  return atuais;
}

/// Consistência (0..40): % dos dias AGENDADOS cumpridos nos últimos 28 dias,
/// ×0,4. Hoje é NEUTRO — não entra no denominador enquanto você não treinar
/// (não derruba a nota de manhã num dia agendado).
int _consistencia(List<Conclusao> concs, List<Treino> treinos, DateTime hj) {
  final agendados = diasAgendados(treinos);
  if (agendados.isEmpty) return 0;
  final diasConc = concs.map((c) => _dia(c.data)).toSet();
  var total = 0, feitos = 0;
  for (var k = 0; k < 28; k++) {
    final d = hj.subtract(Duration(days: k));
    if (!agendados.contains(d.weekday - 1)) continue;
    final fez = diasConc.contains(d);
    if (k == 0 && !fez) continue; // hoje pendente = neutro
    total++;
    if (fez) feitos++;
  }
  return total == 0 ? 0 : ((feitos / total) * 40).round();
}

/// Frequência (0..20): volume real — média de dias treinados por semana nas
/// últimas 4 semanas, com teto em ~5/semana. Só SOMA (não pune quem treina menos).
int _frequencia(List<Conclusao> concs, DateTime hj) {
  final diasConc = concs.map((c) => _dia(c.data)).toSet();
  var feitos = 0;
  for (var k = 0; k < 28; k++) {
    if (diasConc.contains(hj.subtract(Duration(days: k)))) feitos++;
  }
  final porSemana = feitos / 4.0;
  return ((porSemana / 5).clamp(0.0, 1.0) * 20).round();
}

/// Progressão (0..40): melhora REAL do recorde de cada exercício na janela de
/// [dias] (recorde agora vs. início da janela), fração capada em 100%/exercício;
/// soma com retorno decrescente 40·soma/(soma+2).
int _progressao(List<Treino> treinos, List<RegistroProgressao> progressao,
    DateTime hj, int dias) {
  final distintos = exerciciosDistintos(treinos);
  final corte = hj.subtract(Duration(days: dias));
  var soma = 0.0;
  for (final g in agruparPorExercicio(progressao)) {
    if (!distintos.contains(g.exercicio.trim().toLowerCase())) continue;
    final antes =
        g.registros.where((r) => r.data.isBefore(corte)).map((r) => r.valor);
    final base = antes.isEmpty ? g.primeiro : antes.reduce(max);
    if (base <= 0) continue;
    soma += ((g.maior - base) / base).clamp(0.0, 1.0);
  }
  return (40 * (soma / (soma + 2))).round();
}

/// Rating de forma (0..100) = Consistência (40) + Frequência (20) + Progressão
/// (40). Número único "nota de desempenho": consistência é o alicerce, mas só
/// bater recordes (progressão) leva além do platô. Quem não evolui fica estável,
/// não despenca.
class RatingForma {
  final int consistencia; // 0..40
  final int frequencia; // 0..20
  final int progressao; // 0..40
  const RatingForma(this.consistencia, this.frequencia, this.progressao);
  int get total => consistencia + frequencia + progressao;
  static const int maximo = 100;
}

RatingForma ratingForma(List<Conclusao> concs, List<Treino> treinos,
    List<RegistroProgressao> progressao,
    {DateTime? hoje}) {
  final hj = _dia(hoje ?? DateTime.now());
  return RatingForma(
    _consistencia(concs, treinos, hj),
    _frequencia(concs, hj),
    _progressao(treinos, progressao, hj, 42),
  );
}

/// Um ponto do gráfico de tendência do Rating (data + valor total).
class PontoRating {
  final DateTime data;
  final int valor;
  const PontoRating(this.data, this.valor);
}

/// Série (semanal) do Rating ao longo do tempo, para o gráfico de linha. Para
/// cada data passada, recalcula o rating usando SÓ os dados até aquela data
/// (sem "olhar o futuro").
List<PontoRating> serieRating(
  List<Conclusao> concs,
  List<Treino> treinos,
  List<RegistroProgressao> progressao, {
  int semanas = 12,
  DateTime? hoje,
}) {
  final hj = _dia(hoje ?? DateTime.now());
  final pts = <PontoRating>[];
  for (var w = semanas - 1; w >= 0; w--) {
    final data = hj.subtract(Duration(days: w * 7));
    final concsAte = concs.where((c) => !c.data.isAfter(data)).toList();
    final progAte = progressao.where((r) => !r.data.isAfter(data)).toList();
    pts.add(PontoRating(
        data, ratingForma(concsAte, treinos, progAte, hoje: data).total));
  }
  return pts;
}
