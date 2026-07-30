import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/fase.dart';
import 'package:calistenia/models/treino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('linha do tempo: prep + (execução×reps) por série, descanso entre séries',
      () {
    final t = Treino(
      nome: 'Teste',
      exercicios: [
        Exercicio(
          nome: 'Flexão',
          preparacaoSeg: 10,
          execucaoSeg: 3, // por repetição
          descansoSeg: 60, // entre séries
          repeticoes: 10,
          series: 3,
        ),
      ],
    );
    final fases = montarLinhaDoTempo(t);
    // prep(1) + [10 execuções + 1 descanso]×3, menos o descanso final = 1+33-1 = 33.
    expect(fases.length, 33);
    expect(fases.first.tipo, FaseTipo.preparacao);
    expect(fases.last.tipo, FaseTipo.execucao);
    expect(fases.where((f) => f.tipo == FaseTipo.execucao).length, 30);
    expect(fases.where((f) => f.tipo == FaseTipo.descanso).length, 2);
    // A execução carrega série e repetição corretas.
    final exec = fases.where((f) => f.tipo == FaseTipo.execucao).toList();
    expect(exec.first.serie, 1);
    expect(exec.first.rep, 1);
    expect(exec.last.serie, 3);
    expect(exec.last.rep, 10);
  });

  test('isométrico (repetições 1) = uma execução por série', () {
    final t = Treino(
      nome: 'Teste',
      exercicios: [
        Exercicio(
          nome: 'Prancha',
          preparacaoSeg: 0,
          execucaoSeg: 45,
          descansoSeg: 0,
          repeticoes: 1,
          series: 2,
        ),
      ],
    );
    final fases = montarLinhaDoTempo(t);
    expect(fases.length, 2);
    expect(fases.every((f) => f.tipo == FaseTipo.execucao), isTrue);
  });

  test('duração total soma todas as etapas', () {
    final t = Treino(
      nome: 'Teste',
      exercicios: [
        Exercicio(
          nome: 'A',
          preparacaoSeg: 10,
          execucaoSeg: 3,
          descansoSeg: 60,
          repeticoes: 10,
          series: 3,
        ),
      ],
    );
    // 10 + (3*10 + 60)*3 = 10 + 90*3 = 280
    expect(t.duracaoTotalSeg, 280);
  });

  test('migração do formato antigo: repetições antigas viram séries', () {
    // JSON v0.1.0 (sem "series"): "repeticoes" era o nº de rodadas.
    final e = Exercicio.fromJson({
      'id': 'x',
      'nome': 'Flexão',
      'preparacaoSeg': 10,
      'execucaoSeg': 30,
      'descansoSeg': 20,
      'repeticoes': 3,
    });
    expect(e.series, 3); // as 3 rodadas viram 3 séries
    expect(e.repeticoes, 1); // uma "execução" por série (comportamento antigo)
    expect(e.execucaoSeg, 30);
  });
}
