import 'package:calistenia/models/nota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nota model', () {
    test('json ida e volta preserva id e texto', () {
      final n = Nota(texto: 'fazer 3x12 flexões');
      final j = Nota.fromJson(n.toJson());
      expect(j.id, n.id);
      expect(j.texto, 'fazer 3x12 flexões');
    });

    test('copyComTexto troca o texto mantendo o id', () {
      final n = Nota(texto: 'a');
      final b = n.copyComTexto('b');
      expect(b.id, n.id);
      expect(b.texto, 'b');
    });
  });

  group('notasParaTexto (copiar)', () {
    test('vazio quando só há notas vazias', () {
      expect(notasParaTexto([]), '');
      expect(notasParaTexto([Nota(texto: '  ')]), '');
    });

    test('concatena várias notas numeradas com separador', () {
      final texto = notasParaTexto([
        Nota(texto: 'primeira'),
        Nota(texto: '  '),
        Nota(texto: 'segunda'),
      ]);
      expect(texto.contains('primeira'), isTrue);
      expect(texto.contains('segunda'), isTrue);
      expect(texto.contains('---'), isTrue);
    });
  });
}
