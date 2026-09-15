import 'package:calistenia/models/conclusao.dart';
import 'package:calistenia/models/conquista.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/util/gamificacao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('marcoSequencia: só 10/20/30… contam', () {
    expect(marcoSequencia(0), 0);
    expect(marcoSequencia(9), 0);
    expect(marcoSequencia(10), 10);
    expect(marcoSequencia(19), 0);
    expect(marcoSequencia(20), 20);
    expect(marcoSequencia(21), 0); // 21 é tier (troféu), não marco redondo
    expect(marcoSequencia(30), 30);
  });

  test('recompensasDoDia: conquista e marco saem antes; estrela por último', () {
    // Conquista sozinha.
    final soConquista = recompensasDoDia(
      novasConquistas: const [TipoConquista.medalhaOuro],
      streak: 8,
      ratingGanho: 12,
    );
    expect(soConquista.length, 1);
    expect(soConquista.first.tipo, PremioTipo.conquista);

    // Marco redondo sozinho.
    final soMarco = recompensasDoDia(streak: 10, ratingGanho: 9);
    expect(soMarco.length, 1);
    expect(soMarco.first.tipo, PremioTipo.sequencia);
    expect(soMarco.first.valor, 10);

    // Estrela + conquista → conquista primeiro, estrela por último.
    final duplo = recompensasDoDia(
      novasConquistas: const [TipoConquista.trofeuPrata],
      streak: 15,
      ganhouEstrela: true,
      ratingGanho: 30,
    );
    expect(duplo.length, 2);
    expect(duplo.first.tipo, PremioTipo.conquista);
    expect(duplo.last.tipo, PremioTipo.estrela);

    // Dia comum com ganho: só o rating (setas).
    final comum = recompensasDoDia(ratingGanho: 15);
    expect(comum.length, 1);
    expect(comum.first.tipo, PremioTipo.rating);
    expect(comum.first.valor, 15);

    // Dia comum sem ganho: nada.
    expect(recompensasDoDia(ratingGanho: 0), isEmpty);
  });

  test('ratingDoDia: ganho do dia é positivo ao concluir', () {
    final d = DateTime(2026, 9, 15);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [Exercicio(nome: 'A')]),
    ];
    // Metade dos dias agendados concluídos (fora hoje).
    final concs = [
      for (var i = 1; i <= 14; i++)
        Conclusao(data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
    ];
    final antes = ratingDoDia(concs, treinos, const [], hoje: d);
    expect(antes, 0); // nada mudou ainda hoje
    final depois = ratingDoDia(
      [...concs, Conclusao(data: d, treinoId: 't', treino: 't')],
      treinos,
      const [],
      hoje: d,
    );
    expect(depois, greaterThan(0)); // concluir hoje soma consistência
  });
}
