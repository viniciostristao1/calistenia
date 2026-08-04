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
  final int lado; // lado atual em exercício unilateral: 1 ou 2; 0 = bilateral
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
    this.lado = 0,
    required this.exercicioIndex,
    required this.totalExercicios,
  });
}

/// Expande um treino na sequência de fases que o cronômetro vai rodar.
List<Fase> montarLinhaDoTempo(Treino t) => montarLinhaDoTempoDe(t.exercicios);

/// Expande uma lista de exercícios na sequência de fases:
///   bilateral:  preparação (1×) -> [ execução×reps -> descanso ] × séries.
///   unilateral: por série -> prep(lado 1) -> exec×reps(lado 1) ->
///               prep(lado 2) -> exec×reps(lado 2) -> descanso.
/// Não há descanso entre repetições (elas são seguidas); o descanso é entre
/// séries (e, no unilateral, ao fim dos dois lados). Tempos em 0 são pulados,
/// e um descanso no fim absoluto é removido (não faz sentido descansar quando
/// acabou).
List<Fase> montarLinhaDoTempoDe(List<Exercicio> exercicios) {
  final fases = <Fase>[];
  final total = exercicios.length;
  for (var ei = 0; ei < total; ei++) {
    final e = exercicios[ei];
    final series = e.series < 1 ? 1 : e.series;
    final reps = e.repeticoes < 1 ? 1 : e.repeticoes;

    void addPrep(int serie, int lado) {
      if (e.preparacaoSeg <= 0) return;
      fases.add(Fase(
        tipo: FaseTipo.preparacao,
        exercicioNome: e.nome,
        segundos: e.preparacaoSeg,
        rep: 0,
        totalReps: reps,
        serie: serie,
        totalSeries: series,
        lado: lado,
        exercicioIndex: ei,
        totalExercicios: total,
      ));
    }

    void addExec(int serie, int lado) {
      if (e.execucaoSeg <= 0) return;
      for (var r = 1; r <= reps; r++) {
        fases.add(Fase(
          tipo: FaseTipo.execucao,
          exercicioNome: e.nome,
          segundos: e.execucaoSeg,
          rep: r,
          totalReps: reps,
          serie: serie,
          totalSeries: series,
          lado: lado,
          exercicioIndex: ei,
          totalExercicios: total,
        ));
      }
    }

    void addDescanso(int serie) {
      final desc = e.descansoAposSerie(serie);
      if (desc <= 0) return;
      fases.add(Fase(
        tipo: FaseTipo.descanso,
        exercicioNome: e.nome,
        segundos: desc,
        rep: 0,
        totalReps: reps,
        serie: serie,
        totalSeries: series,
        exercicioIndex: ei,
        totalExercicios: total,
      ));
    }

    if (e.unilateral) {
      // Um lado por vez: cada série faz o lado 1 e depois o lado 2, com uma
      // preparação antes de cada lado e um só descanso ao fim da série.
      for (var s = 1; s <= series; s++) {
        addPrep(s, 1);
        addExec(s, 1);
        addPrep(s, 2);
        addExec(s, 2);
        addDescanso(s);
      }
    } else {
      // Bilateral (padrão): uma preparação e depois as séries.
      addPrep(0, 0);
      for (var s = 1; s <= series; s++) {
        addExec(s, 0);
        addDescanso(s);
      }
    }
  }
  while (fases.isNotEmpty && fases.last.tipo == FaseTipo.descanso) {
    fases.removeLast();
  }
  return fases;
}
