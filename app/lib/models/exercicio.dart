import '../util/ids.dart';

/// Um exercício dentro de um treino.
///
/// O cronômetro de um exercício roda assim:
///   preparação (uma vez) -> [ execução -> descanso ] × repetições
///
/// Cada tempo é em SEGUNDOS. Um tempo em 0 significa "sem essa etapa"
/// (ex.: `descansoSeg == 0` = exercício sem descanso).
class Exercicio {
  final String id;
  String nome;
  int preparacaoSeg; // 0 = sem preparação
  int execucaoSeg; // segundos do movimento (o "faça agora")
  int descansoSeg; // 0 = sem descanso entre repetições
  int repeticoes; // >= 1

  Exercicio({
    String? id,
    required this.nome,
    this.preparacaoSeg = 10,
    this.execucaoSeg = 30,
    this.descansoSeg = 15,
    this.repeticoes = 3,
  }) : id = id ?? novoId();

  Exercicio copy() => Exercicio(
    id: id,
    nome: nome,
    preparacaoSeg: preparacaoSeg,
    execucaoSeg: execucaoSeg,
    descansoSeg: descansoSeg,
    repeticoes: repeticoes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'preparacaoSeg': preparacaoSeg,
    'execucaoSeg': execucaoSeg,
    'descansoSeg': descansoSeg,
    'repeticoes': repeticoes,
  };

  factory Exercicio.fromJson(Map<String, dynamic> j) => Exercicio(
    id: j['id'] as String?,
    nome: (j['nome'] ?? '') as String,
    preparacaoSeg: (j['preparacaoSeg'] ?? 0) as int,
    execucaoSeg: (j['execucaoSeg'] ?? 30) as int,
    descansoSeg: (j['descansoSeg'] ?? 0) as int,
    repeticoes: (j['repeticoes'] ?? 1) as int,
  );
}
