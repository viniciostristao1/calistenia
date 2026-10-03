import 'package:calistenia/services/cards_repository.dart';
import 'package:calistenia/services/moedas_repository.dart';
import 'package:calistenia/util/cards_catalog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('economia de moedas (pura)', () {
    test('a cada 3 dias de sequência = +\$10, acumulando', () {
      expect(moedasGanhasPorStreak(2, 0), 0);
      expect(moedasGanhasPorStreak(3, 0), 10);
      expect(moedasGanhasPorStreak(6, 0), 20);
      expect(moedasGanhasPorStreak(9, 0), 30);
    });
    test('idempotente: já creditado não paga de novo', () {
      expect(moedasGanhasPorStreak(3, 3), 0);
      expect(moedasGanhasPorStreak(5, 3), 0); // 3->5 não cruza novo marco
      expect(moedasGanhasPorStreak(6, 3), 10); // cruza o 6
    });
    test('sequência caiu: recomeça a contagem de marcos', () {
      expect(moedasGanhasPorStreak(1, 7), 0); // reset, floor(1/3)=0
      expect(moedasGanhasPorStreak(3, 7), 10); // reset, floor(3/3)=1
    });
  });

  group('catálogo', () {
    test('16 cards, ids únicos, inicial existe', () {
      expect(todosCards.length, 16);
      expect(totalCardsCatalogo, 16);
      final ids = todosCards.map((c) => c.id).toSet();
      expect(ids.length, 16); // sem duplicados
      expect(cardPorId(kCardInicial), isNotNull);
      expect(cardPorId('inexistente'), isNull);
    });
    test('faltando / completa', () {
      final todos = todosCards.map((c) => c.id).toList();
      expect(colecaoCompleta(todos), isTrue);
      expect(cardsFaltando(todos), isEmpty);
      expect(colecaoCompleta(const ['meta']), isFalse);
      expect(cardsFaltando(const ['meta']).length, 15);
    });
  });

  group('repositórios (prefs mock)', () {
    test('cards: ganha o inicial e a compra reduz o que falta', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final iniciais = await c.read(cardsProvider.future);
      expect(iniciais, [kCardInicial]); // starter grátis
      final id = await c.read(cardsProvider.notifier).comprar();
      expect(id, isNotNull);
      expect(id, isNot(kCardInicial));
      expect(c.read(cardsProvider).value!.length, 2);
    });

    test('moedas: credita por streak, idempotente, e gasta', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(moedasProvider.future);
      expect(await c.read(moedasProvider.notifier).creditarPorStreak(3), 10);
      expect(c.read(moedasProvider).value, 10);
      expect(await c.read(moedasProvider.notifier).creditarPorStreak(3), 0);
      expect(await c.read(moedasProvider.notifier).creditarPorStreak(6), 10);
      expect(c.read(moedasProvider).value, 20);
      expect(await c.read(moedasProvider.notifier).gastar(50), isFalse);
      expect(await c.read(moedasProvider.notifier).gastar(20), isTrue);
      expect(c.read(moedasProvider).value, 0);
    });
  });
}
