import 'dart:convert';

import 'package:calistenia/models/medida.dart';
import 'package:calistenia/services/medidas_repository.dart';
import 'package:calistenia/widgets/medidas_bloco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sheet de Medidas em 360dp e 411dp: sem overflow (sem nada cortado),
/// seletor com as 5 métricas visíveis, cards com rótulo+unidade e edição.
Future<void> _abrirEm(WidgetTester tester, double largura) async {
  tester.view.physicalSize = Size(largura, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final m1 = Medida(data: DateTime(2026, 11, 18), peso: 56.75, cintura: 82);
  final m2 = Medida(data: DateTime(2026, 11, 10), peso: 57.0, coxa: 55);
  SharedPreferences.setMockInitialValues({
    'idioma_v1': jsonEncode({'codigo': 'pt'}),
    chaveMedidas: jsonEncode([m1.toJson(), m2.toJson()]),
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => Center(
              child: ElevatedButton(
                onPressed: () => abrirMedidas(c),
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
  expect(tester.takeException(), isNull);
}

void main() {
  group('MedidasSheet layout', () {
    testWidgets('360dp gráfico: 5 métricas visíveis, sem corte', (tester) async {
      await _abrirEm(tester, 360);
      // Texto exato = se houvesse ellipsis ("Cintu…") o find falharia.
      for (final rotulo in ['Peso', 'Cintura', 'Braço', 'Peito', 'Coxa']) {
        expect(find.text(rotulo), findsWidgets);
      }
      expect(find.text('56,75'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('411dp gráfico: 5 métricas visíveis, sem corte', (tester) async {
      await _abrirEm(tester, 411);
      for (final rotulo in ['Peso', 'Cintura', 'Braço', 'Peito', 'Coxa']) {
        expect(find.text(rotulo), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('360dp histórico: cards com unidade, sem ano, editável', (
      tester,
    ) async {
      await _abrirEm(tester, 360);
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Cabeçalho com contador rotulado + datas sem ano.
      expect(find.text('2 medições'), findsOneWidget);
      expect(find.text('18/11'), findsOneWidget);
      expect(find.text('10/11'), findsOneWidget);
      expect(find.textContaining('/2026'), findsNothing);

      // Grade com rótulo+unidade; Coxa aparece; vazio (Peito) nem é mostrado.
      expect(find.text('Peso (kg)'), findsWidgets);
      expect(find.text('Cintura (cm)'), findsOneWidget);
      expect(find.text('Coxa (cm)'), findsOneWidget);
      expect(find.text('Peito (cm)'), findsNothing);
      expect(find.text('56,75'), findsWidgets);
      expect(
        find.text('Peso em kg · demais em cm. Toque num cartão para editar.'),
        findsOneWidget,
      );

      // Tocar no cartão abre o editor (45+ dp de altura tocável).
      await tester.tap(find.text('18/11'));
      await tester.pumpAndSettle();
      expect(find.text('Editar medição'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('métrica sem dados mostra dica com contexto', (tester) async {
      await _abrirEm(tester, 360);
      await tester.tap(find.text('Braço'));
      await tester.pumpAndSettle();
      expect(find.text('Sem dados desta medida ainda.'), findsOneWidget);
      expect(
        find.text('Toque em “Nova medição” para registrar.'),
        findsOneWidget,
      );
      expect(find.text('Nova medição'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
