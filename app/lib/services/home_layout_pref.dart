import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chave = 'home_layout_v1';

/// **Modos de layout da página Treinos.** O padrão é [atual] (o layout de
/// sempre); os outros vieram do laboratório de ideias (7, 8 e 9) e são
/// alternados pelo botão ao lado da engrenagem. É preferência local (não
/// sincroniza, como som/tema).
enum HomeLayout {
  atual('Atual'),
  desempenho('Desempenho'),
  abas('Hoje/Semana'),
  carrossel('Carrossel');

  final String label;
  const HomeLayout(this.label);
}

final homeLayoutProvider =
    AsyncNotifierProvider<HomeLayoutNotifier, HomeLayout>(
      HomeLayoutNotifier.new,
    );

class HomeLayoutNotifier extends AsyncNotifier<HomeLayout> {
  @override
  Future<HomeLayout> build() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_chave);
    return HomeLayout.values.firstWhere(
      (m) => m.name == s,
      orElse: () => HomeLayout.atual,
    );
  }

  Future<void> definir(HomeLayout m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, m.name);
    state = AsyncData(m);
  }

  /// Avança um modo (cicla) e devolve o novo — usado pelo botão do topo.
  Future<HomeLayout> proximo() async {
    final atual = state.value ?? HomeLayout.atual;
    final prox =
        HomeLayout.values[(atual.index + 1) % HomeLayout.values.length];
    await definir(prox);
    return prox;
  }
}
