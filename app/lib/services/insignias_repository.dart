import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/insignia.dart';

const chaveInsignias = 'insignias_v1';

/// Fonte única das insígnias (estrelas) GANHAS. Uma vez ganha, é permanente.
/// Local, e sincronizada quando logado (ver `sync_service.dart`).
final insigniasProvider =
    AsyncNotifierProvider<InsigniasNotifier, List<Insignia>>(
  InsigniasNotifier.new,
);

class InsigniasNotifier extends AsyncNotifier<List<Insignia>> {
  @override
  Future<List<Insignia>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveInsignias);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Insignia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<Insignia> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveInsignias,
      jsonEncode(list.map((i) => i.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  /// Registra a estrela do [dia] se ainda não existir. Retorna `true` se GANHOU
  /// agora (para revelar no fim do treino), `false` se o dia já a tinha.
  Future<bool> registrarSeNova(DateTime dia) async {
    final atuais = await future; // garante carregado antes de comparar
    final nova = Insignia(data: dia);
    if (atuais.any((i) => i.id == nova.id)) return false;
    await _persist([...atuais, nova]);
    return true;
  }
}

/// Estrelas ganhas no mês [ano]/[mes], em ordem de data.
List<Insignia> insigniasDoMes(List<Insignia> lista, int ano, int mes) =>
    lista.where((i) => i.data.year == ano && i.data.month == mes).toList()
      ..sort((a, b) => a.data.compareTo(b.data));

/// Conjunto de DIAS (normalizados) com insígnia ganha — para o peso 1,5 no
/// rating (`ratingForma`).
Set<DateTime> diasComInsignia(List<Insignia> lista) =>
    lista.map((i) => i.data).toSet();
