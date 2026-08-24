import 'dart:convert';

import 'package:calistenia/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('backup round-trip preserva tipos MISTOS (String + bool)', () async {
    // As chaves de config têm tipos misturados: som/gamificação são bool, o
    // resto é String. Este é o caso que quebrava o export (getString num bool).
    SharedPreferences.setMockInitialValues({
      'treinos_v1': '[{"id":"a"}]', // String (JSON)
      'progressao_v1': '[]', // String
      'tema_v1': 'espresso', // String
      'som_v1': false, // bool
      'gamificacao_v1': true, // bool
      'lembretes_v1': '{"ativo":true}', // String (JSON)
    });
    final prefs = await SharedPreferences.getInstance();

    final stores = coletarStores(prefs);
    // Simula o ciclo de ARQUIVO (jsonEncode/decode como no export→import real).
    final decodificado =
        (jsonDecode(jsonEncode(stores)) as Map).cast<String, dynamic>();

    await prefs.clear();
    final n = await aplicarStores(prefs, decodificado);

    expect(n, 6);
    expect(prefs.getString('treinos_v1'), '[{"id":"a"}]');
    expect(prefs.getString('tema_v1'), 'espresso');
    expect(prefs.getBool('som_v1'), false);
    expect(prefs.getBool('gamificacao_v1'), true);
    expect(prefs.getString('lembretes_v1'), '{"ativo":true}');
  });

  test('aplicarStores ignora chaves ausentes e conta as restauradas', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final n = await aplicarStores(prefs, {'treinos_v1': '[]', 'som_v1': true});
    expect(n, 2);
    expect(prefs.getString('treinos_v1'), '[]');
    expect(prefs.getBool('som_v1'), true);
  });
}
