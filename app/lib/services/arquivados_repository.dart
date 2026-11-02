import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercicio.dart';

const chaveArquivados = 'prog_arquivados_v1';

/// Exercícios ARQUIVADOS (aposentados). Guarda a DEFINIÇÃO inteira do exercício
/// (não só o nome) para que desarquivar possa devolvê-lo a um treino com os
/// mesmos tempos/séries. Na aba Progressão eles vão para o FIM (com aviso) e no
/// editor do treino aparecem num resumo "N arquivado". O histórico de
/// progressão (por nome) é preservado. Local + backup (não sincroniza).
final arquivadosProvider =
    AsyncNotifierProvider<ArquivadosNotifier, List<Exercicio>>(
  ArquivadosNotifier.new,
);

class ArquivadosNotifier extends AsyncNotifier<List<Exercicio>> {
  @override
  Future<List<Exercicio>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveArquivados);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) {
        // Compat: formato antigo guardava só o nome (String).
        if (e is String) return Exercicio(nome: e);
        return Exercicio.fromJson(Map<String, dynamic>.from(e as Map));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<Exercicio> l) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveArquivados,
      jsonEncode(l.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(l);
  }

  List<Exercicio> get _atual => List<Exercicio>.of(state.value ?? const []);

  /// A definição arquivada de [nome] (ou null).
  Exercicio? pegar(String nome) =>
      (state.value ?? const <Exercicio>[]).where((e) => e.nome == nome).firstOrNull;

  /// Arquiva (guarda a definição). Se já existir pelo nome, substitui.
  Future<void> arquivar(Exercicio e) async {
    final l = _atual
      ..removeWhere((x) => x.nome == e.nome)
      ..add(e);
    await _persist(l);
  }

  Future<void> desarquivar(String nome) async {
    final l = _atual..removeWhere((e) => e.nome == nome);
    await _persist(l);
  }
}

/// Conjunto de nomes arquivados a partir da lista (helper p/ a UI).
Set<String> nomesArquivados(List<Exercicio>? lista) =>
    {for (final e in (lista ?? const <Exercicio>[])) e.nome};
