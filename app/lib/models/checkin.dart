import '../util/ids.dart';

/// Um check-in: registra que um exercício foi feito num dia (para o calendário
/// de assiduidade). Guarda o nome e a cor do exercício (o "pontinho").
class CheckIn {
  final String id;
  final DateTime data; // normalizada para o dia (meia-noite)
  final String exercicio; // nome do exercício
  final int corIndex; // cor do exercício (pontinho)

  CheckIn({
    String? id,
    required DateTime data,
    required this.exercicio,
    required this.corIndex,
  })  : id = id ?? novoId(),
        data = DateTime(data.year, data.month, data.day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.millisecondsSinceEpoch,
    'exercicio': exercicio,
    'corIndex': corIndex,
  };

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        id: j['id'] as String?,
        data: DateTime.fromMillisecondsSinceEpoch((j['data'] ?? 0) as int),
        exercicio: (j['exercicio'] ?? '') as String,
        corIndex: (j['corIndex'] ?? 0) as int,
      );
}

/// Dois DateTimes caem no mesmo dia?
bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
