import 'package:calistenia/models/conclusao.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/registro_progressao.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/util/treinador.dart';
import 'package:flutter_test/flutter_test.dart';

Treino _t(List<String> ex) => Treino(
  nome: 't',
  dias: const [0, 1, 2, 3, 4, 5, 6],
  exercicios: [for (final n in ex) Exercicio(nome: n)],
);

void main() {
  final hoje = DateTime(2026, 6, 17); // quarta
  DateTime d(int k) => hoje.subtract(Duration(days: k));
  Conclusao c(DateTime data, {bool completo = true}) =>
      Conclusao(data: data, treinoId: 't', treino: 't', completo: completo);
  RegistroProgressao r(String ex, int v, DateTime data, {double peso = 0}) =>
      RegistroProgressao(exercicio: ex, valor: v, peso: peso, data: data);

  // 3 dias esta semana (qua/ter/seg) + 2 na semana passada.
  final concs = [c(d(0)), c(d(1)), c(d(2)), c(d(7)), c(d(8))];
  final checkins = concs.map((e) => e.data).toList();

  test('placar da semana: completos, delta, sequência', () {
    final res = montarResumo(
      concs,
      [
        _t(['flexao']),
      ],
      const [],
      checkins,
      hoje: hoje,
    );
    expect(res.completos, 3);
    expect(res.completosAnterior, 2);
    expect(res.deltaCompletos, 1);
    expect(res.sequencia, 3);
    expect(res.insights, isNotEmpty);
  });

  test('platô: exercício ativo há >10 dias sem recorde vira dica', () {
    final prog = [r('flexao', 8, d(30)), r('flexao', 10, d(20))];
    final res = montarResumo(
      concs,
      [
        _t(['flexao']),
      ],
      prog,
      checkins,
      hoje: hoje,
    );
    expect(res.insights.any((i) => i.titulo.contains('Platô')), isTrue);
    expect(
      res.insights.firstWhere((i) => i.titulo.contains('Platô')).acao,
      InsightAcao.progressao,
    );
  });

  test('recorde recente (<=7 dias) entra no placar', () {
    final prog = [r('flexao', 10, d(10)), r('flexao', 15, d(2))];
    final res = montarResumo(
      concs,
      [
        _t(['flexao']),
      ],
      prog,
      checkins,
      hoje: hoje,
    );
    expect(res.recordesRecentes.any((s) => s.contains('15 reps')), isTrue);
  });

  test('sempre há ao menos 1 dica (fallback de boas-vindas)', () {
    final res = montarResumo(
      const [],
      [
        _t(['flexao']),
      ],
      const [],
      const [],
      hoje: hoje,
    );
    expect(res.insights, isNotEmpty);
  });

  test('"Completos" conta SESSÕES (2 no mesmo dia = 2)', () {
    final cc = [c(d(0)), c(d(0)), c(d(2))]; // 2 hoje + 1 segunda
    final ck = [d(0), d(2)];
    final res = montarResumo(
      cc,
      [
        _t(['flexao']),
      ],
      const [],
      ck,
      hoje: hoje,
    );
    expect(res.completos, 3);
  });

  test('risco de hoje: dia agendado, não concluído, com chama → dica', () {
    final cc = [c(d(1)), c(d(2))]; // ontem e anteontem completos; HOJE não
    final ck = [d(1), d(2)];
    final res = montarResumo(
      cc,
      [
        _t(['flexao']),
      ],
      const [],
      ck,
      hoje: hoje,
    );
    expect(res.sequencia, 2);
    final risco = res.insights.first;
    expect(risco.titulo.toLowerCase().contains('risco'), isTrue);
    expect(risco.acao, InsightAcao.treinos);
  });

  test('sem risco quando o treino de hoje já foi concluído', () {
    final res = montarResumo(
      concs,
      [
        _t(['flexao']),
      ],
      const [],
      checkins,
      hoje: hoje,
    );
    expect(
      res.insights.any((i) => i.titulo.toLowerCase().contains('risco')),
      isFalse,
    );
  });

  test('risco com escudo guardado menciona a reserva', () {
    final cc = [c(d(1)), c(d(2))]; // hoje não concluído, chama de 2
    final ck = [d(1), d(2)];
    final res = montarResumo(
      cc,
      [
        _t(['flexao']),
      ],
      const [],
      ck,
      hoje: hoje,
      temEscudoReserva: true,
    );
    expect(res.insights.first.texto.contains('escudo de reserva'), isTrue);
  });

  test('gargalo do Rating: sem progressão, aponta a progressão', () {
    // treinou dias (consistência/frequência > 0), mas nenhum recorde (prog=0).
    final res = montarResumo(
      concs,
      [
        _t(['flexao']),
      ],
      const [],
      checkins,
      hoje: hoje,
    );
    expect(
      res.insights.any((i) => i.titulo.toLowerCase().contains('progress')),
      isTrue,
    );
  });

  test('exercício fora dos treinos não gera platô', () {
    final prog = [r('remada', 8, d(30)), r('remada', 10, d(20))];
    final res = montarResumo(
      concs,
      [
        _t(['flexao']),
      ],
      prog,
      checkins,
      hoje: hoje,
    );
    expect(res.insights.any((i) => i.titulo.contains('Platô')), isFalse);
  });

  test('micro-gráfico: 8 semanas, última célula = completos da semana', () {
    final res = montarResumo(concs, [
      _t(['flexao']),
    ], const [], checkins, hoje: hoje);
    expect(res.completosPorSemana.length, 8);
    expect(res.completosPorSemana.last, res.completos);
  });

  test('frase-resumo: não vazia e cita os treinos da semana', () {
    final res = montarResumo(concs, [
      _t(['flexao']),
    ], const [], checkins, hoje: hoje);
    expect(res.frase, isNotEmpty);
    expect(res.frase.contains('3 treinos'), isTrue);
  });

  test('exercício em alta (14 dias): maior ganho de reps', () {
    final prog = [r('flexao', 10, d(10)), r('flexao', 15, d(2))];
    final res = montarResumo(concs, [
      _t(['flexao']),
    ], prog, checkins, hoje: hoje);
    expect(res.temAlta, isTrue);
    expect(res.altaNome, 'flexao');
    expect(res.altaDe, 10);
    expect(res.altaPara, 15);
    expect(res.altaPct, 50);
  });

  test('exercício em alta ignora ganho FORA da janela de 14 dias', () {
    final prog = [r('flexao', 8, d(30)), r('flexao', 20, d(20))];
    final res = montarResumo(concs, [
      _t(['flexao']),
    ], prog, checkins, hoje: hoje);
    expect(res.temAlta, isFalse);
  });

  test('projeção: no ritmo recente estima dias até a próxima conquista', () {
    final res = montarResumo(concs, [
      _t(['flexao']),
    ], const [], checkins, hoje: hoje);
    expect(res.temProjecao, isTrue);
    expect(res.projDias, greaterThan(0));
    expect(res.projRotulo, isNotEmpty);
  });

  test('ranking pessoal: melhor semana do ano fica em 1º', () {
    final cs = [
      c(d(0)), c(d(1)), c(d(2)), // semana atual: 3
      c(d(7)), c(d(8)), // semana passada: 2
      c(d(14)), // 2 semanas atrás: 1
    ];
    final res = montarResumo(cs, [
      _t(['flexao']),
    ], const [], cs.map((e) => e.data).toList(), hoje: hoje);
    expect(res.temRanking, isTrue);
    expect(res.rankingPos, 1);
    expect(res.rankingTotal, 3);
  });
}
