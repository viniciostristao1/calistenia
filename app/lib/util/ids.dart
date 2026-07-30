import 'dart:math';

/// Gera um id único simples (timestamp + aleatório). Sem dependência externa.
String novoId() {
  final t = DateTime.now().microsecondsSinceEpoch;
  final r = Random().nextInt(0x7fffffff);
  return '$t-$r';
}
