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

  /// Marca o treino como concluído hoje (ou em [dia]). Não duplica a mesma
  /// conclusão (mesmo treino, mesmo dia). Retorna a conclusão registrada, ou
  /// `null` se já existia.
  Future<Conclusao?> registrar(Treino t, {DateTime? dia}) async {
    final atuais = await future; // garante carregado antes de mutar
    final d = dia ?? DateTime.now();
    final ja = atuais.any((c) =>
        c.treinoId == t.id &&
        c.data.year == d.year &&
        c.data.month == d.month &&
        c.data.day == d.day);
    if (ja) return null;
    final nome = t.nome.trim().isEmpty ? 'Treino' : t.nome.trim();
    final nova = Conclusao(data: d, treinoId: t.id, treino: nome);
    await _persist([...atuais, nova]);
    return nova;
  }

  Future<void> remover(String id) async {
    final list = List<Conclusao>.of(await future)
      ..removeWhere((c) => c.id == id);
    await _persist(list);
  }
}
