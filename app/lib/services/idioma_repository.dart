import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chaveIdioma = 'idioma_v1';

enum Idioma { pt, en, es }

extension IdiomaExt on Idioma {
  String get codigo => switch (this) {
        Idioma.pt => 'pt',
        Idioma.en => 'en',
        Idioma.es => 'es',
      };

  String get nomeNativo => switch (this) {
        Idioma.pt => 'Português',
        Idioma.en => 'English',
        Idioma.es => 'Español',
      };

  static Idioma deCodigo(String? c) => switch (c) {
        'en' => Idioma.en,
        'es' => Idioma.es,
        _ => Idioma.pt,
      };
}

final idiomaProvider =
    AsyncNotifierProvider<IdiomaNotifier, Idioma>(IdiomaNotifier.new);

class IdiomaNotifier extends AsyncNotifier<Idioma> {
  @override
  Future<Idioma> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chaveIdioma);
    if (raw == null || raw.isEmpty) return Idioma.pt;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return IdiomaExt.deCodigo(m['codigo'] as String?);
    } catch (_) {
      return IdiomaExt.deCodigo(raw);
    }
  }

  Future<void> definir(Idioma idioma) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveIdioma, jsonEncode({'codigo': idioma.codigo}));
    state = AsyncData(idioma);
  }
}
