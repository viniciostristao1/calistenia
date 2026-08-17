/// Uma INSÍGNIA (estrela amarela) GANHA num dia. Todo mês, até 7 dias com treino
/// agendado são sorteados de forma determinística (ver `util/insignias.dart`); o
/// usuário só descobre ao **concluir** o treino ("consegui"). No máximo uma por
/// dia — por isso o `id` é o próprio dia (garante dedup no sincronizador).
class Insignia {
  final DateTime data; // dia normalizado (meia-noite)

  Insignia({required DateTime data})
      : data = DateTime(data.year, data.month, data.day);

  /// Id estável = o próprio dia (YYYY-MM-DD). Serve à união por id do sync (uma
  /// insígnia por dia, sem duplicar entre aparelhos).
  String get id => chaveDia(data);

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.millisecondsSinceEpoch,
      };

  factory Insignia.fromJson(Map<String, dynamic> j) => Insignia(
        data: DateTime.fromMillisecondsSinceEpoch((j['data'] ?? 0) as int),
      );
}

/// Chave de um dia (YYYY-MM-DD) — usada como id estável da insígnia.
String chaveDia(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
