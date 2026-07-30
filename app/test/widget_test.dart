import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/fase.dart';
import 'package:calistenia/models/treino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('linha do tempo expande preparação + execução×reps + descanso', () {
    final t = Treino(
      nome: 'Teste',
      exercicios: [
        Exercicio(
            nome: 'A',
            preparacaoSeg: 10,
            execucaoSeg: 30,
            descansoSeg: 15,
            repeticoes: 3),
      ],
    );
    final fases = montarLinhaDoTempo(t);
    // prep + (exec + desc)×3, sem o descanso final => 6 fases.
    expect(fases.length, 6);
    expect(fases.first.tipo, FaseTipo.preparacao);
    expect(fases.last.tipo, FaseTipo.execucao);
    expect(fases.where((f) => f.tipo == FaseTipo.execucao).length, 3);
    expect(fases.where((f) => f.tipo == FaseTipo.descanso).length, 2);
  });

  test('tempos em 0 são pulados (sem preparação, sem descanso)', () {
    final t = Treino(
      nome: 'Teste',
      exercicios: [
        Exercicio(
            nome: 'A',
            preparacaoSeg: 0,
            execucaoSeg: 45,
            descansoSeg: 0,
            repeticoes: 2),
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
            execucaoSeg: 30,
            descansoSeg: 15,
            repeticoes: 3),
      ],
    );
    // 10 + (30+15)*3 = 145
    expect(t.duracaoTotalSeg, 145);
  });
}
