import '../util/ids.dart';

/// Um registro de progressão: quantas repetições a pessoa fez de um exercício
/// num dia. Liga-se ao exercício pelo NOME (a evolução da "Flexão" acumula,
/// independente do treino em que ela aparece).
class RegistroProgressao {
  final String id;
  final String exercicio; // nome do exercício
  final int valor; // repetições feitas naquele dia
  final DateTime data;

  RegistroProgressao({
    String? id,
    required this.exercicio,
    required this.valor,
    DateTime? data,
  })  : id = id ?? novoId(),
        data = data ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercicio': exercicio,
    'valor': valor,
    'data': data.millisecondsSinceEpoch,
  };

  factory RegistroProgressao.fromJson(Map<String, dynamic> j) =>
      RegistroProgressao(
        id: j['id'] as String?,
        exercicio: (j['exercicio'] ?? '') as String,
        valor: (j['valor'] ?? 0) as int,
        data: DateTime.fromMillisecondsSinceEpoch((j['data'] ?? 0) as int),
      );
}
