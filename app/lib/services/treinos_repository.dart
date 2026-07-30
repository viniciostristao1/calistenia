import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercicio.dart';
import '../models/treino.dart';
import '../util/dias.dart';

const _chave = 'treinos_v1';

/// Fonte única dos treinos. Carrega/salva em `shared_preferences` (local, sem
/// login/nuvem). O estado é a lista de treinos.
final treinosProvider =
    AsyncNotifierProvider<TreinosNotifier, List<Treino>>(TreinosNotifier.new);

class TreinosNotifier extends AsyncNotifier<List<Treino>> {
  @override
  Future<List<Treino>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chave);
    if (raw == null) {
      // Primeiro uso: semeia um treino de exemplo (o usuário pode editar/excluir).
      final exemplo = _seed();
      await _write(prefs, exemplo);
      return exemplo;
    }
    if (raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => Treino.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> _write(SharedPreferences prefs, List<Treino> list) async {
    await prefs.setString(
      _chave,
      jsonEncode(list.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _persist(List<Treino> list) async {
    final prefs = await SharedPreferences.getInstance();
    await _write(prefs, list);
    state = AsyncData(list);
  }

  List<Treino> get _atual => List<Treino>.of(state.value ?? const []);

  /// Insere (se novo) ou atualiza (se já existe) um treino.
  Future<void> salvar(Treino t) async {
    final list = _atual;
    final i = list.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      list[i] = t;
    } else {
      list.add(t);
    }
    await _persist(list);
  }

  Future<void> remover(String id) async {
    final list = _atual..removeWhere((x) => x.id == id);
    await _persist(list);
  }
}

List<Treino> _seed() {
  return [
    Treino(
      nome: 'Treino exemplo',
      dias: [diaDeHoje],
      exercicios: [
        // Ritmo por repetição: 3s por flexão, 10 flexões, 3 séries, desc 60s.
        Exercicio(
          nome: 'Flexão',
          preparacaoSeg: 10,
          execucaoSeg: 3,
          descansoSeg: 60,
          repeticoes: 10,
          series: 3,
        ),
        Exercicio(
          nome: 'Agachamento',
          preparacaoSeg: 10,
          execucaoSeg: 3,
          descansoSeg: 60,
          repeticoes: 15,
          series: 3,
        ),
        // Isométrico: 1 "repetição" de 45s (a série inteira), 2 séries.
        Exercicio(
          nome: 'Prancha',
          preparacaoSeg: 10,
          execucaoSeg: 45,
          descansoSeg: 30,
          repeticoes: 1,
          series: 2,
        ),
      ],
    ),
  ];
}
