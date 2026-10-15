import 'package:calistenia/models/registro_progressao.dart';
import 'package:calistenia/services/checkin_repository.dart';
import 'package:calistenia/services/progressao_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renomear um exercício no treino leva o HISTÓRICO junto (progressão +
/// check-ins) — sem isso o gráfico orfana e abre um novo vazio (caso real:
/// "Agachamento com peso" → "Agachamento com halteres").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer novoContainer() {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  Future<void> semearProgressao(ProviderContainer c) async {
    final n = c.read(progressaoProvider.notifier);
    await n.adicionar(RegistroProgressao(
        exercicio: 'Agachamento com peso',
        valor: 12,
        peso: 10,
        data: DateTime(2026, 10, 1)));
    await n.adicionar(RegistroProgressao(
        exercicio: 'Agachamento com peso',
        valor: 13,
        peso: 10,
        data: DateTime(2026, 10, 5)));
    await n.adicionar(RegistroProgressao(
        exercicio: 'Rosca direta', valor: 20, data: DateTime(2026, 10, 5)));
  }

  Future<void> semearCheckins(ProviderContainer c) async {
    final n = c.read(checkinProvider.notifier);
    await n.adicionarManual('Agachamento com peso', 7, DateTime(2026, 10, 1));
    await n.adicionarManual('Agachamento com peso', 7, DateTime(2026, 10, 3));
    await n.adicionarManual('Rosca direta', 1, DateTime(2026, 10, 3));
  }

  group('ProgressaoNotifier.renomear', () {
    test('move os registros e preserva os ids', () async {
      final c = novoContainer();
      await semearProgressao(c);
      final n = c.read(progressaoProvider.notifier);

      final movidos =
          await n.renomear('Agachamento com peso', 'Agachamento com halteres');

      expect(movidos, 2);
      final lista = await c.read(progressaoProvider.future);
      final grupo = agruparPorExercicio(lista);
      expect(grupo.map((g) => g.exercicio),
          ['Agachamento com halteres', 'Rosca direta']);
      final halteres =
          grupo.firstWhere((g) => g.exercicio == 'Agachamento com halteres');
      expect(halteres.registros.map((r) => r.valor), [12, 13]);
      // ids intactos (o sync por id continua funcionando)
      expect(halteres.registros.every((r) => r.id.isNotEmpty), isTrue);
    });

    test('nome igual ou vazio não mexe em nada', () async {
      final c = novoContainer();
      await semearProgressao(c);
      final n = c.read(progressaoProvider.notifier);
      expect(await n.renomear('Agachamento com peso', 'Agachamento com peso'), 0);
      expect(await n.renomear('', 'Novo'), 0);
      expect(await n.renomear('Agachamento com peso', ''), 0);
      expect(await n.renomear('Inexistente', 'Novo'), 0);
      final lista = await c.read(progressaoProvider.future);
      expect(lista.length, 3);
    });

    test('após renomear, garantirBaseline não cria gráfico fantasma', () async {
      final c = novoContainer();
      await semearProgressao(c);
      final n = c.read(progressaoProvider.notifier);
      await n.renomear('Agachamento com peso', 'Agachamento com halteres');
      // É o que o editor faz logo depois de renomear:
      await n.garantirBaseline('Agachamento com halteres', 13, 10);
      final lista = await c.read(progressaoProvider.future);
      expect(lista.where((r) => r.exercicio == 'Agachamento com halteres').length,
          2);
    });
  });

  group('CheckinNotifier.renomear', () {
    test('move os check-ins mantendo dia e cor', () async {
      final c = novoContainer();
      await semearCheckins(c);
      final n = c.read(checkinProvider.notifier);

      expect(await n.renomear('Agachamento com peso', 'Agachamento com halteres'),
          2);
      final lista = await c.read(checkinProvider.future);
      expect(
          lista
              .where((e) => e.exercicio == 'Agachamento com halteres')
              .map((e) => (e.data.day, e.corIndex)),
          [(1, 7), (3, 7)]);
      expect(lista.where((e) => e.exercicio == 'Rosca direta').length, 1);
    });

    test('mesmo dia nos dois nomes não duplica', () async {
      final c = novoContainer();
      final n = c.read(checkinProvider.notifier);
      await n.adicionarManual('Antigo', 7, DateTime(2026, 10, 3));
      await n.adicionarManual('Novo', 2, DateTime(2026, 10, 3));

      expect(await n.renomear('Antigo', 'Novo'), 1);
      final lista = await c.read(checkinProvider.future);
      final doDia = lista
          .where((e) =>
              e.exercicio == 'Novo' &&
              e.data.year == 2026 &&
              e.data.month == 10 &&
              e.data.day == 3)
          .toList();
      expect(doDia.length, 1);
    });

    test('nome igual ou vazio não mexe em nada', () async {
      final c = novoContainer();
      await semearCheckins(c);
      final n = c.read(checkinProvider.notifier);
      expect(await n.renomear('Agachamento com peso', 'Agachamento com peso'), 0);
      expect(await n.renomear('X', 'Y'), 0);
      expect((await c.read(checkinProvider.future)).length, 3);
    });
  });

  group('agruparPorExercicio', () {
    test('nome exato agrupa junto (base do gráfico único)', () async {
      final lista = [
        RegistroProgressao(exercicio: 'Agachamento com halteres', valor: 12, data: DateTime(2026, 10, 1)),
        RegistroProgressao(exercicio: 'Agachamento com halteres', valor: 13, data: DateTime(2026, 10, 5)),
      ];
      final grupos = agruparPorExercicio(lista);
      expect(grupos.length, 1);
      expect(grupos.single.registros.map((r) => r.valor), [12, 13]);
    });
  });
}
