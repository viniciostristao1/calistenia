/// Lógica (pura) das insígnias: sorteio DETERMINÍSTICO de até 7 dias por mês, só
/// entre os dias com treino AGENDADO. Determinístico por (semente da conta + ano
/// + mês) — o mesmo resultado em qualquer aparelho e a cada reabertura, sem
/// precisar guardar um "calendário secreto" (continua surpresa para o usuário,
/// que não computa o hash de cabeça). Sem estado nem I/O.
library;

/// Quantas insígnias são sorteadas por mês (o teto de estrelas mensais).
const int insigniasPorMes = 7;

/// Semente estável por conta. **NÃO** usar `String.hashCode` (pode variar entre
/// execuções/plataformas, o que mudaria o sorteio); FNV-1a é determinístico.
/// Sem conta (deslogado), usa uma semente fixa — ainda determinística.
int sementeInsignia(String? uid) =>
    (uid == null || uid.isEmpty) ? (0x811c9dc5 & 0x7fffffff) : _fnv1a(uid);

int _fnv1a(String s) {
  var h = 0x811c9dc5;
  for (final u in s.codeUnits) {
    h = (h ^ u) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

int _hashDia(int semente, int ano, int mes, int dia) {
  var h = semente & 0xffffffff;
  h = (h ^ (ano * 0x9e3779b9)) & 0xffffffff;
  h = (h * 0x85ebca6b) & 0xffffffff;
  h = (h ^ (mes * 0xc2b2ae35)) & 0xffffffff;
  h = (h * 0x27d4eb2f) & 0xffffffff;
  h = (h ^ (dia * 0x94d049bb)) & 0xffffffff;
  h ^= h >> 16;
  h = (h * 0x85ebca6b) & 0xffffffff;
  h ^= h >> 13;
  h = (h * 0xc2b2ae35) & 0xffffffff;
  h ^= h >> 16;
  return h & 0x7fffffff;
}

/// Dias (número do dia) sorteados para insígnia no mês [ano]/[mes]. Só entram os
/// dias cujo dia-da-semana (0=seg..6=dom) está em [agendadosSemana]. Se houver
/// <= 7 candidatos, todos valem; senão, 7 escolhidos de forma determinística
/// (ordena por um hash de (semente, ano, mês, dia) e pega os 7 primeiros).
Set<int> diasInsigniaDoMes(
    int ano, int mes, Set<int> agendadosSemana, int semente) {
  if (agendadosSemana.isEmpty) return const {};
  final diasNoMes = DateTime(ano, mes + 1, 0).day;
  final pool = <int>[];
  for (var dia = 1; dia <= diasNoMes; dia++) {
    if (agendadosSemana.contains(DateTime(ano, mes, dia).weekday - 1)) {
      pool.add(dia);
    }
  }
  if (pool.length <= insigniasPorMes) return pool.toSet();
  pool.sort((a, b) {
    final c = _hashDia(semente, ano, mes, a)
        .compareTo(_hashDia(semente, ano, mes, b));
    return c != 0 ? c : a.compareTo(b);
  });
  return pool.take(insigniasPorMes).toSet();
}

/// O [dia] é um dia de insígnia? (avaliado no fim do treino, ao concluir.)
bool ehDiaDeInsignia(DateTime dia, Set<int> agendadosSemana, int semente) =>
    diasInsigniaDoMes(dia.year, dia.month, agendadosSemana, semente)
        .contains(dia.day);
