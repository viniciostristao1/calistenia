import '../models/treino.dart';
import 'format.dart';

/// Gera um treino em texto simples (para copiar/compartilhar).
String treinoParaTexto(Treino t) {
  final buf = StringBuffer();
  buf.writeln(t.nome.trim().isEmpty ? 'Treino' : t.nome.trim());
  buf.writeln('─────────────');
  for (var i = 0; i < t.exercicios.length; i++) {
    final e = t.exercicios[i];
    final nome = e.nome.trim().isEmpty ? 'Exercício' : e.nome.trim();
    final prep =
        e.preparacaoSeg > 0 ? ' (prep ${fmtSeg(e.preparacaoSeg)})' : '';
    buf.writeln('${i + 1}. $nome — ${e.resumoCurto}$prep');
  }
  buf.writeln('');
  buf.writeln('Duração ~${fmtSeg(t.duracaoTotalSeg)}');
  buf.writeln('— feito no Calis Timer');
  return buf.toString();
}

/// Junta vários treinos num texto só.
String treinosParaTexto(List<Treino> treinos) =>
    treinos.map(treinoParaTexto).join('\n\n');
