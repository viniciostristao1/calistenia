import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/versao.dart';
import 'checkin_repository.dart';
import 'conclusao_repository.dart';
import 'conquistas_repository.dart';
import 'gamificacao_pref.dart';
import 'insignias_repository.dart';
import 'lembretes_service.dart';
import 'progressao_repository.dart';
import 'som_repository.dart';
import 'tema_repository.dart';
import 'treinos_repository.dart';

/// Backup manual em ARQUIVO `.json` — a "segunda via" além do Firebase/Google.
///
/// Junta num único arquivo todo o estado guardado localmente (cada store é a
/// mesma string JSON do `shared_preferences`) e:
///  - **Exportar:** grava um `.json` e abre o share sheet (mandar pro Drive,
///    e-mail, WhatsApp, salvar no aparelho...).
///  - **Importar:** lê um `.json` desses de volta e restaura tudo.

/// Stores de DADOS (progressão, check-in, conclusões, conquistas, insígnias,
/// treinos) — é o que reconstrói a Progressão e o Rating.
const List<String> _chavesDados = [
  chaveTreinos, // 'treinos_v1'
  chaveCheckin, // 'checkin_v1'
  chaveProgressao, // 'progressao_v1'
  chaveConclusao, // 'conclusao_v1'
  chaveConquistas, // 'conquistas_v1'
  chaveInsignias, // 'insignias_v1'
];

/// Preferências (tema, som, gamificação, lembretes) — completam o backup.
const List<String> _chavesConfig = [
  'tema_v1',
  'som_v1',
  'gamificacao_v1',
  'lembretes_v1',
];

const String _marcaApp = 'calis-timer';
const int _formato = 1;

/// Resultado de uma importação, para a UI dar um retorno claro ao usuário.
class ResultadoImport {
  final bool ok;
  final String mensagem;
  const ResultadoImport(this.ok, this.mensagem);
}

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Monta o arquivo de backup e abre o share sheet do sistema.
Future<void> exportarBackup() async {
  final prefs = await SharedPreferences.getInstance();
  final stores = <String, dynamic>{};
  for (final k in [..._chavesDados, ..._chavesConfig]) {
    final v = prefs.getString(k);
    if (v != null) stores[k] = v; // guarda a string JSON crua de cada store
  }

  final agora = DateTime.now();
  final envelope = {
    'app': _marcaApp,
    'formato': _formato,
    'versao': kVersao,
    'exportadoEm': agora.toIso8601String(),
    'stores': stores,
  };
  final texto = const JsonEncoder.withIndent('  ').convert(envelope);

  final dir = await getTemporaryDirectory();
  final nome =
      'calis-timer-backup-${agora.year}-${_pad2(agora.month)}-${_pad2(agora.day)}.json';
  final arquivo = File('${dir.path}/$nome');
  await arquivo.writeAsString(texto);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(arquivo.path, mimeType: 'application/json')],
      subject: 'Backup do Calis Timer',
      text: 'Backup dos meus treinos e progresso (Calis Timer).',
    ),
  );
}

/// Deixa o usuário escolher um `.json` de backup e restaura os dados.
/// Substitui os stores presentes no arquivo (não faz merge) e recarrega a UI.
Future<ResultadoImport> importarBackup(WidgetRef ref) async {
  final escolha = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (escolha == null || escolha.files.isEmpty) {
    return const ResultadoImport(false, 'Importação cancelada.');
  }

  final f = escolha.files.single;
  String texto;
  try {
    if (f.bytes != null) {
      texto = utf8.decode(f.bytes!);
    } else if (f.path != null) {
      texto = await File(f.path!).readAsString();
    } else {
      return const ResultadoImport(false, 'Não foi possível ler o arquivo.');
    }
  } catch (e) {
    return ResultadoImport(false, 'Falha ao abrir o arquivo: $e');
  }

  Map<String, dynamic> env;
  try {
    env = jsonDecode(texto) as Map<String, dynamic>;
  } catch (_) {
    return const ResultadoImport(false, 'Arquivo não é um JSON válido.');
  }

  if (env['app'] != _marcaApp || env['stores'] is! Map) {
    return const ResultadoImport(
        false, 'Este arquivo não é um backup do Calis Timer.');
  }

  final stores = (env['stores'] as Map).cast<String, dynamic>();
  final prefs = await SharedPreferences.getInstance();
  var n = 0;
  for (final k in [..._chavesDados, ..._chavesConfig]) {
    final v = stores[k];
    if (v is String) {
      await prefs.setString(k, v);
      n++;
    }
  }

  if (n == 0) {
    return const ResultadoImport(
        false, 'O backup não continha dados reconhecidos.');
  }

  _invalidarTudo(ref);

  final quando = env['exportadoEm'];
  final origem = quando is String
      ? ' (de ${quando.split('T').first})'
      : '';
  return ResultadoImport(true, 'Backup restaurado$origem.');
}

/// Recarrega todos os providers a partir do disco (cada `build()` relê os
/// prefs). Se estiver logado, a mudança também sobe para a nuvem sozinha.
void _invalidarTudo(WidgetRef ref) {
  ref.invalidate(treinosProvider);
  ref.invalidate(checkinProvider);
  ref.invalidate(progressaoProvider);
  ref.invalidate(conclusaoProvider);
  ref.invalidate(conquistasProvider);
  ref.invalidate(insigniasProvider);
  ref.invalidate(temaProvider);
  ref.invalidate(somProvider);
  ref.invalidate(gamificacaoProvider);
  ref.invalidate(lembretesConfigProvider);
}
