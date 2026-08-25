import '../util/ids.dart';

/// Um registro de progressão: quantas repetições (e, opcionalmente, com quanto
/// PESO) a pessoa fez de um exercício num dia. Liga-se ao exercício pelo NOME (a
/// evolução da "Flexão" acumula, independente do treino em que ela aparece).
///
/// `peso` = carga adicional em kg (0 = peso do corpo). A progressão passa a
/// reconhecer recorde tanto de reps quanto de peso (ver `gamificacao.dart`).
class RegistroProgressao {
  final String id;
  final String exercicio; // nome do exercício
  final int valor; // repetições feitas naquele dia
  final double peso; // carga em kg naquele dia; 0 = peso do corpo
  final DateTime data;

  RegistroProgressao({
    String? id,
    required this.exercicio,
    required this.valor,
    this.peso = 0,
    DateTime? data,
  })  : id = id ?? novoId(),
        data = data ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercicio': exercicio,
    'valor': valor,
    'peso': peso,
    'data': data.millisecondsSinceEpoch,
  };

  factory RegistroProgressao.fromJson(Map<String, dynamic> j) =>
      RegistroProgressao(
        id: j['id'] as String?,
        exercicio: (j['exercicio'] ?? '') as String,
        valor: (j['valor'] ?? 0) as int,
        peso: ((j['peso'] ?? 0) as num).toDouble(),
        data: DateTime.fromMillisecondsSinceEpoch((j['data'] ?? 0) as int),
      );
}
