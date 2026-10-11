import 'package:calistenia/theme/app_colors.dart';
import 'package:calistenia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Provider de tema simplificado (espelha o temaProvider real, sem SharedPrefs).
class _TemaCtrl extends Notifier<TemaApp> {
  @override
  TemaApp build() => TemaApp.ambar;
  void set(TemaApp t) => state = t;
}

final _temaTest = NotifierProvider<_TemaCtrl, TemaApp>(_TemaCtrl.new);

/// Widget-folha que lê a cor ESTÁTICA (AppColors.surface) — igual aos quadrados
/// do Check-in. NÃO depende de Theme.of, então só repinta se for reconstruído.
class _Quadrado extends StatelessWidget {
  const _Quadrado();
  @override
  Widget build(BuildContext context) =>
      Container(key: const Key('quad'), color: AppColors.surface);
}

/// Variante que escuta o tema (candidata a fix): repinta mesmo sendo const.
class _QuadradoReativo extends ConsumerWidget {
  const _QuadradoReativo();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_temaTest);
    return Container(key: const Key('quad'), color: AppColors.surface);
  }
}

class _App extends ConsumerWidget {
  const _App({required this.filho});
  final Widget filho;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(_temaTest);
    return MaterialApp(
      theme: buildAppTheme(tema),
      home: Scaffold(body: Center(child: filho)),
    );
  }
}

Color _corDoQuad(WidgetTester t) =>
    (t.widget<Container>(find.byKey(const Key('quad'))).color)!;

void main() {
  testWidgets('BUG: const + cor estática NÃO repinta ao trocar tema', (t) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const _App(filho: _Quadrado()), // const: curto-circuita rebuild
      ),
    );
    final antes = _corDoQuad(t);
    expect(antes, AppColors.surface); // ambar (escuro)

    c.read(_temaTest.notifier).set(TemaApp.madeira); // claro (bege)
    await t.pumpAndSettle();

    final depois = _corDoQuad(t);
    // Demonstra o bug: a cor NÃO acompanhou a troca de tema (ficou a antiga).
    expect(depois, antes);
    expect(depois, isNot(AppColors.surface)); // surface agora é madeira
  });

  testWidgets('FIX: widget que escuta o tema repinta mesmo sendo const', (
    t,
  ) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const _App(filho: _QuadradoReativo()),
      ),
    );
    final antes = _corDoQuad(t);

    c.read(_temaTest.notifier).set(TemaApp.madeira);
    await t.pumpAndSettle();

    final depois = _corDoQuad(t);
    expect(depois, isNot(antes)); // acompanhou a troca
    expect(depois, AppColors.surface); // = madeira
  });
}
