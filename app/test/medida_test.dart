import 'package:calistenia/models/medida.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Medida model', () {
    test('json ida e volta preserva id, data e valores', () {
      final m = Medida(
        data: DateTime(2026, 10, 30, 15, 42), // horário é normalizado p/ o dia
        peso: 72.5,
        cintura: 80,
        braco: 35,
      );
      final j = Medida.fromJson(m.toJson());
      expect(j.id, m.id);
      expect(j.data, DateTime(2026, 10, 30));
      expect(j.peso, 72.5);
      expect(j.cintura, 80);
      expect(j.braco, 35);
      expect(j.peito, isNull);
      expect(j.coxa, isNull);
    });

    test('data é normalizada para meia-noite', () {
      final m = Medida(data: DateTime(2026, 1, 2, 23, 59), peso: 70);
      expect(m.data.hour, 0);
      expect(m.data.minute, 0);
    });

    test('temAlgo é falso sem nenhum valor e verdadeiro com um', () {
      expect(Medida(data: DateTime(2026, 1, 1)).temAlgo, isFalse);
      expect(Medida(data: DateTime(2026, 1, 1), coxa: 55).temAlgo, isTrue);
    });

    test('valorDe devolve o campo da métrica pedida', () {
      final m = Medida(data: DateTime(2026, 1, 1), peso: 70, peito: 98);
      expect(m.valorDe(MetricaCorporal.peso), 70);
      expect(m.valorDe(MetricaCorporal.peito), 98);
      expect(m.valorDe(MetricaCorporal.coxa), isNull);
    });

    test('unidade: peso em kg, demais em cm', () {
      expect(MetricaCorporal.peso.unidade, 'kg');
      expect(MetricaCorporal.cintura.unidade, 'cm');
      expect(MetricaCorporal.coxa.unidade, 'cm');
    });

    test('toJson omite campos nulos (não vira 0)', () {
      final j = Medida(data: DateTime(2026, 1, 1), peso: 70).toJson();
      expect(j.containsKey('peso'), isTrue);
      expect(j.containsKey('cintura'), isFalse);
    });
  });
}
