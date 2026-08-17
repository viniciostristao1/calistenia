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
import 'package:calistenia/util/insignias.dart';
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

  test('tolerância: faltar UM dia agendado não derruba o nível', () {
    final d = DateTime(2026, 8, 20);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    // 8 dias concluídos (d-9..d-2), d-1 FALTADO (1 só), hoje pendente.
    final concs = [
      for (var i = 2; i <= 9; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
    ];
    final info = nivelInfo(concs, treinos, hoje: d);
    expect(info.atual, 8); // 1 falta é tolerada -> mantém o ouro
  });

  test('perda escalonada: faltar DOIS dias agendados seguidos cai um degrau (8->4)',
      () {
    final d = DateTime(2026, 8, 20);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    // 8 concluídos (d-10..d-3), depois d-2 e d-1 FALTADOS (agendados, passados).
    final concs = [
      for (var i = 3; i <= 10; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
    ];
    final info = nivelInfo(concs, treinos, hoje: d);
    expect(info.recorde, 8); // chegou à medalha de ouro
    expect(info.atual, 4); // faltou 2 seguidos -> caiu um degrau, para 4 (prata)
    final atuais = conquistasAtuais(concs, treinos, const [], hoje: d);
    expect(atuais.contains(TipoConquista.medalhaPrata), isTrue);
    expect(atuais.contains(TipoConquista.medalhaOuro), isFalse);
  });

  test('não consegui: 2 tentativas ok, 3ª derruba um degrau', () {
    final d = DateTime(2026, 8, 20);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    // 4 completos (d-6..d-3) -> prata (4); depois 2 tentativas (d-2, d-1).
    final base = [
      for (var i = 3; i <= 6; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
      Conclusao(
          data: d.subtract(const Duration(days: 2)),
          treinoId: 't',
          treino: 't',
          completo: false),
      Conclusao(
          data: d.subtract(const Duration(days: 1)),
          treinoId: 't',
          treino: 't',
          completo: false),
    ];
    // Duas tentativas seguidas são toleradas -> mantém a prata.
    expect(nivelInfo(base, treinos, hoje: d).atual, 4);
    // A 3ª tentativa (hoje) estoura o orçamento -> prata (4) cai para 0.
    final tres = [
      ...base,
      Conclusao(data: d, treinoId: 't', treino: 't', completo: false),
    ];
    expect(nivelInfo(tres, treinos, hoje: d).atual, 0);
  });

  test('insígnias: 7 por mês, determinístico e só em dias agendados', () {
    final agendados = {0, 1, 2, 3, 4}; // seg..sex
    final s = sementeInsignia('user-123');
    final dias = diasInsigniaDoMes(2026, 8, agendados, s);
    expect(dias.length, 7);
    // Determinístico: recomputar dá o MESMO conjunto.
    expect(diasInsigniaDoMes(2026, 8, agendados, s), dias);
    // Só caem em dias agendados (seg..sex).
    for (final dia in dias) {
      expect(agendados.contains(DateTime(2026, 8, dia).weekday - 1), isTrue);
    }
    // Muda de mês (não é o mesmo sorteio todo mês).
    expect(diasInsigniaDoMes(2026, 9, agendados, s) == dias, isFalse);
  });

  test('insígnia (v0.48.0): não mexe na consistência; vira bônus separado', () {
    final d = DateTime(2026, 8, 20);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    final concs = [
      Conclusao(
          data: d.subtract(const Duration(days: 1)),
          treinoId: 't',
          treino: 't'),
    ];
    final semIns = ratingForma(concs, treinos, const [], hoje: d);
    final comIns = ratingForma(concs, treinos, const [], hoje: d,
        diasInsignia: {DateTime(2026, 8, 19)});
    // A estrela NÃO altera mais a consistência (peso 1,5 removido).
    expect(comIns.consistencia, semIns.consistencia);
    expect(comIns.total, semIns.total); // nota-base intacta
    // Ela vira bônus LINEAR (1 estrela = +1), fora dos 100.
    expect(semIns.bonusEstrelas, 0);
    expect(comIns.bonusEstrelas, 1);
    expect(comIns.totalComBonus, comIns.total + 1);
  });

  test('bônus de estrelas: linear, só do mês corrente, capado em 7', () {
    final d = DateTime(2026, 8, 20);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    // 3 em agosto (conta) + 2 em julho + 1 em setembro (fora do mês → ignora).
    final ins = {
      DateTime(2026, 8, 3),
      DateTime(2026, 8, 10),
      DateTime(2026, 8, 17),
      DateTime(2026, 7, 5),
      DateTime(2026, 7, 12),
      DateTime(2026, 9, 1),
    };
    expect(
        ratingForma(const [], treinos, const [], hoje: d, diasInsignia: ins)
            .bonusEstrelas,
        3);
    // Capa em 7 mesmo com 9 estrelas no mesmo mês.
    final nove = {for (var i = 1; i <= 9; i++) DateTime(2026, 8, i)};
    expect(
        ratingForma(const [], treinos, const [], hoje: d, diasInsignia: nove)
            .bonusEstrelas,
        7);
  });

  test('rating de forma: consistência + frequência + progressão (0-100)', () {
    final d = DateTime(2026, 8, 20);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    // Cumpriu todos os agendados dos últimos 28 dias (hoje pendente = neutro).
    final concs = [
      for (var i = 1; i <= 28; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
    ];
    final semProg = ratingForma(concs, treinos, const [], hoje: d);
    expect(semProg.consistencia, 40); // agendados cumpridos, hoje neutro
    expect(semProg.frequencia, 20); // volume alto -> teto
    expect(semProg.progressao, 0);
    expect(semProg.total, 60);
    // Recorde subiu de 10 (antes da janela de 42d) para 15 -> +50% -> 40*0.5/2.5 = 8.
    final prog = [
      RegistroProgressao(
          exercicio: 'A', valor: 10, data: d.subtract(const Duration(days: 50))),
      RegistroProgressao(
          exercicio: 'A', valor: 15, data: d.subtract(const Duration(days: 5))),
    ];
    expect(ratingForma(concs, treinos, prog, hoje: d).progressao, 8);
  });

  test('"não consegui" (tentativa) vale meia consistência; mantém freq/sequência',
      () {
    final d = DateTime(2026, 8, 20);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    // Todos os 28 dias agendados foram TENTATIVAS (completo: false).
    final tentativas = [
      for (var i = 1; i <= 28; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)),
            treinoId: 't',
            treino: 't',
            completo: false),
    ];
    final r = ratingForma(tentativas, treinos, const [], hoje: d);
    expect(r.consistencia, 20); // metade de 40 (0,5 por dia tentado)
    expect(r.frequencia, 20); // tentativa conta como treino
    // A sequência NÃO quebra com tentativas (mantém o hábito).
    expect(streakAtual(tentativas, treinos, hoje: d), 28);

    // Completo vale o dobro da tentativa na consistência.
    final completos = [
      for (var i = 1; i <= 28; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
    ];
    expect(ratingForma(completos, treinos, const [], hoje: d).consistencia, 40);

    // Round-trip do JSON preserva o campo `completo`.
    final rt = Conclusao.fromJson(tentativas.first.toJson());
    expect(rt.completo, isFalse);
  });

  test('serieRating: série temporal sem olhar o futuro', () {
    final d = DateTime(2026, 8, 20);
    final treinos = [
      Treino(nome: 't', dias: [0, 1, 2, 3, 4, 5, 6], exercicios: [
        Exercicio(nome: 'A'),
      ]),
    ];
    final concs = [
      for (var i = 0; i < 28; i++)
        Conclusao(
            data: d.subtract(Duration(days: i)), treinoId: 't', treino: 't'),
    ];
    final prog = [
      RegistroProgressao(
          exercicio: 'A', valor: 10, data: d.subtract(const Duration(days: 2))),
      RegistroProgressao(exercicio: 'A', valor: 20, data: d), // recorde HOJE
    ];
    final serie = serieRating(concs, treinos, prog, semanas: 4, hoje: d);
    expect(serie.length, 4);
    // O último ponto = rating atual.
    expect(serie.last.valor, ratingForma(concs, treinos, prog, hoje: d).total);
    // O ponto mais antigo não conta o recorde recente (sem look-ahead).
    expect(serie.first.valor < serie.last.valor, isTrue);
  });

  test('conquista: JSON round-trip preserva perdidaEm (histórico)', () {
    final perdida = Conquista(
      tipo: 'medalhaPrata',
      data: DateTime(2026, 8, 1),
      perdidaEm: DateTime(2026, 8, 20),
    );
    final back = Conquista.fromJson(perdida.toJson());
    expect(back.tipo, 'medalhaPrata');
    expect(back.perdidaEm, DateTime(2026, 8, 20));
    // Ativa (sem perdidaEm) não grava a chave.
    final ativa = Conquista(tipo: 'x', data: DateTime(2026, 8, 1));
    expect(ativa.toJson().containsKey('perdidaEm'), isFalse);
    expect(Conquista.fromJson(ativa.toJson()).perdidaEm, isNull);
    expect(ativa.comPerdida(DateTime(2026, 9, 1)).perdidaEm, DateTime(2026, 9, 1));
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
