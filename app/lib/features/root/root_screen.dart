import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/idioma_repository.dart';
import '../../services/navegacao.dart';
import '../../services/tema_repository.dart';
import '../../l10n/strings.dart';
import '../../widgets/barra_navegacao.dart';
import '../checkin/checkin_screen.dart';
import '../home/home_screen.dart';
import '../progressao/progressao_screen.dart';

/// Casca do app com a barra de abas embaixo: Treinos e Progressão.
class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _aba = 0;
  final _progressaoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    abaSolicitada.addListener(_irParaAbaSolicitada);
  }

  @override
  void dispose() {
    abaSolicitada.removeListener(_irParaAbaSolicitada);
    super.dispose();
  }

  /// Deep-link (ex.: tocar na moeda → Progressão): troca a aba e limpa o pedido.
  void _irParaAbaSolicitada() {
    final a = abaSolicitada.value;
    if (a == null || !mounted) return;
    setState(() => _aba = a);
    abaSolicitada.value = null;
  }

  @override
  Widget build(BuildContext context) {
    // A barra inferior usa AppColors.surface (cor estática). Observa o tema p/
    // repintar na troca — senão a barra fica com a cor do tema anterior
    // (mesmo motivo do MoedasBadge; ver test/tema_troca_repinta_test.dart).
    ref.watch(temaProvider);
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    return Scaffold(
      // Conteúdo passa POR TRÁS da barra flutuante (v0.118.0): as telas
      // compensam com espaço inferior próprio (~112dp nas listas).
      extendBody: true,
      // IndexedStack preserva o estado de cada aba ao alternar.
      body: IndexedStack(
        index: _aba,
        children: [
          const HomeScreen(),
          const CheckinScreen(),
          ProgressaoScreen(
            key: _progressaoKey,
            onIrParaAba: (i) => setState(() => _aba = i),
          ),
        ],
      ),
      // Barra flutuante em pílula (v0.118.0): suspensa, cantos arredondados,
      // SafeArea p/ não encostar na barra de gestos do sistema. Mesmos itens,
      // nomes, ícones e ordem da NavigationBar original.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: BarraNavegacaoFlutuante(
          selecionado: _aba,
          onSelect: (i) {
            final prev = _aba;
            setState(() => _aba = i);
            if (i == 2 && prev != 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  (_progressaoKey.currentState as dynamic)
                      ?.restartRatingAnimation();
                } catch (_) {}
              });
            }
          },
          destinos: [
            DestinoNavegacao(
              rotulo: s.treinos,
              icone: Icons.fitness_center_outlined,
              iconeSelecionado: Icons.fitness_center,
            ),
            DestinoNavegacao(
              rotulo: s.checkIn,
              icone: Icons.calendar_month_outlined,
              iconeSelecionado: Icons.calendar_month,
            ),
            DestinoNavegacao(
              rotulo: s.progressao,
              icone: Icons.trending_up_outlined,
              iconeSelecionado: Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }
}
