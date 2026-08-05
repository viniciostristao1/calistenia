import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conquista.dart';

const chaveConquistas = 'conquistas_v1';

/// Fonte única das conquistas já obtidas (medalhas/troféus). Uma vez ganha, uma
/// conquista é permanente. Local, e sincronizada quando logado.
final conquistasProvider =
    AsyncNotifierProvider<ConquistasNotifier, List<Conquista>>(
  ConquistasNotifier.new,
);

class ConquistasNotifier extends AsyncNotifier<List<Conquista>> {
  @override
  Future<List<Conquista>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveConquistas);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Conquista.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<Conquista> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveConquistas,
      jsonEncode(list.map((c) => c.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  /// Registra as conquistas de [obtidas] que ainda não existem. Retorna as
  /// NOVAS (para celebrar no fim do treino). Nunca remove nem duplica.
  Future<List<TipoConquista>> registrarNovas(
      Set<TipoConquista> obtidas) async {
    final atuais = await future; // garante carregado antes de comparar
    final jaTem = atuais.map((c) => c.tipo).toSet();
    final novas =
        obtidas.where((t) => !jaTem.contains(t.chave)).toList();
    if (novas.isEmpty) return [];
    final agora = DateTime.now();
    final list = [
      ...atuais,
      for (final t in novas) Conquista(tipo: t.chave, data: agora),
    ];
    await _persist(list);
    return novas;
  }

  /// Reconcilia o histórico com o estado atual: conquistas que caíram (não estão
  /// mais em [atuais]) ganham `perdidaEm = agora`; as que voltaram a ser ativas
  /// têm `perdidaEm` limpo. Assim cada conquista aparece OU em "atuais" OU no
  /// histórico (nunca duplicada).
  Future<void> reconciliar(Set<TipoConquista> atuais) async {
    final list = await future;
    final ativas = atuais.map((t) => t.chave).toSet();
    final agora = DateTime.now();
    var mudou = false;
    final nova = <Conquista>[];
    for (final c in list) {
      final ativa = ativas.contains(c.tipo);
      if (ativa && c.perdidaEm != null) {
        nova.add(c.comPerdida(null)); // voltou a ser ativa
        mudou = true;
      } else if (!ativa && c.perdidaEm == null) {
        nova.add(c.comPerdida(agora)); // acabou de cair
        mudou = true;
      } else {
        nova.add(c);
      }
    }
    if (mudou) await _persist(nova);
  }
}

/// A data em que uma conquista foi obtida, ou `null` se ainda não foi.
DateTime? quandoConquistou(List<Conquista> conquistas, TipoConquista t) {
  for (final c in conquistas) {
    if (c.tipo == t.chave) return c.data;
  }
  return null;
}
