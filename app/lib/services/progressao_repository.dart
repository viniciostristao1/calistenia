import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/registro_progressao.dart';

const chaveProgressao = 'progressao_v1';

/// Fonte única dos registros de progressão (local, sem login/nuvem).
final progressaoProvider =
    AsyncNotifierProvider<ProgressaoNotifier, List<RegistroProgressao>>(
  ProgressaoNotifier.new,
);

class ProgressaoNotifier extends AsyncNotifier<List<RegistroProgressao>> {
  @override
  Future<List<RegistroProgressao>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveProgressao);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => RegistroProgressao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<RegistroProgressao> list) async {
    list.sort((a, b) => a.data.compareTo(b.data));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveProgressao,
      jsonEncode(list.map((r) => r.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  List<RegistroProgressao> get _atual =>
      List<RegistroProgressao>.of(state.value ?? const []);

  Future<void> adicionar(RegistroProgressao r) async {
    final list = _atual..add(r);
    await _persist(list);
  }

  Future<void> remover(String id) async {
    final list = _atual..removeWhere((r) => r.id == id);
    await _persist(list);
  }

  Future<void> removerExercicio(String exercicio) async {
    final list = _atual..removeWhere((r) => r.exercicio == exercicio);
    await _persist(list);
  }
}

/// Agrupa os registros por exercício (nome), cada grupo ordenado por data.
/// Retorna uma lista de grupos ordenada pelo registro mais recente primeiro.
List<GrupoProgressao> agruparPorExercicio(List<RegistroProgressao> registros) {
  final mapa = <String, List<RegistroProgressao>>{};
  for (final r in registros) {
    mapa.putIfAbsent(r.exercicio, () => []).add(r);
  }
  final grupos = mapa.entries.map((e) {
    final lista = List<RegistroProgressao>.of(e.value)
      ..sort((a, b) => a.data.compareTo(b.data));
    return GrupoProgressao(exercicio: e.key, registros: lista);
  }).toList();
  grupos.sort((a, b) => b.ultimaData.compareTo(a.ultimaData));
  return grupos;
}

/// Um exercício com seus registros de progressão (ordenados por data).
class GrupoProgressao {
  final String exercicio;
  final List<RegistroProgressao> registros; // ordenados por data crescente

  GrupoProgressao({required this.exercicio, required this.registros});

  int get primeiro => registros.first.valor;
  int get ultimo => registros.last.valor;
  int get maior => registros.map((r) => r.valor).reduce((a, b) => a > b ? a : b);
  DateTime get ultimaData => registros.last.data;
}
