import 'package:calistenia/fx/rewards/chest_open2.dart';
import 'package:calistenia/fx/rewards/flame_3d.dart';
import 'package:calistenia/fx/rewards/score_rising.dart';
import 'package:calistenia/fx/rewards/star_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O CONTEÚDO do baú (v0.81.0): o baú abre no toque e o item — estrela, número,
/// medalha ou chama — sai de dentro dele. Aqui garantimos só que cada item
/// constrói, abre e revela o conteúdo certo sem exceção (a aparência é no
/// aparelho).
Future<void> _abre(
  WidgetTester tester,
  ChestOpen2 bau, {
  bool toque = true,
}) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: bau))));
  await tester.pump(const Duration(milliseconds: 100));
  if (toque) {
    expect(find.text('Toque para abrir'), findsOneWidget);
    await tester.tap(find.byType(ChestOpen2));
  }
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('estrela: o baú abre e a estrela sai de dentro', (tester) async {
    await _abre(tester, const ChestOpen2(valor: 10));
    expect(find.byType(Star3D), findsOneWidget);
  });

  testWidgets('número: o baú abre e a pontuação sai de dentro', (tester) async {
    await _abre(
      tester,
      const ChestOpen2(item: ChestItem.numero, valor: 50),
    );
    expect(find.byType(ScoreRising), findsOneWidget);
  });

  testWidgets('medalha: abre com o rótulo e o emoji do prêmio', (tester) async {
    await _abre(
      tester,
      const ChestOpen2(
        item: ChestItem.medalha,
        label: 'Medalha de Ouro',
        conteudo: Text('🥇', style: TextStyle(fontSize: 64)),
      ),
    );
    expect(find.text('Medalha de Ouro'), findsOneWidget);
    expect(find.text('🥇'), findsOneWidget);
  });

  testWidgets('chama: a chama desenhada sai de dentro do baú', (tester) async {
    await _abre(
      tester,
      const ChestOpen2(item: ChestItem.chama, label: '12 dias', valor: 12),
    );
    expect(find.text('12 dias'), findsOneWidget);
    expect(find.byType(Flame3D), findsWidgets);
  });

  testWidgets('baú rápido não abre sem o toque', (tester) async {
    await _abre(
      tester,
      const ChestOpen2(rapido: true, item: ChestItem.chama),
      toque: false,
    );
    expect(find.byType(Flame3D), findsNothing);
  });
}
