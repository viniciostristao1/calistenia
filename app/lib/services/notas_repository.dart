import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/nota.dart';

const chaveNotas = 'notas_v1';

/// Fonte única do BLOCO DE NOTAS (aba Check-in). Lista livre — o usuário pode
/// ter quantas notas quiser. Local, com sync (união por id) e backup como os
/// outros stores.
final notasProvider = AsyncNotifierProvider<NotasNotifier, List<Nota>>(
  NotasNotifier.new,
);

class NotasNotifier extends AsyncNotifier<List<Nota>> {
  @override
  Future<List<Nota>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveNotas);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Nota.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<Nota> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveNotas,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  List<Nota> get _atual => List<Nota>.of(state.value ?? const []);

  /// Cria uma nota vazia no fim e devolve o id (p/ focar o campo).
  Future<String> adicionar() async {
    final list = _atual;
    final n = Nota();
    list.add(n);
    await _persist(list);
    return n.id;
  }

  Future<void> atualizar(String id, String texto) async {
    final list = _atual;
    final i = list.indexWhere((n) => n.id == id);
    if (i < 0) return;
    if (list[i].texto == texto) return;
    list[i] = list[i].copyComTexto(texto);
    await _persist(list);
  }

  Future<void> limparTexto(String id) async => atualizar(id, '');

  Future<void> remover(String id) async {
    final list = _atual..removeWhere((n) => n.id == id);
    await _persist(list);
  }

  /// Apaga TODAS as notas.
  Future<void> limparTudo() async => _persist([]);

  /// Substitui a lista inteira (usado pelo DESFAZER da UI).
  Future<void> restaurar(List<Nota> anterior) async =>
      _persist(List<Nota>.of(anterior));
}
