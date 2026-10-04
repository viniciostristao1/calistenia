import '../models/conclusao.dart';
import '../models/registro_progressao.dart';
import '../models/treino.dart';
import '../services/progressao_repository.dart' show agruparPorExercicio;
import 'gamificacao.dart';

/// **Treinador (on-device):** lê os dados locais e monta o RESUMO DA SEMANA +
/// dicas inteligentes. Lógica pura (sem I/O, sem UI) — fácil de testar. Nada sai
/// do aparelho.

/// Para onde um insight pode levar (a UI mapeia para a aba).
enum InsightAcao { nenhuma, progressao, conquistas, treinos }

/// Uma dica inteligente (texto + ação opcional de 1 toque).
class Insight {
  final String emoji;
  final String titulo;
  final String texto;
  final InsightAcao acao;
  final String? acaoLabel;
  const Insight(
    this.emoji,
    this.titulo,
    this.texto, {
    this.acao = InsightAcao.nenhuma,
    this.acaoLabel,
  });
}

/// O resumo da semana + as dicas.
class ResumoSemana {
  final int completos; // conclusões completas nesta semana (seg→hoje)
  final int completosAnterior; // semana passada
  final int sequencia; // chama atual
  final int recorde; // recorde da chama
  final int diasTreinados; // dias distintos com atividade nesta semana
  final int rating; // rating atual (com bônus)
  final int ratingAnterior; // rating 7 dias atrás
  final List<String> recordesRecentes; // "Nome · N reps/kg" (últimos 7 dias)
  final List<Insight> insights; // já priorizadas (até 3)
  const ResumoSemana({
    required this.completos,
    required this.completosAnterior,
    required this.sequencia,
    required this.recorde,
    required this.diasTreinados,
    required this.rating,
    required this.ratingAnterior,
    required this.recordesRecentes,
    required this.insights,
  });

  int get deltaCompletos => completos - completosAnterior;
  int get deltaRating => rating - ratingAnterior;
}

DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

const _diasPlural = [
  'segundas',
  'terças',
  'quartas',
  'quintas',
  'sextas',
  'sábados',
  'domingos',
];
const _diasSingular = [
  'segunda',
  'terça',
  'quarta',
  'quinta',
  'sexta',
  'sábado',
  'domingo',
];

/// Nome da conquista por nível-alvo (os tiers de [tiersPremios]).
String _nomeTier(int tier) => switch (tier) {
  4 => 'Medalha de Prata',
  8 => 'Medalha de Ouro',
  15 => 'Troféu de Prata',
  21 => 'Troféu de Ouro',
  _ => 'próxima conquista',
};

ResumoSemana montarResumo(
  List<Conclusao> concs,
  List<Treino> treinos,
  List<RegistroProgressao> prog,
  List<DateTime> diasCheckin, {
  DateTime? hoje,
  Set<DateTime> diasEscudo = const {},
  bool temEscudoReserva = false,
}) {
  final hj = _d(hoje ?? DateTime.now());
  final inicioSemana = hj.subtract(Duration(days: hj.weekday - 1)); // segunda
  final inicioAnterior = inicioSemana.subtract(const Duration(days: 7));
  final diasValidos = diasCheckin.map(_d).toSet();

  bool naSemana(DateTime d, DateTime ini) =>
      !_d(d).isBefore(ini) && _d(d).isBefore(ini.add(const Duration(days: 7)));

  // "Completos" = nº de TREINOS completos (sessões), não dias: 2 no mesmo dia = 2.
  final completos = concs
      .where((c) => c.completo && naSemana(c.data, inicioSemana))
      .length;
  final completosAnterior = concs
      .where((c) => c.completo && naSemana(c.data, inicioAnterior))
      .length;
  final diasTreinados = {
    for (final c in concs)
      if (naSemana(c.data, inicioSemana)) _d(c.data),
    for (final d in diasCheckin)
      if (naSemana(d, inicioSemana)) _d(d),
  }.length;

  final sequencia = sequenciaIninterrupta(
    concs,
    treinos,
    hoje: hj,
    diasValidos: diasValidos,
    diasEscudo: diasEscudo,
  );
  final recorde = sequenciaRecorde(
    concs,
    treinos,
    hoje: hj,
    diasValidos: diasValidos,
    diasEscudo: diasEscudo,
  );

  final agendados = diasAgendados(treinos);

  final rf = ratingForma(concs, treinos, prog, hoje: hj);
  final rating = rf.totalComBonus;
  final seteAtras = hj.subtract(const Duration(days: 7));
  // Aproximação: usa a AGENDA ATUAL para o rating de 7 dias atrás (se você mudou
  // os dias dos treinos, o "vs" pode desviar um pouco — aceitável p/ tendência).
  final ratingAnterior = ratingForma(
    concs.where((c) => !_d(c.data).isAfter(seteAtras)).toList(),
    treinos,
    prog.where((r) => !_d(r.data).isAfter(seteAtras)).toList(),
    hoje: seteAtras,
  ).totalComBonus;

  // Recordes dos últimos 7 dias + platô (exercício ativo há mais tempo sem recorde).
  final ativos = exerciciosDistintos(treinos);
  final grupos = agruparPorExercicio(prog);
  final recordesRecentes = <String>[];
  String? platoNome;
  int platoDias = 0;
  for (final g in grupos) {
    final nome = g.exercicio.trim();
    if (!ativos.contains(nome.toLowerCase())) continue;
    if (g.registros.length < 2) continue;
    // Data em que o MELHOR atual foi atingido (reps ou peso).
    DateTime? dReps, dPeso;
    for (final r in g.registros) {
      if (r.valor == g.maior && (dReps == null || r.data.isAfter(dReps))) {
        dReps = r.data;
      }
      if (g.maiorPeso > 0 &&
          r.peso == g.maiorPeso &&
          (dPeso == null || r.data.isAfter(dPeso))) {
        dPeso = r.data;
      }
    }
    final ultimoRecorde = [dReps, dPeso].whereType<DateTime>().fold<DateTime?>(
      null,
      (a, b) => a == null || b.isAfter(a) ? b : a,
    );
    if (ultimoRecorde == null) continue;
    final dias = hj.difference(_d(ultimoRecorde)).inDays;
    // recorde recente?
    if (dias <= 7) {
      if (g.maior > g.primeiro) recordesRecentes.add('$nome · ${g.maior} reps');
      if (g.maiorPeso > 0 && g.maiorPeso > g.primeiroPeso) {
        recordesRecentes.add(
          '$nome · ${g.maiorPeso.toStringAsFixed(g.maiorPeso.truncateToDouble() == g.maiorPeso ? 0 : 1)} kg',
        );
      }
    }
    // platô (maior tempo sem recorde)
    if (dias > platoDias) {
      platoDias = dias;
      platoNome = nome;
    }
  }

  // ─── insights (prioridade: risco de hoje → platô → meta → falha → reforço) ───
  final candidatos = <Insight>[];

  // RISCO DE HOJE (a mais urgente/"agêntica"): hoje é dia agendado, ainda não
  // concluído, e há uma chama a perder.
  final hojeWd = hj.weekday - 1;
  final hojeCompleto =
      diasEscudo.map(_d).contains(hj) ||
      concs.any((c) => _d(c.data) == hj && c.completo);
  if (agendados.contains(hojeWd) && !hojeCompleto && sequencia > 0) {
    final seqTxt = sequencia == 1 ? '1 dia' : '$sequencia dias';
    candidatos.add(
      Insight(
        '⚠️',
        'Sua chama está em risco',
        temEscudoReserva
            ? 'Você tem treino hoje e a sequência de $seqTxt zera se faltar. '
                  'Bora treinar — e você ainda tem um 🛡️ escudo de reserva se faltar.'
            : 'Você tem treino hoje e a sequência de $seqTxt zera se faltar. '
                  'Bora manter a chama acesa!',
        acao: InsightAcao.treinos,
        acaoLabel: 'Treinar agora',
      ),
    );
  }

  final temPlato = platoNome != null && platoDias >= 10;
  if (temPlato) {
    candidatos.add(
      Insight(
        '📈',
        'Platô no $platoNome',
        'Faz $platoDias dias sem bater recorde. Que tal tentar +1 repetição '
            '(ou um pouco mais de carga) hoje?',
        acao: InsightAcao.progressao,
        acaoLabel: 'Ver progressão',
      ),
    );
  }

  // GARGALO do Rating: o componente mais fraco (como % do seu teto). Dá o elo a
  // puxar. Se o fraco for a Progressão e já houver platô, não repete.
  final somaComp = rf.consistencia + rf.frequencia + rf.progressao;
  if (somaComp > 0) {
    final frac = {
      'consistencia': rf.consistencia / 400,
      'frequencia': rf.frequencia / 200,
      'progressao': rf.progressao / 400,
    };
    final menor = frac.entries.reduce((a, b) => a.value <= b.value ? a : b);
    if (!(menor.key == 'progressao' && temPlato)) {
      final (emoji, titulo, texto, acao, label) = switch (menor.key) {
        'consistencia' => (
          '🎯',
          'Reforce a consistência',
          'No Rating, a Consistência é seu elo mais fraco. Cumprir os dias '
              'agendados (mesmo um treino curto) é o que mais sobe a nota.',
          InsightAcao.nenhuma,
          null,
        ),
        'frequencia' => (
          '📅',
          'Aumente a frequência',
          'Sua Frequência é o que mais puxa o Rating pra baixo. Treinar mais '
              'vezes na semana ajuda bastante.',
          InsightAcao.nenhuma,
          null,
        ),
        _ => (
          '📈',
          'Puxe a progressão',
          'Sua Progressão é o que mais segura o Rating. Bater um recorde (reps '
              'ou carga) destrava pontos.',
          InsightAcao.progressao,
          'Ver progressão',
        ),
      };
      candidatos.add(
        Insight(emoji, titulo, texto, acao: acao, acaoLabel: label),
      );
    }
  }

  // Meta próxima: recorde de sequência OU próxima conquista.
  if (sequencia > 0 && recorde - sequencia >= 1 && recorde - sequencia <= 2) {
    final faltam = recorde - sequencia;
    candidatos.add(
      Insight(
        '🔥',
        'Quase no seu recorde',
        'Mais ${faltam == 1 ? '1 dia' : '$faltam dias'} e você iguala seu '
            'recorde de sequência ($recorde dias). Não quebre a corrente!',
      ),
    );
  } else {
    final nivel = nivelInfo(concs, treinos, diasValidos: diasValidos).atual;
    for (final tier in tiersPremios) {
      final faltam = tier - nivel;
      if (faltam >= 1 && faltam <= 2) {
        candidatos.add(
          Insight(
            '🏅',
            'Perto de uma conquista',
            'Faltam ${faltam == 1 ? '1 dia' : '$faltam dias'} de treino '
                'completo para a ${_nomeTier(tier)}.',
            acao: InsightAcao.conquistas,
            acaoLabel: 'Ver conquistas',
          ),
        );
        break;
      }
    }
  }

  // Falha por dia da semana (últimos 28 dias).
  final falhasWd = List<int>.filled(7, 0);
  final totalWd = List<int>.filled(7, 0);
  final completoReal = <DateTime, bool>{};
  for (final c in concs) {
    final d = _d(c.data);
    if (!diasValidos.contains(d)) continue;
    completoReal[d] = (completoReal[d] ?? false) || c.completo;
  }
  for (final e in diasEscudo) {
    completoReal[_d(e)] = true;
  }
  for (var k = 1; k <= 28; k++) {
    final d = hj.subtract(Duration(days: k));
    final wd = d.weekday - 1;
    if (!agendados.contains(wd)) continue;
    totalWd[wd]++;
    if (completoReal[d] != true) falhasWd[wd]++;
  }
  // pior dia (mais falhas, >=2)
  var piorWd = -1;
  for (var w = 0; w < 7; w++) {
    if (falhasWd[w] >= 2 && (piorWd < 0 || falhasWd[w] > falhasWd[piorWd])) {
      piorWd = w;
    }
  }
  if (piorWd >= 0) {
    candidatos.add(
      Insight(
        '🗓️',
        'Seu ponto fraco são as ${_diasPlural[piorWd]}',
        'Você falhou ${falhasWd[piorWd]}x nas ${_diasPlural[piorWd]} no último '
            'mês. Até um treino curto nesse dia mantém a sua sequência.',
        acao: InsightAcao.treinos,
        acaoLabel: 'Ver treinos',
      ),
    );
  }

  // Reforço positivo (melhor dia 100%, >=2 ocorrências) — fallback garantido.
  var melhorWd = -1;
  double melhorTaxa = -1;
  for (var w = 0; w < 7; w++) {
    if (totalWd[w] >= 2) {
      final taxa = (totalWd[w] - falhasWd[w]) / totalWd[w];
      if (taxa >= 0.999 && taxa > melhorTaxa) {
        melhorTaxa = taxa;
        melhorWd = w;
      }
    }
  }
  if (melhorWd >= 0) {
    candidatos.add(
      Insight(
        '💪',
        'Seu dia mais forte é ${_diasSingular[melhorWd]}',
        'Você concluiu 100% das ${_diasPlural[melhorWd]} no último mês. Mandou bem!',
      ),
    );
  }
  if (candidatos.isEmpty) {
    candidatos.add(
      const Insight(
        '🌱',
        'Comece a sua história',
        'Conclua treinos para o Treinador aprender seus padrões e te dar dicas '
            'personalizadas por aqui.',
      ),
    );
  }

  return ResumoSemana(
    completos: completos,
    completosAnterior: completosAnterior,
    sequencia: sequencia,
    recorde: recorde,
    diasTreinados: diasTreinados,
    rating: rating,
    ratingAnterior: ratingAnterior,
    recordesRecentes: recordesRecentes.toSet().toList(),
    insights: candidatos.take(4).toList(),
  );
}
