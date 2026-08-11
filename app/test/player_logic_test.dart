import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/fase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testes da LÓGICA do cronômetro (linha do tempo + "A seguir" + contador),
/// extraída para funções puras em `fase.dart`. Cobre em especial o caso que
/// travava na prática — muitas repetições × várias séries — como guarda de
/// regressão para essa classe de bug.
void main() {
  // Exercício que travava: 22 reps × 4 séries (ex.: Rosca direta / Flexão).
  Exercicio flexao22x4() => Exercicio(
        nome: 'Flexão declinada',
        preparacaoSeg: 10,
        execucaoSeg: 3,
        descansoSeg: 90,
        repeticoes: 22,
        series: 4,
      );

  group('linha do tempo 22×4 (o caso que travava)', () {
    test('estrutura: prep + 88 execuções + 3 descansos = 92 fases', () {
      final fases = montarLinhaDoTempoDe([flexao22x4()]);
      expect(fases.length, 92);
      expect(fases.first.tipo, FaseTipo.preparacao);
      expect(fases.where((f) => f.tipo == FaseTipo.execucao).length, 88);
      expect(fases.where((f) => f.tipo == FaseTipo.descanso).length, 3);
      // O descanso do fim absoluto é removido.
      expect(fases.last.tipo, FaseTipo.execucao);
    });

    test('contador 0-based nunca fica negativo (rep >= 1 em toda execução)', () {
      final fases = montarLinhaDoTempoDe([flexao22x4()]);
      for (final f in fases.where((f) => f.tipo == FaseTipo.execucao)) {
        expect(f.rep, greaterThanOrEqualTo(1)); // na tela: rep-1 >= 0
        expect(f.rep, lessThanOrEqualTo(f.totalReps));
      }
    });
  });

  group('proximaEtapaIdx: aponta a próxima ETAPA, não a próxima repetição', () {
    // idx 0 = prep; 1..22 = exec s1; 23 = descanso s1; 24.. = exec s2; ...
    final fases = montarLinhaDoTempoDe([flexao22x4()]);

    test('na preparação → aponta a execução', () {
      expect(fases[proximaEtapaIdx(fases, 0)].tipo, FaseTipo.execucao);
    });

    test('durante a execução → pula as reps restantes e aponta o descanso', () {
      for (final idx in [1, 10, 22]) {
        final j = proximaEtapaIdx(fases, idx);
        expect(fases[j].tipo, FaseTipo.descanso, reason: 'a partir de $idx');
        expect(fases[j].serie, 1);
      }
    });

    test('no descanso → aponta a execução da próxima série', () {
      final descanso1 = fases.indexWhere((f) => f.tipo == FaseTipo.descanso);
      final j = proximaEtapaIdx(fases, descanso1);
      expect(fases[j].tipo, FaseTipo.execucao);
      expect(fases[j].serie, 2);
    });

    test('última repetição do treino → -1 (fim); índices fora do limite = -1', () {
      expect(proximaEtapaIdx(fases, fases.length - 1), -1);
      expect(proximaEtapaIdx(fases, 999), -1);
      expect(proximaEtapaIdx(fases, -1), -1);
    });
  });

  group('descricaoEtapa: texto do "A seguir"', () {
    final fases = montarLinhaDoTempoDe([flexao22x4()]);

    test('execução mostra exercício + nº de reps', () {
      final exec = fases.firstWhere((f) => f.tipo == FaseTipo.execucao);
      expect(descricaoEtapa(exec), 'Flexão declinada · 22 reps');
    });

    test('descanso mostra o tempo', () {
      final desc = fases.firstWhere((f) => f.tipo == FaseTipo.descanso);
      expect(descricaoEtapa(desc), 'Descanso · 1min 30s');
    });

    test('isométrico (1 rep) mostra o tempo, não "1 reps"', () {
      final iso = montarLinhaDoTempoDe([
        Exercicio(
            nome: 'Prancha',
            preparacaoSeg: 0,
            execucaoSeg: 40,
            descansoSeg: 0,
            repeticoes: 1,
            series: 1),
      ]);
      final exec = iso.firstWhere((f) => f.tipo == FaseTipo.execucao);
      expect(descricaoEtapa(exec), 'Prancha · 40s');
    });

    test('unilateral: inclui "(lado N)" e a prep do lado 2 vira a próxima etapa',
        () {
      final fs = montarLinhaDoTempoDe([
        Exercicio(
            nome: 'Pistol',
            preparacaoSeg: 5,
            execucaoSeg: 2,
            descansoSeg: 30,
            repeticoes: 5,
            series: 2,
            unilateral: true),
      ]);
      final execL1 =
          fs.firstWhere((f) => f.tipo == FaseTipo.execucao && f.lado == 1);
      expect(descricaoEtapa(execL1), 'Pistol (lado 1) · 5 reps');
      // Durante o lado 1, a próxima etapa é a PREPARAÇÃO do lado 2.
      final prox = fs[proximaEtapaIdx(fs, fs.indexOf(execL1))];
      expect(prox.tipo, FaseTipo.preparacao);
      expect(prox.lado, 2);
    });
  });
}
