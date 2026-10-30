import '../util/ids.dart';

/// As métricas corporais acompanhadas. A ordem aqui é a ordem de exibição
/// (seletor do gráfico e campos do editor). Peso em kg; o resto em cm.
enum MetricaCorporal { peso, cintura, braco, peito, coxa }

extension MetricaCorporalInfo on MetricaCorporal {
  /// Unidade da métrica (peso = kg; medidas = cm).
  String get unidade => this == MetricaCorporal.peso ? 'kg' : 'cm';
}

/// Uma medição corporal num dado dia: peso + circunferências. Todos os campos
/// são opcionais — uma medição pode ter só o peso, por exemplo. O [id] é estável
/// e serve à união por id do sync (mesmo padrão de [Nota] e dos outros stores).
class Medida {
  final String id;
  final DateTime data; // dia da medição (normalizado p/ meia-noite)
  final double? peso; // kg
  final double? cintura; // cm
  final double? braco; // cm
  final double? peito; // cm
  final double? coxa; // cm
  final DateTime atualizadoEm;

  Medida({
    String? id,
    required DateTime data,
    this.peso,
    this.cintura,
    this.braco,
    this.peito,
    this.coxa,
    DateTime? atualizadoEm,
  }) : id = id ?? novoId(),
       data = DateTime(data.year, data.month, data.day),
       atualizadoEm = atualizadoEm ?? DateTime.now();

  /// Valor de uma métrica específica (p/ o gráfico/seletor).
  double? valorDe(MetricaCorporal m) => switch (m) {
    MetricaCorporal.peso => peso,
    MetricaCorporal.cintura => cintura,
    MetricaCorporal.braco => braco,
    MetricaCorporal.peito => peito,
    MetricaCorporal.coxa => coxa,
  };

  /// Tem pelo menos um valor preenchido? (não salvamos medição vazia.)
  bool get temAlgo =>
      peso != null ||
      cintura != null ||
      braco != null ||
      peito != null ||
      coxa != null;

  Medida copyWith({
    DateTime? data,
    double? peso,
    double? cintura,
    double? braco,
    double? peito,
    double? coxa,
  }) => Medida(
    id: id,
    data: data ?? this.data,
    peso: peso ?? this.peso,
    cintura: cintura ?? this.cintura,
    braco: braco ?? this.braco,
    peito: peito ?? this.peito,
    coxa: coxa ?? this.coxa,
    atualizadoEm: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.millisecondsSinceEpoch,
    if (peso != null) 'peso': peso,
    if (cintura != null) 'cintura': cintura,
    if (braco != null) 'braco': braco,
    if (peito != null) 'peito': peito,
    if (coxa != null) 'coxa': coxa,
    'atualizadoEm': atualizadoEm.millisecondsSinceEpoch,
  };

  static double? _num(dynamic v) => v == null ? null : (v as num).toDouble();

  factory Medida.fromJson(Map<String, dynamic> j) => Medida(
    id: j['id'] as String? ?? novoId(),
    data: j['data'] == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(j['data'] as int),
    peso: _num(j['peso']),
    cintura: _num(j['cintura']),
    braco: _num(j['braco']),
    peito: _num(j['peito']),
    coxa: _num(j['coxa']),
    atualizadoEm: j['atualizadoEm'] == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(j['atualizadoEm'] as int),
  );
}
