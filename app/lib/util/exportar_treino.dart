import '../models/exercicio.dart';
import '../models/treino.dart';
import 'dias.dart';
import 'format.dart';

const _assinatura = '— feito no Calis Timer';

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

/// Corpo de um treino (nome + exercícios + duração), SEM a assinatura.
String _corpoTreino(Treino t) {
  final buf = StringBuffer();
  buf.writeln(t.nome.trim().isEmpty ? 'Treino' : t.nome.trim());
  buf.writeln('─────────────────');
  for (var i = 0; i < t.exercicios.length; i++) {
    final e = t.exercicios[i];
    final nome = e.nome.trim().isEmpty ? 'Exercício' : e.nome.trim();
    buf.writeln('${i + 1}. $nome:');
    buf.writeln(_detalhesExercicio(e));
  }
  buf.write('Duração ⏱️ ~${fmtSeg(t.duracaoTotalSeg)}');
  return buf.toString();
}

/// Um treino em texto (para copiar/compartilhar), com assinatura.
String treinoParaTexto(Treino t) => '${_corpoTreino(t)}\n$_assinatura\n';

/// Os treinos de UM dia (pode haver mais de um) em texto, com uma assinatura.
String treinosParaTexto(List<Treino> treinos) =>
    '${treinos.map(_corpoTreino).join('\n\n')}\n$_assinatura\n';

/// TODOS os treinos da semana, separados por dia (Segunda→Domingo). Dias sem
/// treino aparecem como "(descanso)". Uma única assinatura no fim.
String semanaParaTexto(List<Treino> todos) {
  final buf = StringBuffer();
  buf.writeln('MINHA SEMANA');
  buf.writeln('═════════════════');
  for (var d = 0; d < 7; d++) {
    final doDia = todos.where((t) => t.dias.contains(d)).toList();
    buf.writeln('');
    buf.writeln('▶ ${nomesDiasLongos[d].toUpperCase()}');
    if (doDia.isEmpty) {
      buf.writeln('(descanso)');
    } else {
      buf.writeln(doDia.map(_corpoTreino).join('\n\n'));
    }
  }
  buf.writeln('');
  buf.writeln(_assinatura);
  return buf.toString();
}
