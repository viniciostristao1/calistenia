import 'package:calistenia/fx/fx.dart';
import 'package:calistenia/fx/reward_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test da camada `fx/`: cada RewardType deve CONSTRUIR e AVANÇAR alguns
/// frames sem lançar (controllers, layout, motor de partículas). Não valida a
/// aparência — isso é no aparelho —, só que nada explode em runtime.
void main() {
  testWidgets('todo RewardType constrói e anima sem exceção', (tester) async {
    registerBuiltInRewards();

    for (final type in RewardType.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: RewardRegistry.build(ctx, type, const FxParams(), value: 50),
            ),
          ),
        ),
      ));

      // Avança o tempo para rodar as animações e a integração das partículas.
      // (Não usar pumpAndSettle: o GlowHalo pulsa em loop e não "assenta".)
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull, reason: 'falhou em $type');
    }
  });

  testWidgets('efeito com FxParams extremos não explode', (tester) async {
    registerBuiltInRewards();
    const extremo = FxParams(
      speed: 3,
      intensity: 2,
      scale: 2,
      particleCount: 200,
      duration: Duration(milliseconds: 300),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: RewardRegistry.build(ctx, RewardType.star, extremo),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
