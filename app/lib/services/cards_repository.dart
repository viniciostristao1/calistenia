import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/cards_catalog.dart';

const _chaveCards = 'cards_v1';
const _chavePreTreino = 'cards_pretreino_v1';

/// **Coleção de CARDS** do usuário (ids possuídos, em ordem de obtenção). No 1º uso
/// ganha [kCardInicial] de graça (p/ o card pré-treino não ficar vazio). Compra
/// é SURPRESA: [comprar] sorteia um card ainda não possuído. Local.
final cardsProvider = AsyncNotifierProvider<CardsNotifier, List<String>>(
  CardsNotifier.new,
);

class CardsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chaveCards);
    if (raw == null) {
      // 1ª vez: dá o card inicial de graça.
      final inicial = [kCardInicial];
      await prefs.setString(_chaveCards, jsonEncode(inicial));
      return inicial;
    }
    if (raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> _persist(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveCards, jsonEncode(list));
    state = AsyncData(list);
  }

  /// Compra SURPRESA: sorteia um card ainda não possuído, adiciona e devolve o
  /// id (ou `null` se a coleção já está completa). NÃO mexe nas moedas — quem
  /// chama deve gastar antes (ver `moedasProvider`).
  Future<String?> comprar() async {
    final atuais = await future;
    final faltam = todosCards
        .where((c) => !atuais.contains(c.id))
        .map((c) => c.id)
        .toList();
    if (faltam.isEmpty) return null;
    final escolha = faltam[Random().nextInt(faltam.length)];
    await _persist([...atuais, escolha]);
    return escolha;
  }
}

/// Ids do catálogo ainda NÃO possuídos.
List<String> cardsFaltando(List<String> possuidos) => todosCards
    .where((c) => !possuidos.contains(c.id))
    .map((c) => c.id)
    .toList();

/// Coleção completa (todos os cards do catálogo)?
bool colecaoCompleta(List<String> possuidos) =>
    possuidos.toSet().length >= totalCardsCatalogo;

/// **Preferência: mostrar o card motivacional ANTES do treino.** Ligado por
/// padrão. Local (como som/tema). Desligar some com o card ao "Iniciar treino".
final cardsPreTreinoProvider =
    AsyncNotifierProvider<CardsPreTreinoNotifier, bool>(
      CardsPreTreinoNotifier.new,
    );

class CardsPreTreinoNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chavePreTreino) ?? true;
  }

  Future<void> definir(bool ligado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chavePreTreino, ligado);
    state = AsyncData(ligado);
  }
}
