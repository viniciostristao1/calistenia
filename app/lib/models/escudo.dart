import 'insignia.dart' show chaveDia;

/// Um **ESCUDO** (troféu raro). Sorteado (seed + sorte) num dia entre o 13º e o
/// 26º de uma sequência consecutiva (pulando o 20º, p/ não colidir com o fogo).
/// Dá o direito de "gastar": cobrir UMA falha e contá-la como dia completo
/// (mantendo a corrente). Enquanto `usadoEm == null` está GUARDADO (disponível);
/// depois de usado, `usadoEm` é o dia coberto. Máximo 1 guardado por vez.
class Escudo {
  final DateTime ganhoEm; // dia em que foi sorteado/ganho (normalizado)
  final DateTime? usadoEm; // dia coberto (null = guardado, não usado)

  Escudo({required DateTime ganhoEm, DateTime? usadoEm})
    : ganhoEm = DateTime(ganhoEm.year, ganhoEm.month, ganhoEm.day),
      usadoEm = usadoEm == null
          ? null
          : DateTime(usadoEm.year, usadoEm.month, usadoEm.day);

  bool get usado => usadoEm != null;

  /// Id estável = o dia em que foi ganho (YYYY-MM-DD). Como só há 1 escudo
  /// guardado por vez e ele vem de dias distintos, serve à união por id do sync.
  String get id => chaveDia(ganhoEm);

  /// Cópia já USADA, cobrindo [dia].
  Escudo copyUsando(DateTime dia) => Escudo(ganhoEm: ganhoEm, usadoEm: dia);

  Map<String, dynamic> toJson() => {
    'id': id,
    'ganhoEm': ganhoEm.millisecondsSinceEpoch,
    'usadoEm': usadoEm?.millisecondsSinceEpoch,
  };

  factory Escudo.fromJson(Map<String, dynamic> j) => Escudo(
    ganhoEm: DateTime.fromMillisecondsSinceEpoch((j['ganhoEm'] ?? 0) as int),
    usadoEm: j['usadoEm'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(j['usadoEm'] as int),
  );
}
