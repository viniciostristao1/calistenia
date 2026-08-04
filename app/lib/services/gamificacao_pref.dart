import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chave = 'gamificacao_v1';

/// Preferência de gamificação (medalhas/troféus + pergunta "treino completo?").
/// Ligada por padrão. É preferência local — não sincroniza (como som/tema).
final gamificacaoProvider =
    AsyncNotifierProvider<GamificacaoNotifier, bool>(GamificacaoNotifier.new);

class GamificacaoNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chave) ?? true;
  }

  Future<void> definir(bool ligado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chave, ligado);
    state = AsyncData(ligado);
  }
}
