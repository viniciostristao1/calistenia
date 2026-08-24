import 'package:calistenia/services/lembretes_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LembretesConfig', () {
    test('horário padrão é 07:00 quando o dia não tem horário salvo', () {
      const c = LembretesConfig.vazio;
      expect(c.horarioDe(0), LembretesConfig.horarioPadrao);
      expect(c.horaDe(0), 7);
      expect(c.minutoDe(0), 0);
    });

    test('comHorario define minutos do dia e comAtivo alterna a chave', () {
      final c = LembretesConfig.vazio
          .comAtivo(true)
          .comHorario(5, 9 * 60 + 30); // sábado 09:30
      expect(c.ativo, true);
      expect(c.horaDe(5), 9);
      expect(c.minutoDe(5), 30);
      // Dias não configurados seguem no padrão.
      expect(c.horarioDe(0), LembretesConfig.horarioPadrao);
    });

    test('comHorario faz clamp em 0..1439', () {
      final c = LembretesConfig.vazio.comHorario(0, 5000);
      expect(c.horarioDe(0), 1439);
      final c2 = LembretesConfig.vazio.comHorario(0, -10);
      expect(c2.horarioDe(0), 0);
    });

    test('JSON round-trip preserva ativo e horários', () {
      final c = LembretesConfig.vazio
          .comAtivo(true)
          .comHorario(0, 6 * 60 + 30)
          .comHorario(3, 18 * 60);
      final voltou = LembretesConfig.fromJson(c.toJson());
      expect(voltou.ativo, true);
      expect(voltou.horaDe(0), 6);
      expect(voltou.minutoDe(0), 30);
      expect(voltou.horaDe(3), 18);
      expect(voltou.minutoDe(3), 0);
    });

    test('fromJson tolera ausência de campos', () {
      final c = LembretesConfig.fromJson(const {});
      expect(c.ativo, false);
      expect(c.horarioDe(2), LembretesConfig.horarioPadrao);
    });
  });
}
