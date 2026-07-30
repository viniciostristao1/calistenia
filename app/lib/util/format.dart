/// "90" -> "1min 30s"; "30" -> "30s"; "120" -> "2min".
String fmtSeg(int s) {
  final m = s ~/ 60;
  final r = s % 60;
  if (m == 0) return '${r}s';
  if (r == 0) return '${m}min';
  return '${m}min ${r}s';
}

/// "90" -> "01:30" (formato de relógio para o cronômetro).
String fmtRelogio(int s) {
  if (s < 0) s = 0;
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}
