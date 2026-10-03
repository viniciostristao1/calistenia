import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/escudo.dart';

const chaveEscudo = 'escudos_v1';

/// Fonte única dos ESCUDOS (ganhos e usados). Local, sincronizada quando logado
/// (ver `sync_service.dart`, união por id). Regra: **no máximo 1 guardado**.
final escudoProvider = AsyncNotifierProvider<EscudoNotifier, List<Escudo>>(
  EscudoNotifier.new,
);

class EscudoNotifier extends AsyncNotifier<List<Escudo>> {
  @override
  Future<List<Escudo>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveEscudo);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Escudo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<Escudo> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveEscudo,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  /// Ganha um escudo no [dia] se ainda **não houver um guardado** (máx 1) e esse
  /// dia já não tiver gerado um. Retorna `true` se ganhou agora (p/ a cerimônia).
  Future<bool> ganhar(DateTime dia) async {
    final atuais = await future;
    if (atuais.any((e) => !e.usado)) return false; // já há um guardado
    final novo = Escudo(ganhoEm: dia);
    if (atuais.any((e) => e.id == novo.id)) return false; // dedup do dia
    await _persist([...atuais, novo]);
    return true;
  }

  /// Gasta o escudo guardado cobrindo [diaCoberto]. Retorna `true` se usou.
  Future<bool> usar(DateTime diaCoberto) async {
    final atuais = await future;
    final idx = atuais.indexWhere((e) => !e.usado);
    if (idx < 0) return false; // nada guardado
    final novo = [...atuais];
    novo[idx] = atuais[idx].copyUsando(diaCoberto);
    await _persist(novo);
    return true;
  }
}

/// Há um escudo GUARDADO (disponível p/ usar)?
bool temEscudoDisponivel(List<Escudo> l) => l.any((e) => !e.usado);

/// Dias COBERTOS por escudo (contam como completos na sequência).
Set<DateTime> diasCobertosPorEscudo(List<Escudo> l) => {
  for (final e in l)
    if (e.usadoEm != null) e.usadoEm!,
};

/// Dias em que um escudo foi GANHO (para o bônus de +20 no rating).
Set<DateTime> diasEscudoGanho(List<Escudo> l) => {for (final e in l) e.ganhoEm};

/// Escudos GANHOS no mês [ano]/[mes] (para o quadro/linha das insígnias).
List<Escudo> escudosDoMes(List<Escudo> l, int ano, int mes) =>
    l.where((e) => e.ganhoEm.year == ano && e.ganhoEm.month == mes).toList()
      ..sort((a, b) => a.ganhoEm.compareTo(b.ganhoEm));
