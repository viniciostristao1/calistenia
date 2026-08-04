/// As conquistas possíveis. Dois eixos: MEDALHAS premiam sequência (dias
/// agendados seguidos) e TROFÉUS premiam marcos acumulados.
enum TipoConquista { medalhaPrata, medalhaOuro, trofeuPrata, trofeuOuro }

extension TipoConquistaInfo on TipoConquista {
  /// Chave estável para armazenar/sincronizar (não traduzir).
  String get chave => name;

  String get emoji => switch (this) {
        TipoConquista.medalhaPrata => '🥈',
        TipoConquista.medalhaOuro => '🥇',
        TipoConquista.trofeuPrata => '🏆',
        TipoConquista.trofeuOuro => '👑',
      };

  String get titulo => switch (this) {
        TipoConquista.medalhaPrata => 'Medalha de Prata',
        TipoConquista.medalhaOuro => 'Medalha de Ouro',
        TipoConquista.trofeuPrata => 'Troféu de Prata',
        TipoConquista.trofeuOuro => 'Troféu de Ouro',
      };

  /// Nome curto (para chips/legendas compactas).
  String get tituloCurto => switch (this) {
        TipoConquista.medalhaPrata => 'Prata',
        TipoConquista.medalhaOuro => 'Ouro',
        TipoConquista.trofeuPrata => 'Troféu',
        TipoConquista.trofeuOuro => 'Coroa',
      };

  /// Descrição da regra. Para a conquista-surpresa não é revelada até conquistar.
  String get descricao => switch (this) {
        TipoConquista.medalhaPrata => '4 dias de treino seguidos',
        TipoConquista.medalhaOuro => '8 dias de treino seguidos',
        TipoConquista.trofeuPrata => '15 dias de treino concluídos',
        TipoConquista.trofeuOuro => 'Conquista secreta',
      };

  /// Conquista-surpresa: fica oculta na galeria até ser desbloqueada.
  bool get surpresa => this == TipoConquista.trofeuOuro;
}

TipoConquista? tipoConquistaDe(String chave) {
  for (final t in TipoConquista.values) {
    if (t.name == chave) return t;
  }
  return null;
}

/// Uma conquista já obtida (registrada no momento em que foi desbloqueada).
class Conquista {
  final String tipo; // TipoConquista.name
  final DateTime data; // quando foi conquistada

  Conquista({required this.tipo, required this.data});

  Map<String, dynamic> toJson() => {
    // 'id' = tipo: cada conquista é única por tipo. Serve à união por id do
    // sincronizador (uma conquista por tipo, sem duplicar entre aparelhos).
    'id': tipo,
    'tipo': tipo,
    'data': data.millisecondsSinceEpoch,
  };

  factory Conquista.fromJson(Map<String, dynamic> j) => Conquista(
        tipo: (j['tipo'] ?? '') as String,
        data: DateTime.fromMillisecondsSinceEpoch((j['data'] ?? 0) as int),
      );
}
