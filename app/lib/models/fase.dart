import 'exercicio.dart';
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
  final int rep; // repetição atual (só p/ execução); 0 caso não se aplique
  final int totalReps; // repetições por série do exercício
  final int serie; // série atual (execução/descanso); 0 caso não se aplique
  final int totalSeries; // total de séries do exercício
  final int exercicioIndex; // 0-based, dentro do treino
  final int totalExercicios;

  const Fase({
    required this.tipo,
    required this.exercicioNome,
    required this.segundos,
    required this.rep,
    required this.totalReps,
    required this.serie,
    required this.totalSeries,
    required this.exercicioIndex,
    required this.totalExercicios,
  });
}

/// Expande um treino na sequência de fases que o cronômetro vai rodar.
List<Fase> montarLinhaDoTempo(Treino t) => montarLinhaDoTempoDe(t.exercicios);

/// Expande uma lista de exercícios na sequência de fases:
///   por exercício: preparação (1×) -> [ execução×reps -> descanso ] × séries.
/// Não há descanso entre repetições (elas são seguidas); o descanso é entre
/// séries. Tempos em 0 são pulados, e um descanso no fim absoluto é removido
/// (não faz sentido descansar quando acabou).
List<Fase> montarLinhaDoTempoDe(List<Exercicio> exercicios) {
  final fases = <Fase>[];
  final total = exercicios.length;
  for (var ei = 0; ei < total; ei++) {
    final e = exercicios[ei];
    final series = e.series < 1 ? 1 : e.series;
    final reps = e.repeticoes < 1 ? 1 : e.repeticoes;
    if (e.preparacaoSeg > 0) {
      fases.add(Fase(
        tipo: FaseTipo.preparacao,
        exercicioNome: e.nome,
        segundos: e.preparacaoSeg,
        rep: 0,
        totalReps: reps,
        serie: 0,
        totalSeries: series,
        exercicioIndex: ei,
        totalExercicios: total,
      ));
    }
    for (var s = 1; s <= series; s++) {
      if (e.execucaoSeg > 0) {
        for (var r = 1; r <= reps; r++) {
          fases.add(Fase(
            tipo: FaseTipo.execucao,
            exercicioNome: e.nome,
            segundos: e.execucaoSeg,
            rep: r,
            totalReps: reps,
            serie: s,
            totalSeries: series,
            exercicioIndex: ei,
            totalExercicios: total,
          ));
        }
      }
      final desc = e.descansoAposSerie(s);
      if (desc > 0) {
        fases.add(Fase(
          tipo: FaseTipo.descanso,
          exercicioNome: e.nome,
          segundos: desc,
          rep: 0,
          totalReps: reps,
          serie: s,
          totalSeries: series,
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
