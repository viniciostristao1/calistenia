/// "90" -> "1min 30s"; "30" -> "30s"; "120" -> "2min".
String fmtSeg(int s) {
  final m = s ~/ 60;
  final r = s % 60;
  if (m == 0) return '${r}s';
  if (r == 0) return '${m}min';
  return '${m}min ${r}s';
}

/// 10.0 -> "10kg"; 2.5 -> "2,5kg".
String fmtPeso(double kg) {
  if (kg == kg.roundToDouble()) return '${kg.toInt()}kg';
  return '${kg.toStringAsFixed(1).replaceAll('.', ',')}kg';
}

/// DateTime -> "14:05" (hora:minuto).
String fmtHora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// DateTime -> "31/07" (dia/mês, 2 dígitos).
String fmtDataCurta(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// DateTime -> "31/07/26" (com ano curto).
String fmtDataAno(DateTime d) =>
    '${fmtDataCurta(d)}/${(d.year % 100).toString().padLeft(2, '0')}';

/// "90" -> "01:30" (formato de relógio para o cronômetro).
String fmtRelogio(int s) {
  if (s < 0) s = 0;
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}
