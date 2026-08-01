import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/fase.dart';
import 'package:calistenia/models/registro_progressao.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/services/progressao_repository.dart';
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

  test('descanso variável por série entra na linha do tempo', () {
    final t = Treino(
      nome: 'Teste',
      exercicios: [
        Exercicio(
          nome: 'Flexão',
          preparacaoSeg: 0,
          execucaoSeg: 45,
          repeticoes: 1,
          series: 3,
          descansos: [60, 90, 120], // após série 1, 2 e 3 (a 3ª some no fim)
        ),
      ],
    );
    final fases = montarLinhaDoTempo(t);
    final descansos =
        fases.where((f) => f.tipo == FaseTipo.descanso).toList();
    // exec, desc60, exec, desc90, exec (desc120 final removido).
    expect(descansos.length, 2);
    expect(descansos[0].segundos, 60);
    expect(descansos[1].segundos, 90);
    // 45*3 + 60 + 90 = 285
    expect(t.duracaoTotalSeg, 45 * 3 + 60 + 90 + 120);
  });

  test('execução removida (0) some da linha do tempo', () {
    final t = Treino(
      nome: 'Teste',
      exercicios: [
        Exercicio(
          nome: 'Só descanso',
          preparacaoSeg: 10,
          execucaoSeg: 0, // sem execução
          descansoSeg: 0,
          repeticoes: 5,
          series: 2,
        ),
      ],
    );
    final fases = montarLinhaDoTempo(t);
    expect(fases.length, 1);
    expect(fases.first.tipo, FaseTipo.preparacao);
  });

  test('progressão agrupa por exercício e resume a evolução', () {
    final regs = [
      RegistroProgressao(
          exercicio: 'Flexão', valor: 10, data: DateTime(2026, 7, 1)),
      RegistroProgressao(
          exercicio: 'Flexão', valor: 15, data: DateTime(2026, 7, 20)),
      RegistroProgressao(
          exercicio: 'Agachamento', valor: 20, data: DateTime(2026, 7, 10)),
    ];
    final grupos = agruparPorExercicio(regs);
    expect(grupos.length, 2);
    // ordenado pela última data (desc): Flexão (20/07) antes de Agachamento.
    expect(grupos.first.exercicio, 'Flexão');
    expect(grupos.first.primeiro, 10); // registro mais antigo
    expect(grupos.first.ultimo, 15); // registro mais recente
    expect(grupos.first.maior, 15);
  });

  test('peso e cor: resumo inclui peso, JSON round-trip e migração', () {
    final e = Exercicio(
      nome: 'Rosca',
      execucaoSeg: 3,
      repeticoes: 10,
      series: 3,
      pesoKg: 12.5,
      corIndex: 4,
    );
    expect(e.resumoCurto.contains('12,5kg'), isTrue);
    final back = Exercicio.fromJson(e.toJson());
    expect(back.pesoKg, 12.5);
    expect(back.corIndex, 4);
    // Exercício antigo (sem peso/cor) migra para 0.
    final antigo = Exercicio.fromJson(
        {'nome': 'X', 'execucaoSeg': 30, 'repeticoes': 3, 'series': 1});
    expect(antigo.pesoKg, 0);
    expect(antigo.corIndex, 0);
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
