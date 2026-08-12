import '../models/exercicio.dart';
import '../models/treino.dart';
import 'format.dart';

/// Descanso em texto: "1min" ou, se variável por série, "1min–1min 30s".
/// Vazio quando não há descanso.
String _descansoTexto(Exercicio e) {
  final lista = e.descansos;
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
    return mn == mx ? fmtSeg(mn) : '${fmtSeg(mn)}–${fmtSeg(mx)}';
  }
  return e.descansoSeg > 0 ? fmtSeg(e.descansoSeg) : '';
}

/// Linha de detalhes de um exercício:
/// "3×6 repetições · execução 5s/rep · descanso 1min/série | (preparação 10s)".
String _detalhesExercicio(Exercicio e) {
  final series = e.series < 1 ? 1 : e.series;
  final reps = e.repeticoes < 1 ? 1 : e.repeticoes;
  final partes = <String>[];

  if (e.execucaoSeg <= 0) {
    partes.add('$series ${series > 1 ? 'séries' : 'série'} · sem execução');
  } else if (reps > 1) {
    partes.add('$series×$reps repetições · execução ${fmtSeg(e.execucaoSeg)}/rep');
  } else {
    partes.add('$series× ${fmtSeg(e.execucaoSeg)} (isométrico)');
  }

  final desc = _descansoTexto(e);
  if (series > 1 && desc.isNotEmpty) partes.add('descanso $desc/série');
  if (e.pesoKg > 0) partes.add(fmtPeso(e.pesoKg));
  if (e.unilateral) partes.add('um lado por vez');

  var linha = partes.join(' · ');
  if (e.preparacaoSeg > 0) {
    linha += ' | (preparação ${fmtSeg(e.preparacaoSeg)})';
  }
  return linha;
}

/// Gera um treino em texto (para copiar/compartilhar), com detalhes por
/// exercício e a duração total.
String treinoParaTexto(Treino t) {
  final buf = StringBuffer();
  buf.writeln(t.nome.trim().isEmpty ? 'Treino' : t.nome.trim());
  buf.writeln('─────────────────');
  for (var i = 0; i < t.exercicios.length; i++) {
    final e = t.exercicios[i];
    final nome = e.nome.trim().isEmpty ? 'Exercício' : e.nome.trim();
    buf.writeln('${i + 1}. $nome:');
    buf.writeln(_detalhesExercicio(e));
  }
  buf.writeln('');
  buf.writeln('Duração ⏱️ ~${fmtSeg(t.duracaoTotalSeg)}');
  buf.writeln('— feito no Calis Timer');
  return buf.toString();
}

/// Junta vários treinos num texto só.
String treinosParaTexto(List<Treino> treinos) =>
    treinos.map(treinoParaTexto).join('\n\n');
