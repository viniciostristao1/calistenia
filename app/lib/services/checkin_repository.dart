import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checkin.dart';
import '../models/exercicio.dart';

const chaveCheckin = 'checkin_v1';

/// Deep-link da aba Check-in: quando ≠ null, a `CheckinScreen` abre nessa
/// sub-aba (0=calendário, 1=galeria/conquistas, 2=histórico) e volta a null.
/// Usado pela dica "Ver conquistas" do Resumo. (ValueNotifier simples — não
/// depende da versão do Riverpod p/ StateProvider.)
final checkinVistaInicial = ValueNotifier<int?>(null);

/// Fonte única dos check-ins (assiduidade). Local, sem login/nuvem.
final checkinProvider = AsyncNotifierProvider<CheckinNotifier, List<CheckIn>>(
  CheckinNotifier.new,
);

class CheckinNotifier extends AsyncNotifier<List<CheckIn>> {
  @override
  Future<List<CheckIn>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveCheckin);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<CheckIn> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveCheckin,
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
  Future<void> adicionarManual(String nome, int corIndex, DateTime dia) async {
    final list = _atual;
    if (_existe(list, dia, nome)) return;
    list.add(CheckIn(data: dia, exercicio: nome, corIndex: corIndex));
    await _persist(list);
  }

  Future<void> remover(String id) async {
    final list = _atual..removeWhere((c) => c.id == id);
    await _persist(list);
  }

  /// Renomeia um exercício no HISTÓRICO: todos os check-ins com o nome antigo
  /// passam para o nome novo (mesmo motivo do `ProgressaoNotifier.renomear`).
  /// Se antigo e novo já tinham check-in no MESMO dia, fica só o primeiro
  /// (nunca duplica o dia). Devolve quantos check-ins foram movidos.
  Future<int> renomear(String antigo, String novo) async {
    final de = antigo.trim();
    final para = novo.trim();
    if (de.isEmpty || para.isEmpty || de == para) return 0;
    final list = List<CheckIn>.of(await future);
    var movidos = 0;
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      if (c.exercicio.trim() == de) {
        list[i] = CheckIn(
          id: c.id,
          data: c.data,
          exercicio: para,
          corIndex: c.corIndex,
        );
        movidos++;
      }
    }
    if (movidos == 0) return 0;
    final vistos = <String>{};
    list.retainWhere((c) {
      final k = '${c.data.year}-${c.data.month}-${c.data.day}§${c.exercicio}';
      if (!vistos.add(k)) return false;
      return true;
    });
    await _persist(list);
    return movidos;
  }
}

/// Os check-ins de um dia.
List<CheckIn> checkinsDoDia(List<CheckIn> todos, DateTime dia) =>
    todos.where((c) => mesmoDia(c.data, dia)).toList();
