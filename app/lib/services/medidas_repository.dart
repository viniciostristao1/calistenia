import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medida.dart';

const chaveMedidas = 'medidas_v1';

/// Fonte única das MEDIDAS CORPORAIS (peso + circunferências), acessível pelo
/// botão na aba Check-in. Lista ordenada por data (mais recente primeiro).
/// Local, com sync (união por id) e backup como os outros stores.
final medidasProvider = AsyncNotifierProvider<MedidasNotifier, List<Medida>>(
  MedidasNotifier.new,
);

class MedidasNotifier extends AsyncNotifier<List<Medida>> {
  @override
  Future<List<Medida>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveMedidas);
    if (raw == null || raw.isEmpty) return [];
    try {
      final lista = (jsonDecode(raw) as List)
          .map((e) => Medida.fromJson(e as Map<String, dynamic>))
          .toList();
      return _ordenar(lista);
    } catch (_) {
      return [];
    }
  }

  /// Mais recente primeiro (empate: pela edição mais nova).
  static List<Medida> _ordenar(List<Medida> l) {
    final copia = List<Medida>.of(l);
    copia.sort((a, b) {
      final c = b.data.compareTo(a.data);
      return c != 0 ? c : b.atualizadoEm.compareTo(a.atualizadoEm);
    });
    return copia;
  }

  Future<void> _persist(List<Medida> list) async {
    final ordenada = _ordenar(list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveMedidas,
      jsonEncode(ordenada.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(ordenada);
  }

  List<Medida> get _atual => List<Medida>.of(state.value ?? const []);

  /// Cria/atualiza uma medição (upsert por id). Medições vazias são ignoradas.
  /// Ids diferentes convivem no MESMO dia (o histórico guarda todas as medições).
  Future<void> salvar(Medida m) async {
    if (!m.temAlgo) return;
    final list = _atual;
    final i = list.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      list[i] = m;
    } else {
      list.add(m);
    }
    await _persist(list);
  }

  Future<void> remover(String id) async {
    final list = _atual..removeWhere((m) => m.id == id);
    await _persist(list);
  }

  /// Substitui a lista inteira (usado pelo DESFAZER da UI).
  Future<void> restaurar(List<Medida> anterior) async =>
      _persist(List<Medida>.of(anterior));
}
