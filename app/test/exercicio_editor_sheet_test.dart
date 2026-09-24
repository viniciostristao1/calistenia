import 'package:calistenia/features/treino/exercicio_editor_sheet.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _abrir(WidgetTester tester, Exercicio? ex) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => Center(
              child: ElevatedButton(
                onPressed: () => showExercicioEditor(c, ex),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

double _opacidadeDoBotao(WidgetTester tester) {
  final f = find.ancestor(
    of: find.text('Salvar exercício'),
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(f).opacity;
}

void main() {
  testWidgets('editar: Salvar aparece só ao alterar e some ao reverter',
      (tester) async {
    final ex = Exercicio(
      nome: 'Flexão',
      preparacaoSeg: 10,
      execucaoSeg: 3,
      descansoSeg: 60,
      repeticoes: 10,
      series: 3,
    );
    await _abrir(tester, ex);

    expect(_opacidadeDoBotao(tester), 0);

    await tester.enterText(find.byType(TextField).first, 'Flexão X');
    await tester.pumpAndSettle();
    expect(_opacidadeDoBotao(tester), 1);

    // Fica ancorado embaixo (perto do rodapé da folha).
    final y = tester.getBottomLeft(find.text('Salvar exercício')).dy;
    expect(y, greaterThan(500));

    await tester.enterText(find.byType(TextField).first, 'Flexão');
    await tester.pumpAndSettle();
    expect(_opacidadeDoBotao(tester), 0);
  });

  testWidgets('editar: mexer num tempo também revela o Salvar', (tester) async {
    final ex = Exercicio(
      nome: 'Flexão',
      preparacaoSeg: 10,
      execucaoSeg: 3,
      descansoSeg: 60,
      repeticoes: 10,
      series: 3,
    );
    await _abrir(tester, ex);
    expect(_opacidadeDoBotao(tester), 0);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(_opacidadeDoBotao(tester), 1);
  });

  testWidgets('novo: Salvar aparece ao digitar o nome', (tester) async {
    await _abrir(tester, null);
    expect(_opacidadeDoBotao(tester), 0);
    await tester.enterText(find.byType(TextField).first, 'Rosca');
    await tester.pumpAndSettle();
    expect(_opacidadeDoBotao(tester), 1);
  });
}
