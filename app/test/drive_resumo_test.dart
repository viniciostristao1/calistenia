import 'dart:convert';

import 'package:calistenia/models/checkin.dart';
import 'package:calistenia/models/conclusao.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/registro_progressao.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/services/drive_resumo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoje = DateTime(2026, 10, 16);

Conclusao _cc(String id, int diaOffset, {bool completo = true}) =>
    Conclusao(
      id: id,
      data: _hoje.subtract(Duration(days: diaOffset)),
      treinoId: 't1',
      treino: 'Peito',
      completo: completo,
    );

Treino _treino() => Treino(id: 't1', nome: 'Peito', dias: const [0], exercicios: [
      Exercicio(nome: 'Flexão', series: 3, repeticoes: 10, pesoKg: 10),
      Exercicio(nome: 'Barra', series: 5, repeticoes: 5),
    ]);

/// Drive fake em memória, com falha injetável (offline).
class _DriveFake implements DriveArquivos {
  final Map<String, String> arquivos = {};
  String? pastaCriada;
  bool falharTudo = false;
  int salvamentos = 0;

  @override
  Future<String?> acharArquivoId(String nomePasta, String nomeArquivo) async {
    if (falharTudo) throw Exception('offline');
    return arquivos.containsKey(nomeArquivo) ? 'id-$nomeArquivo' : null;
  }

  @override
  Future<String> ler(String fileId) async {
    if (falharTudo) throw Exception('offline');
    final texto = arquivos[fileId.replaceFirst('id-', '')];
    if (texto == null) throw Exception('notFound 404');
    return texto;
  }

  @override
  Future<void> salvar(String fileId, String texto) async {
    if (falharTudo) throw Exception('offline');
    salvamentos++;
    arquivos[fileId.replaceFirst('id-', '')] = texto;
  }

  @override
  Future<String> criar(
      String nomePasta, String nomeArquivo, String texto) async {
    if (falharTudo) throw Exception('offline');
    pastaCriada = nomePasta;
    arquivos[nomeArquivo] = texto;
    return 'id-$nomeArquivo';
  }
}

DriveResumoService _servico(_DriveFake drive, {String? token}) {
  return DriveResumoService(
    arquivos: drive,
    tokens: ({required bool interativo}) async => token,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TotaisResumo> totaisSalvos() async {
    final prefs = await SharedPreferences.getInstance();
    return TotaisResumo.fromJson(
        jsonDecode(prefs.getString(chaveDriveResumoTotais)!) as Map<String, dynamic>);
  }

  group('bloco do dia', () {
    test('traz data, treino, plano, feito e check-ins — sem dados proibidos', () {
      final bloco = blocoDia(
        conclusao: _cc('c1', 0),
        treino: _treino(),
        progressoes: [
          RegistroProgressao(
              exercicio: 'Flexão', valor: 12, peso: 10, data: _hoje),
        ],
        checkins: [CheckIn(data: _hoje, exercicio: 'Flexão', corIndex: 0)],
      );
      expect(bloco, contains('## 2026-10-16 — Peito (completo)'));
      expect(bloco, contains('Flexão: plano 3×10 · 10kg · feito 12 reps · 10kg'));
      expect(bloco, contains('Barra: plano 5×5 · não feito'));
      expect(bloco, contains('Check-ins do dia: 1'));
      expect(bloco, contains('<!-- conclusao:c1:c -->'));
      for (final proibido in [
        'peso:',
        'cintura',
        'peito:',
        'coxa',
        'uid',
        'viniciostristao@gmail.com',
        'token',
        'chave',
        'Nota(',
      ]) {
        expect(bloco.contains(proibido), isFalse, reason: proibido);
      }
    });

    test('tentativa marca (tentativa)', () {
      final bloco = blocoDia(conclusao: _cc('c2', 0, completo: false));
      expect(bloco, contains('(tentativa)'));
      expect(bloco, contains('<!-- conclusao:c2:t -->'));
    });
  });

  group('carga inicial única', () {
    test('conta tudo uma vez e congela', () async {
      SharedPreferences.setMockInitialValues({});
      final drive = _DriveFake();
      final svc = _servico(drive, token: 'tok');
      final concs = [_cc('a', 10), _cc('b', 5, completo: false)];
      final checks = [
        CheckIn(data: _hoje.subtract(const Duration(days: 5)), exercicio: 'X', corIndex: 0),
        CheckIn(data: _hoje.subtract(const Duration(days: 5)), exercicio: 'Y', corIndex: 0),
      ];
      await svc.enviarAposConclusao(
        conclusao: _cc('novo', 0),
        treino: _treino(),
        progressoes: const [],
        checkins: checks,
        conclusoes: concs,
        interativo: false,
        agora: _hoje,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(chaveDriveResumoCarga), isTrue);
      final t1 = await totaisSalvos();
      // carga: 2 conclusões (1 completa + 1 tentativa) + 1 nova completa
      expect(t1.completos, 2);
      expect(t1.incompletos, 1);
      // dias: 10, 5 e hoje (check-ins caem no dia 5, já contado)
      expect(t1.dias.length, 3);
      expect(t1.checkins, 2);

      // Segunda execução com dados MUDADOS não recarrega.
      await svc.enviarAposConclusao(
        conclusao: _cc('outro', 0),
        conclusoes: [...concs, _cc('c', 1), _cc('d', 2), _cc('e', 3)],
        checkins: const [],
        interativo: false,
        agora: _hoje,
      );
      final t2 = await totaisSalvos();
      expect(t2.completos, 3); // +1 do 'outro', sem os 3 extras da carga
      expect(t2.incompletos, 1);
    });
  });

  group('idempotência e poda', () {
    test('mesmo treino duas vezes conta uma vez só', () async {
      SharedPreferences.setMockInitialValues({});
      final drive = _DriveFake();
      final svc = _servico(drive, token: 'tok');
      final conc = _cc('dup', 0);
      for (var i = 0; i < 2; i++) {
        await svc.enviarAposConclusao(
          conclusao: conc,
          treino: _treino(),
          conclusoes: [conc],
          checkins: const [],
          interativo: false,
        );
      }
      final t = await totaisSalvos();
      expect(t.completos, 1);
      final texto = drive.arquivos['treinos.md']!;
      expect('conclusao:dup'.allMatches(texto).length, 1);
    });

    test('upgrade tentativa -> completo troca o bloco e move a contagem', () async {
      SharedPreferences.setMockInitialValues({});
      final drive = _DriveFake();
      final svc = _servico(drive, token: 'tok');
      await svc.enviarAposConclusao(
        conclusao: _cc('up', 0, completo: false),
        conclusoes: [_cc('up', 0, completo: false)],
        checkins: const [],
        interativo: false,
        agora: _hoje,
      );
      await svc.enviarAposConclusao(
        conclusao: _cc('up', 0, completo: true),
        conclusoes: [_cc('up', 0, completo: true)],
        checkins: const [],
        interativo: false,
        agora: _hoje,
      );
      final t = await totaisSalvos();
      expect(t.completos, 1);
      expect(t.incompletos, 0);
      final texto = drive.arquivos['treinos.md']!;
      expect(texto, contains('(completo)'));
      expect(texto.contains('(tentativa)'), isFalse);
    });

    test('poda remove blocos > 4 meses sem mexer nos totais', () async {
      SharedPreferences.setMockInitialValues({});
      final drive = _DriveFake();
      final svc = _servico(drive, token: 'tok');
      // Totais pré-existentes contando um treino antigo (junho).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(chaveDriveResumoCarga, true);
      await prefs.setString(
          chaveDriveResumoTotais,
          '{"primeiro":0,"completos":1,"incompletos":0,'
          '"dias":["2026-06-01","2026-10-16"],"checkins":0,"contados":{}}');
      drive.arquivos['treinos.md'] =
          '# Calis Timer — treinos\n\n## 2026-06-01 — Costas (completo)\n'
          '- Check-ins do dia: 0\n<!-- conclusao:velho:c -->\n';
      await svc.enviarAposConclusao(
        conclusao: _cc('novo2', 0),
        conclusoes: [_cc('novo2', 0)],
        checkins: const [],
        interativo: false,
        agora: _hoje,
      );
      final texto = drive.arquivos['treinos.md']!;
      expect(texto.contains('2026-06-01'), isFalse);
      expect(texto, contains('2026-10-16'));
      final t = await totaisSalvos();
      expect(t.completos, 2); // 1 antigo (mantido) + 1 novo
      expect(t.dias, contains('2026-06-01'));
    });
  });

  group('pendentes e recriação', () {
    test('offline guarda pendente; online reenvia uma vez', () async {
      SharedPreferences.setMockInitialValues({});
      final drive = _DriveFake()..falharTudo = true;
      final svc = _servico(drive, token: 'tok');
      await svc.enviarAposConclusao(
        conclusao: _cc('p1', 0),
        conclusoes: [_cc('p1', 0)],
        checkins: const [],
        interativo: false,
        agora: _hoje,
      );
      var prefs = await SharedPreferences.getInstance();
      expect(
          prefs.getString(chaveDriveResumoPendentes), contains('p1'));
      expect(drive.arquivos.containsKey('treinos.md'), isFalse);

      drive.falharTudo = false;
      await svc.tentarPendentes(
        conclusoes: [_cc('p1', 0)],
        checkins: const [],
        interativo: false,
        agora: _hoje,
      );
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(chaveDriveResumoPendentes), '[]');
      expect(drive.arquivos['treinos.md'], contains('conclusao:p1'));
      expect(drive.salvamentos, 1);
    });

    test('arquivo sumido é recriado com os totais das prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final drive = _DriveFake();
      final svc = _servico(drive, token: 'tok');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(chaveDriveResumoCarga, true);
      await prefs.setString(
          chaveDriveResumoTotais,
          '{"primeiro":0,"completos":5,"incompletos":0,'
          '"dias":["2026-10-01"],"checkins":7,"contados":{}}');
      await prefs.setString(chaveDriveResumoFileId, 'id-treinos.md');
      // Drive sem o arquivo (apagado fora do app): ler falha.
      await svc.enviarAposConclusao(
        conclusao: _cc('re', 0),
        conclusoes: [_cc('re', 0)],
        checkins: const [],
        interativo: false,
        agora: _hoje,
      );
      final texto = drive.arquivos['treinos.md']!;
      expect(texto, contains('Treinos concluídos: 6 (6 completos · 0 tentativas)'));
      expect(texto, contains('Check-ins: 7'));
      expect(drive.pastaCriada, 'Calis Timer');
    });

    test('sem login/token não quebra e deixa pendente', () async {
      SharedPreferences.setMockInitialValues({});
      final drive = _DriveFake();
      final svc = _servico(drive); // sem token
      await svc.enviarAposConclusao(
        conclusao: _cc('s1', 0),
        conclusoes: [_cc('s1', 0)],
        checkins: const [],
        interativo: false,
        agora: _hoje,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(chaveDriveResumoPendentes), contains('s1'));
    });
  });
}
