import 'package:calistenia/models/conclusao.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/registro_progressao.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/util/gamificacao.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cobre a "Opção A": aumento de PESO conta como progressão (melhor-dos-dois),
/// sem prejudicar quem só evolui por repetições (bodyweight).
void main() {
  final hoje = DateTime(2026, 8, 25);
  Treino treinoCom(String ex) =>
      Treino(nome: 'T', dias: const [0], exercicios: [Exercicio(nome: ex)]);

  group('RegistroProgressao com peso', () {
    test('JSON round-trip preserva o peso', () {
      final r = RegistroProgressao(
          exercicio: 'Agachamento',
          valor: 8,
          peso: 42.5,
          data: DateTime(2026, 8, 20));
      final v = RegistroProgressao.fromJson(r.toJson());
      expect(v.valor, 8);
      expect(v.peso, 42.5);
      expect(v.exercicio, 'Agachamento');
    });

    test('registro antigo sem peso vira peso 0 (bodyweight)', () {
      final v = RegistroProgressao.fromJson(
          {'id': 'a', 'exercicio': 'Flexão', 'valor': 5, 'data': 0});
      expect(v.peso, 0);
    });
  });

  group('Rating — progressão por PESO', () {
    // Reps ESTAGNADAS (10→10), mas o peso subiu 40→42,5 na janela.
    test('recorde de peso (reps flat) sobe a progressão', () {
      final treinos = [treinoCom('Agachamento')];
      final prog = [
        RegistroProgressao(
            exercicio: 'Agachamento',
            valor: 10,
            peso: 40,
            data: hoje.subtract(const Duration(days: 50))), // antes do corte
        RegistroProgressao(
            exercicio: 'Agachamento',
            valor: 10,
            peso: 42.5,
            data: hoje.subtract(const Duration(days: 5))),
      ];
      final r =
          ratingForma(const <Conclusao>[], treinos, prog, hoje: hoje);
      expect(r.progressao, greaterThan(0));
    });

    test('mesmo peso e mesmas reps = progressão 0 (sem recorde)', () {
      final treinos = [treinoCom('Agachamento')];
      final prog = [
        RegistroProgressao(
            exercicio: 'Agachamento',
            valor: 10,
            peso: 40,
            data: hoje.subtract(const Duration(days: 50))),
        RegistroProgressao(
            exercicio: 'Agachamento',
            valor: 10,
            peso: 40,
            data: hoje.subtract(const Duration(days: 5))),
      ];
      final r =
          ratingForma(const <Conclusao>[], treinos, prog, hoje: hoje);
      expect(r.progressao, 0);
    });
  });

  group('recordesRecentes (Troféu de Ouro)', () {
    test('conta um recorde de PESO recente (reps flat)', () {
      final treinos = [treinoCom('Agachamento')];
      final prog = [
        RegistroProgressao(
            exercicio: 'Agachamento',
            valor: 10,
            peso: 40,
            data: hoje.subtract(const Duration(days: 30))),
        RegistroProgressao(
            exercicio: 'Agachamento',
            valor: 10,
            peso: 42.5,
            data: hoje.subtract(const Duration(days: 5))),
      ];
      expect(recordesRecentes(treinos, prog, hoje: hoje), 1);
    });
  });
}
