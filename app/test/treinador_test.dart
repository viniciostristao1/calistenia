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
}
