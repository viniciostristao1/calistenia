import '../util/ids.dart';

/// Registra que um TREINO foi CONCLUÍDO num dia — o "sim" da pergunta de fim de
/// treino ("Você completou o treino?"). É a base da gamificação (sequência,
/// medalhas, troféus), distinta do [CheckIn] (assiduidade) por exercício: o
/// check-in marca "apareci"; a conclusão marca "completei tudo".
class Conclusao {
  final String id;
  final DateTime data; // normalizada para o dia (meia-noite)
  final String treinoId; // qual treino
  final String treino; // nome do treino (para exibição)

  Conclusao({
    String? id,
    required DateTime data,
    required this.treinoId,
    required this.treino,
  })  : id = id ?? novoId(),
        data = DateTime(data.year, data.month, data.day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.millisecondsSinceEpoch,
    'treinoId': treinoId,
    'treino': treino,
  };

  factory Conclusao.fromJson(Map<String, dynamic> j) => Conclusao(
        id: j['id'] as String?,
        data: DateTime.fromMillisecondsSinceEpoch((j['data'] ?? 0) as int),
        treinoId: (j['treinoId'] ?? '') as String,
        treino: (j['treino'] ?? '') as String,
      );
}
