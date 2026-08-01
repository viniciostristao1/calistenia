import '../util/format.dart';
import '../util/ids.dart';

/// Um exercício dentro de um treino.
///
/// Modelo "ritmo por repetição". O cronômetro de um exercício roda assim:
///   preparação (uma vez) -> [ (execução × repetições) -> descanso ] × séries
///
/// Ou seja:
///  - `execucaoSeg` = duração de UMA repetição (ex.: uma flexão de 3s). 0 = sem
///     execução (etapa ausente, igual à preparação/descanso);
///  - `repeticoes`  = quantas repetições por série (ex.: 10 flexões);
///  - `series`      = quantas séries (ex.: 3 vezes);
///  - `descansoSeg` = descanso padrão entre séries;
///  - `descansos`   = (opcional) descanso por série — quando presente, sobrepõe o
///     padrão série a série (ex.: 1min na 1ª, 1min30 na 2ª…). `null` = usa o padrão.
///
/// Um tempo em 0 = "sem essa etapa". Isométrico (prancha) = `repeticoes: 1` com
/// `execucaoSeg` = tempo da série.
class Exercicio {
  final String id;
  String nome;
  int preparacaoSeg; // 0 = sem preparação
  int execucaoSeg; // segundos de UMA repetição; 0 = sem execução
  int descansoSeg; // descanso padrão entre séries; 0 = sem descanso
  int repeticoes; // repetições por série; >= 1
  int series; // número de séries; >= 1
  List<int>? descansos; // descanso por série (tamanho = series); null = padrão
  double pesoKg; // peso adicional usado; 0 = só o peso do corpo
  int corIndex; // índice na paleta de cores (marca do exercício)

  Exercicio({
    String? id,
    required this.nome,
    this.preparacaoSeg = 10,
    this.execucaoSeg = 3,
    this.descansoSeg = 60,
    this.repeticoes = 10,
    this.series = 3,
    this.descansos,
    this.pesoKg = 0,
    this.corIndex = 0,
  }) : id = id ?? novoId();

  /// Descanso após a série [s] (1-based). Usa o override por série se houver;
  /// senão, o descanso padrão.
  int descansoAposSerie(int s) {
    final d = descansos;
    if (d != null && s >= 1 && s <= d.length) return d[s - 1];
    return descansoSeg;
  }

  /// True se os descansos por série não são todos iguais (descanso variável ativo).
  bool get temDescansoVariavel => descansos != null;

  /// Resumo curto para listas: "3×10 · 3s/rep · 10kg · desc 1min", "3 séries ·
  /// sem execução", "3× 45s" (isométrico), com descanso variável como faixa.
  String get resumoCurto {
    final String base;
    if (execucaoSeg <= 0) {
      base = '$series ${series > 1 ? 'séries' : 'série'} · sem execução';
    } else if (repeticoes > 1) {
      base = '$series×$repeticoes · ${fmtSeg(execucaoSeg)}/rep';
    } else {
      base = '$series× ${fmtSeg(execucaoSeg)}';
    }
    final desc = _resumoDescanso();
    return [
      base,
      if (pesoKg > 0) fmtPeso(pesoKg),
      if (desc.isNotEmpty) desc,
    ].join(' · ');
  }

  String _resumoDescanso() {
    final lista = descansos;
    if (lista != null && lista.isNotEmpty) {
      var mn = 1 << 30, mx = 0, ativos = 0;
      for (final d in lista) {
        if (d > 0) {
          ativos++;
          if (d < mn) mn = d;
          if (d > mx) mx = d;
        }
      }
      if (ativos == 0) return '';
      return mn == mx ? 'desc ${fmtSeg(mn)}' : 'desc ${fmtSeg(mn)}–${fmtSeg(mx)}';
    }
    return descansoSeg > 0 ? 'desc ${fmtSeg(descansoSeg)}' : '';
  }

  Exercicio copy() => Exercicio(
    id: id,
    nome: nome,
    preparacaoSeg: preparacaoSeg,
    execucaoSeg: execucaoSeg,
    descansoSeg: descansoSeg,
    repeticoes: repeticoes,
    series: series,
    descansos: descansos == null ? null : List<int>.of(descansos!),
    pesoKg: pesoKg,
    corIndex: corIndex,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'preparacaoSeg': preparacaoSeg,
    'execucaoSeg': execucaoSeg,
    'descansoSeg': descansoSeg,
    'repeticoes': repeticoes,
    'series': series,
    if (descansos != null) 'descansos': descansos,
    'pesoKg': pesoKg,
    'corIndex': corIndex,
  };

  factory Exercicio.fromJson(Map<String, dynamic> j) {
    // Migração do formato antigo (v0.1.0): lá "repeticoes" significava quantas
    // RODADAS de [execução -> descanso] rodar — ou seja, o que hoje é "séries",
    // sem repetições internas. Preserva o comportamento: series = antigo, reps = 1.
    final temSeries = j.containsKey('series');
    final repsAntigo = (j['repeticoes'] ?? 1) as int;
    final rawDescansos = j['descansos'];
    return Exercicio(
      id: j['id'] as String?,
      nome: (j['nome'] ?? '') as String,
      preparacaoSeg: (j['preparacaoSeg'] ?? 0) as int,
      execucaoSeg: (j['execucaoSeg'] ?? 3) as int,
      descansoSeg: (j['descansoSeg'] ?? 0) as int,
      repeticoes: temSeries ? repsAntigo : 1,
      series: temSeries ? (j['series'] ?? 1) as int : repsAntigo,
      descansos: rawDescansos == null
          ? null
          : (rawDescansos as List).map((e) => e as int).toList(),
      pesoKg: ((j['pesoKg'] ?? 0) as num).toDouble(),
      corIndex: (j['corIndex'] ?? 0) as int,
    );
  }
}
