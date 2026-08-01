import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checkin.dart';
import '../models/exercicio.dart';

const _chave = 'checkin_v1';

/// Fonte única dos check-ins (assiduidade). Local, sem login/nuvem.
final checkinProvider =
    AsyncNotifierProvider<CheckinNotifier, List<CheckIn>>(CheckinNotifier.new);

class CheckinNotifier extends AsyncNotifier<List<CheckIn>> {
  @override
  Future<List<CheckIn>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chave);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<CheckIn> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chave,
      jsonEncode(list.map((c) => c.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  List<CheckIn> get _atual => List<CheckIn>.of(state.value ?? const []);

  bool _existe(List<CheckIn> list, DateTime dia, String exercicio) =>
      list.any((c) => mesmoDia(c.data, dia) && c.exercicio == exercicio);

  /// Registra o check-in de um exercício num dia (sem duplicar no mesmo dia).
  Future<void> registrar(Exercicio e, {DateTime? dia}) async {
    final d = dia ?? DateTime.now();
    final nome = e.nome.trim().isEmpty ? 'Exercício' : e.nome.trim();
    final list = _atual;
    if (_existe(list, d, nome)) return;
    list.add(CheckIn(data: d, exercicio: nome, corIndex: e.corIndex));
    await _persist(list);
  }

  /// Check-in manual (a partir do calendário): nome + cor + dia.
  Future<void> adicionarManual(
      String nome, int corIndex, DateTime dia) async {
    final list = _atual;
    if (_existe(list, dia, nome)) return;
    list.add(CheckIn(data: dia, exercicio: nome, corIndex: corIndex));
    await _persist(list);
  }

  Future<void> remover(String id) async {
    final list = _atual..removeWhere((c) => c.id == id);
    await _persist(list);
  }
}

/// Os check-ins de um dia.
List<CheckIn> checkinsDoDia(List<CheckIn> todos, DateTime dia) =>
    todos.where((c) => mesmoDia(c.data, dia)).toList();
