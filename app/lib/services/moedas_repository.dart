import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/cards_catalog.dart';

const _chaveMoedas = 'moedas_v1';
const _chaveCred = 'moedas_cred_streak_v1'; // até qual streak já pagou

/// **Economia de moedas** ($): acumulam (diferente do Rating, que estabiliza).
/// Ganha +[kMoedasPorMarco] a cada [kMarcoDias] dias de SEQUÊNCIA consecutiva.
/// Gasta [kCustoCard] por card (compra surpresa). Local (não sincroniza — como
/// som/tema; a conquista some se trocar de aparelho, mas é só a carteira).
final moedasProvider = AsyncNotifierProvider<MoedasNotifier, int>(
  MoedasNotifier.new,
);

/// Quantas moedas um [streak] rende dado o que já foi pago até [creditado].
/// Se a sequência caiu ([streak] < [creditado]), recomeça a contagem de marcos.
int moedasGanhasPorStreak(int streak, int creditado) {
  final base = streak < creditado ? 0 : creditado;
  final chunks = (streak ~/ kMarcoDias) - (base ~/ kMarcoDias);
  return chunks > 0 ? chunks * kMoedasPorMarco : 0;
}

class MoedasNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_chaveMoedas) ?? 0;
  }

  /// Credita os marcos de sequência ainda não pagos. Retorna quantas moedas
  /// foram adicionadas agora (0 se nenhuma). Idempotente p/ o mesmo [streak].
  Future<int> creditarPorStreak(int streak) async {
    final atual = await future;
    final prefs = await SharedPreferences.getInstance();
    final creditado = prefs.getInt(_chaveCred) ?? 0;
    final ganho = moedasGanhasPorStreak(streak, creditado);
    await prefs.setInt(_chaveCred, streak);
    if (ganho > 0) {
      final novo = atual + ganho;
      await prefs.setInt(_chaveMoedas, novo);
      state = AsyncData(novo);
    }
    return ganho;
  }

  /// Gasta [valor] se houver saldo. Retorna `true` se gastou.
  Future<bool> gastar(int valor) async {
    final atual = await future;
    if (atual < valor) return false;
    final novo = atual - valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveMoedas, novo);
    state = AsyncData(novo);
    return true;
  }
}
