import 'treino.dart';

enum FaseTipo { preparacao, execucao, descanso }

extension FaseTipoLabel on FaseTipo {
  String get rotulo => switch (this) {
    FaseTipo.preparacao => 'Preparação',
    FaseTipo.execucao => 'Execução',
    FaseTipo.descanso => 'Descanso',
  };
}

/// Uma etapa concreta da linha do tempo do cronômetro (já "expandida" a partir
/// dos exercícios). É o que o player conta segundo a segundo.
class Fase {
  final FaseTipo tipo;
  final String exercicioNome;
  final int segundos;
  final int rep; // repetição atual (só para execução); 0 caso não se aplique
  final int totalReps; // total de repetições do exercício
  final int exercicioIndex; // 0-based, dentro do treino
  final int totalExercicios;

  const Fase({
    required this.tipo,
    required this.exercicioNome,
    required this.segundos,
    required this.rep,
    required this.totalReps,
    required this.exercicioIndex,
    required this.totalExercicios,
  });
}

/// Expande um treino na sequência de fases que o cronômetro vai rodar:
///   por exercício: preparação (uma vez) -> [ execução -> descanso ] × reps.
/// Tempos em 0 são pulados. Um descanso no fim absoluto do treino é removido
/// (não faz sentido descansar quando o treino acabou).
List<Fase> montarLinhaDoTempo(Treino t) {
  final fases = <Fase>[];
  final total = t.exercicios.length;
  for (var ei = 0; ei < total; ei++) {
    final e = t.exercicios[ei];
    if (e.preparacaoSeg > 0) {
      fases.add(Fase(
        tipo: FaseTipo.preparacao,
        exercicioNome: e.nome,
        segundos: e.preparacaoSeg,
        rep: 0,
        totalReps: e.repeticoes,
        exercicioIndex: ei,
        totalExercicios: total,
      ));
    }
    final reps = e.repeticoes < 1 ? 1 : e.repeticoes;
    for (var r = 1; r <= reps; r++) {
      if (e.execucaoSeg > 0) {
        fases.add(Fase(
          tipo: FaseTipo.execucao,
          exercicioNome: e.nome,
          segundos: e.execucaoSeg,
          rep: r,
          totalReps: reps,
          exercicioIndex: ei,
          totalExercicios: total,
        ));
      }
      if (e.descansoSeg > 0) {
        fases.add(Fase(
          tipo: FaseTipo.descanso,
          exercicioNome: e.nome,
          segundos: e.descansoSeg,
          rep: r,
          totalReps: reps,
          exercicioIndex: ei,
          totalExercicios: total,
        ));
      }
    }
  }
  while (fases.isNotEmpty && fases.last.tipo == FaseTipo.descanso) {
    fases.removeLast();
  }
  return fases;
}
