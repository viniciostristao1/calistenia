import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const chaveArquivados = 'prog_arquivados_v1';

/// Nomes de exercícios ARQUIVADOS (aposentados): na aba Progressão eles vão para
/// o FIM da lista, com um aviso, e o exercício sai dos treinos (fora do timer e
/// do check-in). O histórico de progressão é preservado. Local + backup (não
/// sincroniza: é uma organização da visão, e o exercício arquivado já sai dos
/// treinos sincronizados).
final arquivadosProvider = AsyncNotifierProvider<ArquivadosNotifier, Set<String>>(
  ArquivadosNotifier.new,
);

class ArquivadosNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveArquivados);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _persist(Set<String> s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chaveArquivados, jsonEncode(s.toList()));
    state = AsyncData(s);
  }

  bool contem(String nome) => (state.value ?? const {}).contains(nome);

  Future<void> arquivar(String nome) async {
    final s = Set<String>.of(state.value ?? const {})..add(nome);
    await _persist(s);
  }

  Future<void> desarquivar(String nome) async {
    final s = Set<String>.of(state.value ?? const {})..remove(nome);
    await _persist(s);
  }
}
