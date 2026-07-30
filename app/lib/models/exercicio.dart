import '../util/ids.dart';

/// Um exercício dentro de um treino.
///
/// Modelo "ritmo por repetição". O cronômetro de um exercício roda assim:
///   preparação (uma vez) -> [ (execução × repetições) -> descanso ] × séries
///
/// Ou seja:
///  - `execucaoSeg` = duração de UMA repetição (ex.: uma flexão de 3s);
///  - `repeticoes`  = quantas repetições por série (ex.: 10 flexões);
///  - `series`      = quantas séries (ex.: 3 vezes);
///  - `descansoSeg` = descanso ENTRE séries.
///
/// Um tempo em 0 = "sem essa etapa" (ex.: `descansoSeg == 0` = sem descanso).
/// Isométrico (prancha) = `repeticoes: 1` com `execucaoSeg` = tempo da série.
class Exercicio {
  final String id;
  String nome;
  int preparacaoSeg; // 0 = sem preparação
  int execucaoSeg; // segundos de UMA repetição (o "faça agora"); >= 1
  int descansoSeg; // 0 = sem descanso; senão descanso entre séries
  int repeticoes; // repetições por série; >= 1
  int series; // número de séries; >= 1

  Exercicio({
    String? id,
    required this.nome,
    this.preparacaoSeg = 10,
    this.execucaoSeg = 3,
    this.descansoSeg = 60,
    this.repeticoes = 10,
    this.series = 3,
  }) : id = id ?? novoId();

  Exercicio copy() => Exercicio(
    id: id,
    nome: nome,
    preparacaoSeg: preparacaoSeg,
    execucaoSeg: execucaoSeg,
    descansoSeg: descansoSeg,
    repeticoes: repeticoes,
    series: series,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'preparacaoSeg': preparacaoSeg,
    'execucaoSeg': execucaoSeg,
    'descansoSeg': descansoSeg,
    'repeticoes': repeticoes,
    'series': series,
  };

  factory Exercicio.fromJson(Map<String, dynamic> j) {
    // Migração do formato antigo (v0.1.0): lá "repeticoes" significava quantas
    // RODADAS de [execução -> descanso] rodar — ou seja, o que hoje é "séries",
    // sem repetições internas. Preserva o comportamento: series = antigo, reps = 1.
    final temSeries = j.containsKey('series');
    final repsAntigo = (j['repeticoes'] ?? 1) as int;
    return Exercicio(
      id: j['id'] as String?,
      nome: (j['nome'] ?? '') as String,
      preparacaoSeg: (j['preparacaoSeg'] ?? 0) as int,
      execucaoSeg: (j['execucaoSeg'] ?? 3) as int,
      descansoSeg: (j['descansoSeg'] ?? 0) as int,
      repeticoes: temSeries ? repsAntigo : 1,
      series: temSeries ? (j['series'] ?? 1) as int : repsAntigo,
    );
  }
}
