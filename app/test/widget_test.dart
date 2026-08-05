import 'package:calistenia/models/checkin.dart';
import 'package:calistenia/models/conclusao.dart';
import 'package:calistenia/models/conquista.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/fase.dart';
import 'package:calistenia/models/registro_progressao.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/services/checkin_repository.dart';
import 'package:calistenia/services/progressao_repository.dart';
import 'package:calistenia/util/gamificacao.dart';
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

  test('check-in: normaliza data ao dia, round-trip e filtro por dia', () {
    final c1 = CheckIn(
        data: DateTime(2026, 8, 1, 15, 30), exercicio: 'Flexão', corIndex: 2);
    expect(c1.data.hour, 0); // normalizado à meia-noite
    expect(mesmoDia(c1.data, DateTime(2026, 8, 1, 9)), isTrue);
    final back = CheckIn.fromJson(c1.toJson());
    expect(back.exercicio, 'Flexão');
    expect(back.corIndex, 2);
    final lista = [
      c1,
      CheckIn(data: DateTime(2026, 8, 2), exercicio: 'X', corIndex: 0),
    ];
    expect(checkinsDoDia(lista, DateTime(2026, 8, 1)).length, 1);
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

  test('unilateral: prep(1) exec(1) prep(2) exec(2) descanso, por série', () {
    final t = Treino(
      nome: 'Teste',
      exercicios: [
        Exercicio(
          nome: 'Flexão um braço',
          preparacaoSeg: 10,
          execucaoSeg: 3,
          descansoSeg: 60,
          repeticoes: 2,
          series: 2,
          unilateral: true,
        ),
      ],
    );
    final fases = montarLinhaDoTempo(t);
    // Por série: 2 prep + 4 exec + 1 desc = 7; ×2 séries = 14; -1 desc final = 13.
    expect(fases.length, 13);
    // Preparação antes de cada lado, em cada série (2 lados × 2 séries).
    expect(fases.where((f) => f.tipo == FaseTipo.preparacao).length, 4);
    expect(fases.where((f) => f.tipo == FaseTipo.execucao).length, 8);
    expect(fases.where((f) => f.tipo == FaseTipo.descanso).length, 1);
    // A sequência começa no lado 1 e passa ao lado 2.
    expect(fases[0].tipo, FaseTipo.preparacao);
    expect(fases[0].lado, 1);
    expect(fases[1].lado, 1); // execução do lado 1
    final prepLado2 = fases.firstWhere((f) => f.lado == 2);
    expect(prepLado2.tipo, FaseTipo.preparacao);
    // Duração: prep 10×2×2 + exec 3×2×2×2 + descanso 60×2 = 40 + 24 + 120 = 184.
    expect(t.duracaoTotalSeg, 184);
  });

  test('unilateral: JSON round-trip preserva a flag', () {
    final e = Exercicio(nome: 'Agachamento uma perna', unilateral: true);
    expect(Exercicio.fromJson(e.toJson()).unilateral, isTrue);
    // Exercício antigo (sem a chave) migra para bilateral.
    final antigo = Exercicio.fromJson({'nome': 'X', 'execucaoSeg': 3});
    expect(antigo.unilateral, isFalse);
  });

  test('streak: dia de descanso (não agendado) não quebra a corrente', () {
    final d = DateTime(2026, 8, 10);
    final wdD = d.weekday - 1;
    final wdD2 = d.subtract(const Duration(days: 2)).weekday - 1;
    // Agenda pula o dia D-1 (descanso).
    final treinos = [
      Treino(nome: 't', dias: [wdD, wdD2], exercicios: [Exercicio(nome: 'F')]),
    ];
    final concs = [
      Conclusao(data: d, treinoId: 't', treino: 't'),
      Conclusao(
          data: d.subtract(const Duration(days: 2)), treinoId: 't', treino: 't'),
    ];
    expect(streakAtual(concs, treinos, hoje: d), 2);
  });

  test('streak: dia agendado sem conclusão quebra; hoje pendente não quebra', () {
    final d = DateTime(2026, 8, 10);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'F'),
      ]),
    ];
    // Concluiu hoje e ontem, faltou anteontem (agendado) -> quebra em D-2.
    final concs = [
      Conclusao(data: d, treinoId: 't', treino: 't'),
      Conclusao(
          data: d.subtract(const Duration(days: 1)), treinoId: 't', treino: 't'),
    ];
    expect(streakAtual(concs, treinos, hoje: d), 2);
    // Hoje ainda não concluído (pendente) não quebra: conta a partir de ontem.
    final concsPendente = [
      Conclusao(
          data: d.subtract(const Duration(days: 1)), treinoId: 't', treino: 't'),
    ];
    expect(streakAtual(concsPendente, treinos, hoje: d), 1);
  });

  test('conquistas atuais escalam com a sequência (4/8/15/21)', () {
    final d = DateTime(2026, 8, 10);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    List<Conclusao> seq(int n) => [
          for (var i = 0; i < n; i++)
            Conclusao(
                data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
        ];
    // 4 seguidos = só Medalha de Prata.
    final a4 = conquistasAtuais(seq(4), treinos, const [], hoje: d);
    expect(a4, {TipoConquista.medalhaPrata});
    // 8 seguidos = Prata + Ouro (medalhas).
    final a8 = conquistasAtuais(seq(8), treinos, const [], hoje: d);
    expect(a8.contains(TipoConquista.medalhaOuro), isTrue);
    expect(a8.contains(TipoConquista.trofeuPrata), isFalse);
    // 15 seguidos = + Troféu de Prata.
    final a15 = conquistasAtuais(seq(15), treinos, const [], hoje: d);
    expect(a15.contains(TipoConquista.trofeuPrata), isTrue);
    expect(a15.contains(TipoConquista.trofeuOuro), isFalse); // falta 21 + progressão
  });

  test('conquistas atuais: quebrar a sequência derruba TODAS (inclui troféu)',
      () {
    final d = DateTime(2026, 8, 10);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    // 15 dias no total, mas os 2 últimos agendados foram perdidos: sequência = 0.
    final concs = [
      for (var i = 2; i < 17; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
    ];
    final atuais = conquistasAtuais(concs, treinos, const [], hoje: d);
    expect(totalDiasConcluidos(concs), 15);
    // Tudo é por sequência: com o elo quebrado, nada fica ativo.
    expect(atuais.isEmpty, isTrue);
  });

  test('troféu de ouro: 21 seguidos + progressão recente em >=50%', () {
    final d = DateTime(2026, 8, 10);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
        Exercicio(nome: 'B'),
      ]),
    ];
    final concs = [
      for (var i = 0; i < 25; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
    ];
    // Recorde de A batido HÁ MUITO (fora da janela de 21 dias).
    final progAntigo = [
      RegistroProgressao(exercicio: 'A', valor: 10, data: DateTime(2026, 6, 1)),
      RegistroProgressao(exercicio: 'A', valor: 15, data: DateTime(2026, 6, 20)),
    ];
    expect(recordesRecentes(treinos, progAntigo, hoje: d), 0);
    expect(
        conquistasAtuais(concs, treinos, progAntigo, hoje: d)
            .contains(TipoConquista.trofeuOuro),
        isFalse);
    // Recorde recente (dentro dos 21 dias) -> coroa volta a ser atual.
    final progRecente = [
      RegistroProgressao(exercicio: 'A', valor: 10, data: DateTime(2026, 7, 1)),
      RegistroProgressao(
          exercicio: 'A', valor: 15, data: d.subtract(const Duration(days: 3))),
    ];
    expect(recordesRecentes(treinos, progRecente, hoje: d), 1);
    expect(
        conquistasAtuais(concs, treinos, progRecente, hoje: d)
            .contains(TipoConquista.trofeuOuro),
        isTrue);
  });
}
