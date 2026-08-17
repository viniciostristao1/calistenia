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
/// sequência crua: +1 por dia concluído; falhas gastam um "orçamento" e, ao
/// estourá-lo, cai UM degrau de prêmio (perda escalonada), não zera.
class NivelInfo {
  final int atual;
  final int recorde;
  const NivelInfo(this.atual, this.recorde);
}

/// Orçamento de falhas por corrente. Um dia CONCLUÍDO ("consegui") zera o
/// orçamento; uma TENTATIVA ("não consegui") gasta 1; FALTAR (dia agendado sem
/// registro) gasta 2. Ao gasto PASSAR de [_orcamentoFalhas], cai um degrau e o
/// orçamento zera. Assim: "não consegui" 2 dias ok / 3º quebra; faltar 1 dia ok
/// / 2º quebra (falta pesa o dobro).
const int _orcamentoFalhas = 2;

NivelInfo nivelInfo(List<Conclusao> concs, List<Treino> treinos,
    {DateTime? hoje}) {
  final hj = _dia(hoje ?? DateTime.now());
  final agendados = diasAgendados(treinos);
  // Por dia: houve alguma conclusão COMPLETA? (completo vence tentativa no dia)
  final completoPorDia = <DateTime, bool>{};
  for (final c in concs) {
    final d = _dia(c.data);
    completoPorDia[d] = (completoPorDia[d] ?? false) || c.completo;
  }
  if (completoPorDia.isEmpty) return const NivelInfo(0, 0);
  final inicio =
      completoPorDia.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  var nivel = 0, recorde = 0, gasto = 0, i = 0;
  var d = inicio;
  while (!d.isAfter(hj) && i < 4000) {
    final wd = d.weekday - 1;
    final registro = completoPorDia[d];
    if (registro == true) {
      // Concluiu de verdade: avança e zera o orçamento de falhas.
      nivel += 1;
      gasto = 0;
      if (nivel > recorde) recorde = nivel;
    } else if (registro == false && agendados.contains(wd)) {
      // "Não consegui" num dia agendado: falha leve (custa 1).
      gasto += 1;
      if (gasto > _orcamentoFalhas) {
        nivel = _dropTier(nivel);
        gasto = 0;
      }
    } else if (registro == null && agendados.contains(wd) && d.isBefore(hj)) {
      // Faltou num dia agendado já passado: falha pesada (custa 2).
      gasto += 2;
      if (gasto > _orcamentoFalhas) {
        nivel = _dropTier(nivel);
        gasto = 0;
      }
    }
    // Descanso (não agendado), tentativa fora de dia agendado, ou hoje ainda
    // pendente (sem registro) -> neutro.
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
/// (não derruba a nota de manhã num dia agendado). Peso por dia: completou = 1,0;
/// só tentou ("não consegui") = 0,5. O componente é limitado ao teto de 40.
///
/// v0.48.0: a INSÍGNIA SAIU daqui — não pesa mais na consistência. Dentro do teto
/// ela era diluída (quem já estava em 40/40 não ganhava nada) e podia "comprar"
/// faltas. Virou um bônus separado, fora dos 100 (ver [_bonusEstrelas]).
int _consistencia(List<Conclusao> concs, List<Treino> treinos, DateTime hj) {
  final agendados = diasAgendados(treinos);
  if (agendados.isEmpty) return 0;
  final pesoDia = <DateTime, double>{};
  for (final c in concs) {
    final d = _dia(c.data);
    final p = c.completo ? 1.0 : 0.5;
    if (p > (pesoDia[d] ?? 0)) pesoDia[d] = p;
  }
  var total = 0;
  var feitos = 0.0;
  for (var k = 0; k < 28; k++) {
    final d = hj.subtract(Duration(days: k));
    if (!agendados.contains(d.weekday - 1)) continue;
    final peso = pesoDia[d] ?? 0.0;
    if (k == 0 && peso == 0) continue; // hoje pendente = neutro
    total++;
    feitos += peso;
  }
  return total == 0 ? 0 : ((feitos / total) * 40).round().clamp(0, 40);
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

/// Bônus de estrelas (0..7): EXTRA fora dos 100, LINEAR — cada insígnia ganha no
/// MÊS-CALENDÁRIO corrente vale +1. Prêmio limpo: não dilui a consistência nem
/// mascara faltas (só quem CONCLUIU dias sorteados soma). Capado em 7 (limite/mês).
/// Reseta no dia 1º de cada mês (bate com o quadro de estrelas do Check-in).
int _bonusEstrelas(Set<DateTime> diasInsignia, DateTime hj) {
  var n = 0;
  for (final d in diasInsignia) {
    if (d.year == hj.year && d.month == hj.month) n++;
  }
  return n.clamp(0, 7);
}

/// Rating de forma = Consistência (40) + Frequência (20) + Progressão (40) =
/// base 0..100, MAIS o bônus de estrelas (0..7) como EXTRA fora do teto. Número
/// único "nota de desempenho": consistência é o alicerce, mas só bater recordes
/// (progressão) leva além do platô. Quem não evolui fica estável, não despenca.
class RatingForma {
  final int consistencia; // 0..40
  final int frequencia; // 0..20
  final int progressao; // 0..40
  final int bonusEstrelas; // 0..7 — EXTRA de insígnias do mês, fora dos 100
  const RatingForma(this.consistencia, this.frequencia, this.progressao,
      [this.bonusEstrelas = 0]);

  /// Nota-base "de forma" (0..100): consistência + frequência + progressão.
  int get total => consistencia + frequencia + progressao;

  /// Nota com o bônus de estrelas somado (pode passar de 100 — é o extra).
  int get totalComBonus => total + bonusEstrelas;

  static const int maximo = 100;
}

RatingForma ratingForma(List<Conclusao> concs, List<Treino> treinos,
    List<RegistroProgressao> progressao,
    {DateTime? hoje, Set<DateTime> diasInsignia = const {}}) {
  final hj = _dia(hoje ?? DateTime.now());
  return RatingForma(
    _consistencia(concs, treinos, hj),
    _frequencia(concs, hj),
    _progressao(treinos, progressao, hj, 42),
    _bonusEstrelas(diasInsignia, hj),
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
  Set<DateTime> diasInsignia = const {},
}) {
  final hj = _dia(hoje ?? DateTime.now());
  final pts = <PontoRating>[];
  for (var w = semanas - 1; w >= 0; w--) {
    final data = hj.subtract(Duration(days: w * 7));
    final concsAte = concs.where((c) => !c.data.isAfter(data)).toList();
    final progAte = progressao.where((r) => !r.data.isAfter(data)).toList();
    final insigAte =
        diasInsignia.where((d) => !d.isAfter(data)).toSet();
    pts.add(PontoRating(
        data,
        ratingForma(concsAte, treinos, progAte,
                hoje: data, diasInsignia: insigAte)
            .totalComBonus));
  }
  return pts;
}
