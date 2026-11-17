import '../models/checkin.dart';
import '../models/conclusao.dart';
import '../models/conquista.dart';
import '../models/escudo.dart';
import '../models/insignia.dart';
import '../models/medida.dart';
import '../models/nota.dart';
import '../models/registro_progressao.dart';
import '../models/treino.dart';
import '../util/dias.dart';
import '../util/extrato_rating.dart';
import '../util/format.dart';
import '../util/gamificacao.dart';

/// Resumo do treino para a Muse (texto para colar no chat + arquivo `.md`).
///
/// Tudo aqui é PURO (só monta texto a partir das listas) e em pt-BR — o
/// conteúdo é pessoal, para a IA do usuário, não texto de interface.
/// Regras de contagem espelham o proxy (`calis_resumo.py`): dias em data de
/// Brasília entram como datas locais; sequência conta hoje, senão ontem, para
/// trás sem falhar; "último recorde há Nd" nunca é recalculado pela IA.
///
/// Limites honestos do que EXISTE nos dados (não inventar):
/// - tempo/descanso = DO PLANO (`duracaoTotalSeg`, `resumoCurto`) — o app não
///   registra tempo executado da sessão; vem rotulado como plano.
/// - rating = `ratingForma`/`extratoRating` (nota 0–1000 + bônus e ganho do dia).
class ResumoClaude {
  const ResumoClaude._();

  static const _diasSemana = [
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _diaTxt(DateTime d) =>
      '${fmtDataCurta(d)} (${_diasSemana[d.weekday - 1]})';

  static String _diasTxt(int n, String um, String varios) =>
      n == 1 ? '1 $um' : '$n $varios';

  /// Dias com treino (check-in OU conclusão), do mais recente ao mais antigo.
  static List<DateTime> diasTreinados(
    List<CheckIn> checkins,
    List<Conclusao> conclusoes,
  ) {
    final dias = <DateTime>{
      for (final c in checkins) _dia(c.data),
      for (final c in conclusoes) _dia(c.data),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return dias;
  }

  /// Sequência atual: conta hoje; se hoje não tem, começa de ontem.
  static int sequencia(DateTime hoje, List<DateTime> diasDesc) {
    final set = diasDesc.toSet();
    var cur = _dia(hoje);
    if (!set.contains(cur)) cur = cur.subtract(const Duration(days: 1));
    var n = 0;
    while (set.contains(cur)) {
      n++;
      cur = cur.subtract(const Duration(days: 1));
    }
    return n;
  }

  static List<Conclusao> _conclusoesDoDia(
          List<Conclusao> todas, DateTime dia) =>
      todas.where((c) => mesmoDia(c.data, dia)).toList();

  static List<CheckIn> _checkinsDoDia(List<CheckIn> todos, DateTime dia) =>
      todos.where((c) => mesmoDia(c.data, dia)).toList();

  static List<RegistroProgressao> _progressaoDoDia(
          List<RegistroProgressao> todas, DateTime dia) =>
      todas.where((p) => mesmoDia(p.data, dia)).toList();

  static String _valorProg(RegistroProgressao p) =>
      p.peso > 0 ? '${p.valor}x${fmtPeso(p.peso)}' : '${p.valor} reps';

  /// Linha do rating atual ("Rating: 742/1000 (+12 hoje).").
  static String linhaRating({
    required DateTime hoje,
    required List<Conclusao> conclusoes,
    required List<Treino> treinos,
    required List<RegistroProgressao> progressoes,
    required List<Insignia> insignias,
    required List<Escudo> escudos,
  }) {
    final diasIns = {for (final i in insignias) _dia(i.data)};
    final diasEsc = {for (final e in escudos) _dia(e.ganhoEm)};
    final forma = ratingForma(
      conclusoes,
      treinos,
      progressoes,
      hoje: hoje,
      diasInsignia: diasIns,
      diasEscudoGanho: diasEsc,
    );
    final ganho = ratingDoDia(conclusoes, treinos, progressoes, hoje: hoje);
    final sinal = ganho >= 0 ? '+' : '';
    return 'Rating: ${forma.totalComBonus}/1000 ($sinal$ganho hoje).';
  }

  static Treino? _treinoDe(Conclusao c, List<Treino> treinos) {
    for (final t in treinos) {
      if (t.id == c.treinoId) return t;
    }
    return null;
  }

  /// Grade fixa da semana a partir de `Treino.dias` (0=seg .. 6=dom).
  /// Vazia quando não há treinos. Dia sem treino vira "— descanso —";
  /// treino ativo sem dia cai na linha "Sem dia definido". Exercício
  /// arquivado não aparece (já saiu dos treinos). Só usa nome/estrutura do
  /// plano — nunca medidas, notas, uid ou e-mail.
  static String blocoPlanoSemanal(
      List<Treino> treinos, String atualizadoEm) {
    if (treinos.isEmpty) return '';
    final porDia = List.generate(7, (_) => <Treino>[]);
    final semDia = <Treino>[];
    for (final t in treinos) {
      if (t.dias.isEmpty) {
        semDia.add(t);
      } else {
        for (final d in t.dias) {
          if (d >= 0 && d < 7) porDia[d].add(t);
        }
      }
    }
    String descrever(Treino t) {
      final nome = t.nome.trim().isEmpty ? 'Treino' : t.nome;
      if (t.exercicios.isEmpty) return nome;
      final ex = t.exercicios.map((e) => '${e.nome} ${e.resumoCurto}');
      return '$nome (${ex.join(' | ')})';
    }

    final b = StringBuffer('## Plano semanal (atualizado em $atualizadoEm)\n');
    for (var d = 0; d < 7; d++) {
      final doDia = porDia[d];
      b.writeln(doDia.isEmpty
          ? '- ${nomesDiasLongos[d]}: — descanso —'
          : '- ${nomesDiasLongos[d]}: ${doDia.map(descrever).join(' ;; ')}');
    }
    if (semDia.isNotEmpty) {
      b.writeln(
          '- Sem dia definido: ${semDia.map(descrever).join(' ;; ')}');
    }
    return b.toString();
  }

  /// Linha de abertura ("Completei o treino hoje, agora são N dias…").
  static String fraseStreak(
    DateTime hoje,
    List<CheckIn> checkins,
    List<Conclusao> conclusoes,
  ) {
    final h = _dia(hoje);
    final dias = diasTreinados(checkins, conclusoes);
    final seq = sequencia(hoje, dias);
    final completasHoje =
        _conclusoesDoDia(conclusoes, h).where((c) => c.completo).toList();
    if (completasHoje.isNotEmpty) {
      final seguidos = seq == 1
          ? 'agora é 1 dia seguido.'
          : 'agora são $seq dias seguidos.';
      return 'Completei o treino hoje, $seguidos';
    }
    final algumaHoje = _conclusoesDoDia(conclusoes, h).isNotEmpty ||
        _checkinsDoDia(checkins, h).isNotEmpty;
    final base = algumaHoje
        ? 'Treinei hoje mas não completei o treino.'
        : 'Ainda não treinei hoje.';
    final seqTxt = seq == 0
        ? 'Sequência atual: 0 dias.'
        : seq == 1
            ? 'Sequência atual: 1 dia seguido.'
            : 'Sequência atual: $seq dias seguidos.';
    final completosAntes = [
      for (final c in conclusoes)
        if (c.completo && _dia(c.data).isBefore(h)) _dia(c.data)
    ]..sort((a, b) => b.compareTo(a));
    final gap = completosAntes.isEmpty
        ? ''
        : ' Último treino completo há '
            '${_diasTxt(h.difference(completosAntes.first).inDays, 'dia', 'dias')} '
            '(${_diaTxt(completosAntes.first)}).';
    return '$base $seqTxt$gap';
  }

  /// Texto curto do dia (botão "Copiar de hoje"): frase + sessão de hoje.
  static String textoHoje({
    required DateTime hoje,
    required List<CheckIn> checkins,
    required List<Conclusao> conclusoes,
    required List<RegistroProgressao> progressoes,
    required List<Treino> treinos,
    List<Insignia> insignias = const [],
    List<Escudo> escudos = const [],
  }) {
    final h = _dia(hoje);
    final b = StringBuffer(fraseStreak(hoje, checkins, conclusoes));
    final conclHoje = _conclusoesDoDia(conclusoes, h);
    final checksHoje = _checkinsDoDia(checkins, h);
    final progHoje = _progressaoDoDia(progressoes, h);
    if (conclHoje.isEmpty && checksHoje.isEmpty && progHoje.isEmpty) {
      return '$b Nada registrado hoje ainda.';
    }
    for (final c in conclHoje) {
      final t = _treinoDe(c, treinos);
      final estado = c.completo ? 'completo' : 'incompleto';
      b.write(' Treino: ${c.treino} ($estado).');
      if (t != null) {
        b.write(' Plano: ${t.duracaoTotalSeg > 0 ? '±${fmtSeg(t.duracaoTotalSeg)}' : 'sem tempo'}; ');
        b.write(t.exercicios.map((e) => '${e.nome} ${e.resumoCurto}').join(' | '));
        b.write('.');
      }
    }
    if (checksHoje.isNotEmpty) {
      b.write(' Feito: ${checksHoje.map((c) => c.exercicio).join(', ')}.');
    }
    if (progHoje.isNotEmpty) {
      b.write(' Números de hoje: ${progHoje.map((p) => '${p.exercicio} ${_valorProg(p)}').join('; ')}.');
    }
    b.write(' ${linhaRating(hoje: hoje, conclusoes: conclusoes, treinos: treinos, progressoes: progressoes, insignias: insignias, escudos: escudos)}');
    return b.toString();
  }

  /// Arquivo `.md` com hoje + últimos 15 dias + progressão 3 meses + totais.
  static String arquivoQuinzena({
    required DateTime hoje,
    required List<CheckIn> checkins,
    required List<Conclusao> conclusoes,
    required List<RegistroProgressao> progressoes,
    required List<Treino> treinos,
    required List<Conquista> conquistas,
    required List<Insignia> insignias,
    required List<Escudo> escudos,
    List<Medida> medidas = const [],
    List<Nota> notas = const [],
  }) {
    final h = _dia(hoje);
    final b = StringBuffer()
      ..writeln('# Treino — resumo para a Muse (${fmtDataCurta(h)})')
      ..writeln()
      ..writeln(fraseStreak(hoje, checkins, conclusoes))
      ..writeln()
      ..writeln('_Tempo e descanso abaixo são DO PLANO (o app não registra '
          'tempo executado da sessão)._')
      ..writeln();

    // ── plano semanal (grade fixa; responde "qual é o treino de terça?") ──
    final plano = blocoPlanoSemanal(treinos, fmtDataCurta(h));
    if (plano.isNotEmpty) {
      b.writeln(plano);
    }

    // ── dia a dia (15 dias, hoje incluso) ──
    b.writeln('## Últimos 15 dias');
    for (var i = 0; i < 15; i++) {
      final dia = h.subtract(Duration(days: i));
      final concl = _conclusoesDoDia(conclusoes, dia);
      final checks = _checkinsDoDia(checkins, dia);
      final prog = _progressaoDoDia(progressoes, dia);
      if (concl.isEmpty && checks.isEmpty && prog.isEmpty) {
        b.writeln('- ${_diaTxt(dia)}: sem treino.');
        continue;
      }
      final partes = <String>[];
      for (final c in concl) {
        final t = _treinoDe(c, treinos);
        var s =
            '${c.treino} (${c.completo ? 'completo' : 'incompleto'}';
        if (t != null && t.duracaoTotalSeg > 0) {
          s += ', plano ±${fmtSeg(t.duracaoTotalSeg)}';
        }
        s += ')';
        partes.add(s);
        if (t != null) {
          partes.add(t.exercicios
              .map((e) => '${e.nome} ${e.resumoCurto}')
              .join(' | '));
        }
      }
      if (checks.isNotEmpty) {
        partes.add('check-ins: ${checks.map((c) => c.exercicio).join(', ')}');
      }
      if (prog.isNotEmpty) {
        partes.add(
            'feito: ${prog.map((p) => '${p.exercicio} ${_valorProg(p)}').join('; ')}');
      }
      b.writeln('- ${_diaTxt(dia)}: ${partes.join(' — ')}');
    }
    b.writeln();

    // ── progressão 3 meses por exercício ──
    final corte90 = h.subtract(const Duration(days: 90));
    final porEx = <String, List<RegistroProgressao>>{};
    for (final p in progressoes) {
      if (_dia(p.data).isBefore(corte90)) continue;
      porEx.putIfAbsent(p.exercicio, () => []).add(p);
    }
    final ativos = {
      for (final t in treinos)
        for (final e in t.exercicios) e.nome,
    };
    b.writeln('## Progressão (últimos 3 meses, por exercício)');
    if (porEx.isEmpty) {
      b.writeln('Sem registros no período.');
    } else {
      final nomes = porEx.keys.toList()..sort();
      for (final ex in nomes) {
        final regs = porEx[ex]!..sort((a, b) => a.data.compareTo(b.data));
        final a = regs.first, z = regs.last;
        final evo = a.valor == z.valor && a.peso == z.peso
            ? _valorProg(z)
            : '${_valorProg(a)} → ${_valorProg(z)}';
        final gap = h.difference(_dia(z.data)).inDays;
        final flag = ativos.contains(ex) ? '[ativo]' : '[fora dos treinos]';
        b.writeln('- $ex $flag: $evo (${regs.length} registro(s); '
            'último recorde há ${_diasTxt(gap, 'dia', 'dias')}).');
      }
    }
    b.writeln();

    // ── totais ──
    final dias = diasTreinados(checkins, conclusoes).toSet();
    final em15 = dias.where((d) => h.difference(d).inDays < 15).length;
    final em90 = dias.where((d) => h.difference(d).inDays < 90).length;
    final conclTodas = conclusoes.length;
    final conclCompletas = conclusoes.where((c) => c.completo).length;
    b.writeln('## Totais');
    b.writeln('- 15 dias: $em15 treinados × ${15 - em15} sem treino.');
    b.writeln('- 90 dias: $em90 dias treinados.');
    b.writeln(
        '- Check-ins: ${checkins.length}; conclusões: $conclTodas ($conclCompletas completas).');
    final ativas =
        conquistas.where((c) => c.perdidaEm == null).toList();
    if (ativas.isNotEmpty) {
      b.writeln(
          '- Conquistas: ${ativas.map((c) => '${_emojiConquista(c.tipo)} ${c.tipo}').join('; ')}.');
    }
    if (insignias.isNotEmpty) {
      b.writeln('- Insígnias (estrelas mensais): ${insignias.length}.');
    }
    final guardados = escudos.where((e) => e.usadoEm == null).length;
    final usados = escudos.length - guardados;
    if (escudos.isNotEmpty) {
      b.writeln('- Escudos: $guardados guardado(s), $usados usado(s).');
    }
    b.writeln();

    // ── rating ──
    b.writeln('## Rating');
    b.writeln(linhaRating(
      hoje: hoje,
      conclusoes: conclusoes,
      treinos: treinos,
      progressoes: progressoes,
      insignias: insignias,
      escudos: escudos,
    ));
    final extrato = extratoRating(
      conclusoes,
      treinos,
      progressoes,
      diasInsignia: {for (final i in insignias) _dia(i.data)},
      diasEscudo: {for (final e in escudos) _dia(e.ganhoEm)},
      hoje: hoje,
      max: 10,
    );
    if (extrato.isNotEmpty) {
      b.writeln('Últimas pontuações: ${extrato.map((p) => '${fmtDataCurta(p.data)} ${p.emoji} +${p.pontos} (${p.motivo})').join('; ')}.');
    }
    b.writeln();

    // ── medidas corporais ──
    if (medidas.isNotEmpty) {
      final ord = [...medidas]..sort((a, b) => a.data.compareTo(b.data));
      final ultimas = ord.length <= 5 ? ord : ord.sublist(ord.length - 5);
      b.writeln('## Medidas corporais (peso em kg, resto em cm)');
      for (final m in ultimas) {
        final partes = <String>[];
        if (m.peso != null) partes.add('peso ${fmtPeso(m.peso!)}');
        if (m.cintura != null) partes.add('cintura ${_fmtCm(m.cintura!)}');
        if (m.braco != null) partes.add('braço ${_fmtCm(m.braco!)}');
        if (m.peito != null) partes.add('peito ${_fmtCm(m.peito!)}');
        if (m.coxa != null) partes.add('coxa ${_fmtCm(m.coxa!)}');
        if (partes.isEmpty) continue;
        b.writeln('- ${_diaTxt(_dia(m.data))}: ${partes.join(' · ')}.');
      }
      final evo = _evolucaoMedidas(ord);
      if (evo.isNotEmpty) {
        b.writeln(
            'Evolução (${_diaTxt(_dia(ord.first.data))} → ${_diaTxt(_dia(ord.last.data))}): $evo.');
      }
      b.writeln();
    }

    // ── notas livres ──
    final textoNotas = notasParaTexto(notas);
    if (textoNotas.isNotEmpty) {
      b.writeln('## Notas');
      b.writeln(textoNotas);
      b.writeln();
    }
    return b.toString();
  }

  /// "70" em vez de "70,0" (cm das medidas; o peso usa `fmtPeso`).
  static String _fmtCm(double v) => v == v.roundToDouble()
      ? '${v.toInt()}'
      : v.toStringAsFixed(1).replaceAll('.', ',');

  /// Primeira → última por métrica (só as que têm valor nos dois extremos).
  static String _evolucaoMedidas(List<Medida> ord) {
    if (ord.length < 2) return '';
    final a = ord.first, z = ord.last;
    final partes = <String>[];
    void par(String nome, double? va, double? vz, String Function(double) fmt) {
      if (va == null || vz == null) return;
      partes.add('$nome ${fmt(va)} → ${fmt(vz)}');
    }

    par('peso', a.peso, z.peso, fmtPeso);
    par('cintura', a.cintura, z.cintura, _fmtCm);
    par('braço', a.braco, z.braco, _fmtCm);
    par('peito', a.peito, z.peito, _fmtCm);
    par('coxa', a.coxa, z.coxa, _fmtCm);
    return partes.join('; ');
  }

  static String _emojiConquista(String tipo) => switch (tipo) {
        'medalhaPrata' => '🥈',
        'medalhaOuro' => '🥇',
        _ => '🏆',
      };
}
