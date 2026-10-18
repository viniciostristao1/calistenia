import '../util/ids.dart';

/// Uma nota livre do bloco de notas (aba Check-in).
/// Só texto + instante da última edição; o [id] é estável e serve à
/// união por id do sync (mesmo padrão dos outros stores).
class Nota {
  final String id;
  final String texto;
  final DateTime atualizadoEm;

  Nota({String? id, this.texto = '', DateTime? atualizadoEm})
    : id = id ?? novoId(),
      atualizadoEm =
          atualizadoEm ?? DateTime.now();

  Nota copyComTexto(String novoTexto) =>
      Nota(id: id, texto: novoTexto, atualizadoEm: DateTime.now());

  Map<String, dynamic> toJson() => {
    'id': id,
    'texto': texto,
    'atualizadoEm': atualizadoEm.millisecondsSinceEpoch,
  };

  factory Nota.fromJson(Map<String, dynamic> j) => Nota(
    id: j['id'] as String? ?? novoId(),
    texto: (j['texto'] ?? '') as String,
    atualizadoEm: j['atualizadoEm'] == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(j['atualizadoEm'] as int),
  );
}

/// Texto pronto p/ copiar: as notas numeradas, separadas por linha em branco.
/// Puro/testável. Notas vazias são ignoradas.
String notasParaTexto(List<Nota> notas) {
  final cheias = notas.where((n) => n.texto.trim().isNotEmpty).toList();
  if (cheias.isEmpty) return '';
  final buf = StringBuffer();
  for (var i = 0; i < cheias.length; i++) {
    if (i > 0) buf.writeln('\n---\n');
    buf.write(cheias[i].texto.trim());
  }
  return buf.toString();
}
