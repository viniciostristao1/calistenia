import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

const _chave = 'tema_v1';

/// Preferência de tema (azul/âmbar/grafite/espresso/madeira), persistida localmente.
final temaProvider =
    AsyncNotifierProvider<TemaNotifier, TemaApp>(TemaNotifier.new);

class TemaNotifier extends AsyncNotifier<TemaApp> {
  @override
  Future<TemaApp> build() async {
    // Padrão = âmbar (cor oficial). Guardado pelo nome do enum (compat com o
    // formato antigo, que também era 'azul'/'ambar').
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_chave);
    return TemaApp.values.firstWhere(
      (t) => t.name == s,
      orElse: () => TemaApp.ambar,
    );
  }

  Future<void> definir(TemaApp t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, t.name);
    state = AsyncData(t);
  }
}
