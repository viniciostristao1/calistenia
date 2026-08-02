import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

const _chave = 'tema_v1';

/// Preferência de tema de destaque (azul/âmbar), persistida localmente.
final temaProvider =
    AsyncNotifierProvider<TemaNotifier, TemaApp>(TemaNotifier.new);

class TemaNotifier extends AsyncNotifier<TemaApp> {
  @override
  Future<TemaApp> build() async {
    // Padrão = âmbar (cor oficial); azul só se o usuário escolher.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chave) == 'azul' ? TemaApp.azul : TemaApp.ambar;
  }

  Future<void> definir(TemaApp t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, t == TemaApp.ambar ? 'ambar' : 'azul');
    state = AsyncData(t);
  }
}
