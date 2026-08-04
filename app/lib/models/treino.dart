import '../util/ids.dart';
import 'exercicio.dart';

/// Um treino: tem nome, os dias da semana em que aparece e uma lista de
/// exercícios (em ordem de execução).
class Treino {
  final String id;
  String nome;
  List<int> dias; // 0=seg .. 6=dom
  List<Exercicio> exercicios;

  Treino({
    String? id,
    required this.nome,
    List<int>? dias,
    List<Exercicio>? exercicios,
  }) : id = id ?? novoId(),
       dias = dias ?? [],
       exercicios = exercicios ?? [];

  /// Duração total do treino em segundos (aproximada — inclui o descanso da
  /// última série; a linha do tempo real remove o descanso do fim absoluto).
  int get duracaoTotalSeg {
    var total = 0;
    for (final e in exercicios) {
      final series = e.series < 1 ? 1 : e.series;
      final reps = e.repeticoes < 1 ? 1 : e.repeticoes;
      if (e.unilateral) {
        // Preparação antes de cada lado, em cada série; execução dos dois lados.
        total += e.preparacaoSeg * 2 * series;
        total += e.execucaoSeg * reps * 2 * series;
      } else {
        total += e.preparacaoSeg;
        total += e.execucaoSeg * reps * series;
      }
      for (var s = 1; s <= series; s++) {
        total += e.descansoAposSerie(s);
      }
    }
    return total;
  }

  Treino copy() => Treino(
    id: id,
    nome: nome,
    dias: List.of(dias),
    exercicios: exercicios.map((e) => e.copy()).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'dias': dias,
    'exercicios': exercicios.map((e) => e.toJson()).toList(),
  };

  factory Treino.fromJson(Map<String, dynamic> j) => Treino(
    id: j['id'] as String?,
    nome: (j['nome'] ?? '') as String,
    dias: ((j['dias'] ?? []) as List).map((e) => e as int).toList(),
    exercicios: ((j['exercicios'] ?? []) as List)
        .map((e) => Exercicio.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
