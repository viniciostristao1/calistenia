import 'package:calistenia/models/conclusao.dart';
import 'package:calistenia/models/escudo.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/services/escudo_repository.dart';
import 'package:calistenia/util/gamificacao.dart';
import 'package:calistenia/util/insignias.dart';
import 'package:flutter_test/flutter_test.dart';

/// Treino agendado TODOS os dias -> cada dia conta para a corrente.
Treino _t7() => Treino(
  nome: 't',
  dias: const [0, 1, 2, 3, 4, 5, 6],
  exercicios: [Exercicio(nome: 'A')],
);

/// [n] dias completos terminando HOJE (k=0 = hoje), pulando os offsets em [pular].
List<Conclusao> _completos(DateTime hoje, int n, {Set<int> pular = const {}}) =>
    [
      for (var k = 0; k < n; k++)
        if (!pular.contains(k))
          Conclusao(
            data: hoje.subtract(Duration(days: k)),
            treinoId: 't',
            treino: 't',
          ),
    ];

void main() {
  final hoje = DateTime(2026, 6, 15);

  group('sorteio do escudo', () {
    test('candidatos = 13..26 sem o 20 (13 valores)', () {
      expect(candidatosEscudo, [
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        21,
        22,
        23,
        24,
        25,
        26,
      ]);
      expect(candidatosEscudo.contains(20), isFalse);
      expect(candidatosEscudo.length, 13);
    });

    test('alvoEscudo é determinístico e sempre cai num candidato', () {
      for (final semente in [0, 1, 123, 999999, 0x7fffffff]) {
        for (var d = 1; d <= 40; d++) {
          final alvo = alvoEscudo(semente, DateTime(2026, 3, d));
          expect(candidatosEscudo.contains(alvo), isTrue);
          // determinístico: mesma entrada, mesma saída
          expect(alvo, alvoEscudo(semente, DateTime(2026, 3, d)));
        }
      }
    });
  });

  group('sequência + escudo (dia coberto = completo)', () {
    test('15 dias seguidos = sequência 15', () {
      final c = _completos(hoje, 15);
      expect(sequenciaIninterrupta(c, [_t7()], hoje: hoje), 15);
    });

    test('uma falha quebra a corrente; o escudo a restaura', () {
      // Falta no dia -5 (k=5): a corrente para em 5.
      final c = _completos(hoje, 15, pular: {5});
      expect(sequenciaIninterrupta(c, [_t7()], hoje: hoje), 5);
      // Cobrindo o dia -5 com um escudo, a corrente volta a 15.
      final coberto = {hoje.subtract(const Duration(days: 5))};
      expect(
        sequenciaIninterrupta(c, [_t7()], hoje: hoje, diasEscudo: coberto),
        15,
      );
    });

    test('ultimaFaltaCobrivel aponta a quebra; some ao cobrir', () {
      final c = _completos(hoje, 15, pular: {5});
      final falta = ultimaFaltaCobrivel(c, [_t7()], hoje: hoje);
      expect(falta, hoje.subtract(const Duration(days: 5)));
      // Com ela coberta, não há mais falta a cobrir (resto tudo completo).
      final coberto = {hoje.subtract(const Duration(days: 5))};
      expect(
        ultimaFaltaCobrivel(c, [_t7()], hoje: hoje, diasEscudo: coberto),
        isNull,
      );
    });

    test('inicioSequenciaAtual = o 1º dia da corrente', () {
      final c = _completos(hoje, 15);
      expect(
        inicioSequenciaAtual(c, [_t7()], hoje: hoje),
        hoje.subtract(const Duration(days: 14)),
      );
    });
  });

  group('repositório / modelo', () {
    test('máx 1 guardado + usar gasta', () {
      final e = Escudo(ganhoEm: hoje);
      expect(e.usado, isFalse);
      expect(temEscudoDisponivel([e]), isTrue);
      final usado = e.copyUsando(hoje.subtract(const Duration(days: 5)));
      expect(usado.usado, isTrue);
      expect(temEscudoDisponivel([usado]), isFalse);
      expect(diasCobertosPorEscudo([usado]), {
        hoje.subtract(const Duration(days: 5)),
      });
      expect(diasEscudoGanho([e]), {hoje});
    });

    test('json ida e volta', () {
      final e = Escudo(
        ganhoEm: hoje,
        usadoEm: hoje.add(const Duration(days: 2)),
      );
      final j = Escudo.fromJson(e.toJson());
      expect(j.ganhoEm, e.ganhoEm);
      expect(j.usadoEm, e.usadoEm);
      expect(j.id, e.id);
    });
  });

  group('rating +20 por escudo do mês', () {
    test('escudo do mês soma +20; de outro mês não', () {
      final treinos = [_t7()];
      final concs = _completos(hoje, 10);
      final semEsc = ratingForma(concs, treinos, const [], hoje: hoje);
      final comEsc = ratingForma(
        concs,
        treinos,
        const [],
        hoje: hoje,
        diasEscudoGanho: {hoje},
      );
      expect(comEsc.bonusEscudos, 20);
      expect(comEsc.totalComBonus - semEsc.totalComBonus, 20);
      // Escudo de outro mês não entra no bônus do mês corrente.
      final outroMes = ratingForma(
        concs,
        treinos,
        const [],
        hoje: hoje,
        diasEscudoGanho: {DateTime(2026, 4, 10)},
      );
      expect(outroMes.bonusEscudos, 0);
    });
  });
}
