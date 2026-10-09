import 'package:calistenia/models/conclusao.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/registro_progressao.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/util/extrato_rating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoje = DateTime(2026, 6, 17);
  DateTime d(int k) => hoje.subtract(Duration(days: k));
  Treino treinoTodosDias() => Treino(
    nome: 't',
    dias: const [0, 1, 2, 3, 4, 5, 6],
    exercicios: [Exercicio(nome: 'flexao')],
  );
  Conclusao c(DateTime data) =>
      Conclusao(data: data, treinoId: 't', treino: 't', completo: true);

  test('extrato: treino concluído soma pontos; insígnia +10, escudo +20', () {
    final extrato = extratoRating(
      [c(d(1)), c(d(3))],
      [treinoTodosDias()],
      const [],
      diasInsignia: {d(2)},
      diasEscudo: {d(4)},
      hoje: hoje,
    );
    expect(extrato, isNotEmpty);
    // ordenado do mais recente para o mais antigo
    for (var i = 1; i < extrato.length; i++) {
      expect(!extrato[i - 1].data.isBefore(extrato[i].data), isTrue);
    }
    final treino = extrato.firstWhere((e) => e.motivo == 'Treino concluído');
    expect(treino.pontos, greaterThan(0));
    expect(extrato.firstWhere((e) => e.motivo == 'Insígnia').pontos, 10);
    expect(extrato.firstWhere((e) => e.motivo == 'Escudo').pontos, 20);
  });

  test('extrato: dia com recorde vira "Recorde · <nome>"', () {
    final prog = [
      RegistroProgressao(exercicio: 'flexao', valor: 10, peso: 0, data: d(5)),
      RegistroProgressao(exercicio: 'flexao', valor: 18, peso: 0, data: d(2)),
    ];
    final extrato = extratoRating(
      [c(d(2))],
      [treinoTodosDias()],
      prog,
      hoje: hoje,
    );
    expect(
      extrato.any(
        (e) => e.motivo.startsWith('Recorde') && e.motivo.contains('flexao'),
      ),
      isTrue,
    );
  });

  test('extrato: no máximo `max` itens', () {
    final concs = [for (var k = 1; k <= 20; k++) c(d(k))];
    final extrato = extratoRating(
      concs,
      [treinoTodosDias()],
      const [],
      hoje: hoje,
      max: 10,
    );
    expect(extrato.length, lessThanOrEqualTo(10));
  });

  test('ganhoSeTreinarHoje: >0 se hoje pendente; 0 se já concluiu', () {
    final concs = [c(d(2)), c(d(4))]; // não treinou hoje
    expect(
      ganhoSeTreinarHoje(concs, [treinoTodosDias()], const [], hoje: hoje),
      greaterThan(0),
    );
    final comHoje = [...concs, c(d(0))];
    expect(
      ganhoSeTreinarHoje(comHoje, [treinoTodosDias()], const [], hoje: hoje),
      0,
    );
  });
}
