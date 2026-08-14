import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conclusao.dart';
import '../models/treino.dart';

const chaveConclusao = 'conclusao_v1';

/// Fonte única das conclusões de treino (base da gamificação). Local, e
/// sincronizada quando logado (ver `sync_service.dart`).
final conclusaoProvider =
    AsyncNotifierProvider<ConclusaoNotifier, List<Conclusao>>(
  ConclusaoNotifier.new,
);

class ConclusaoNotifier extends AsyncNotifier<List<Conclusao>> {
  @override
  Future<List<Conclusao>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveConclusao);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Conclusao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<Conclusao> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveConclusao,
      jsonEncode(list.map((c) => c.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  /// Marca o treino como concluído ([completo] true) ou TENTADO ([completo]
  /// false, "não consegui hoje") no dia. Não duplica (mesmo treino/dia); mas se
  /// já havia uma TENTATIVA e agora vem uma conclusão completa, faz o upgrade.
  /// Retorna o registro criado/atualizado, ou `null` se nada mudou.
  Future<Conclusao?> registrar(Treino t,
      {DateTime? dia, bool completo = true}) async {
    final atuais = await future; // garante carregado antes de mutar
    final d = dia ?? DateTime.now();
    final nome = t.nome.trim().isEmpty ? 'Treino' : t.nome.trim();
    final idx = atuais.indexWhere((c) =>
        c.treinoId == t.id &&
        c.data.year == d.year &&
        c.data.month == d.month &&
        c.data.day == d.day);
    if (idx >= 0) {
      final ex = atuais[idx];
      // Só faz upgrade de tentativa → completo (nunca o contrário).
      if (completo && !ex.completo) {
        final upg = Conclusao(
            id: ex.id, data: d, treinoId: t.id, treino: nome, completo: true);
        final list = List<Conclusao>.of(atuais)..[idx] = upg;
        await _persist(list);
        return upg;
      }
      return null;
    }
    final nova =
        Conclusao(data: d, treinoId: t.id, treino: nome, completo: completo);
    await _persist([...atuais, nova]);
    return nova;
  }

  Future<void> remover(String id) async {
    final list = List<Conclusao>.of(await future)
      ..removeWhere((c) => c.id == id);
    await _persist(list);
  }
}
