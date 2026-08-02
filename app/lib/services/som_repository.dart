import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chave = 'som_v1';

/// Preferência de som (bips do cronômetro e som de fim). Ligado por padrão.
final somProvider = AsyncNotifierProvider<SomNotifier, bool>(SomNotifier.new);

class SomNotifier extends AsyncNotifier<bool> {
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
