import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checkin.dart';
import '../models/conclusao.dart';
import '../models/registro_progressao.dart';
import '../models/treino.dart';
import '../util/format.dart';
import 'resumo_claude_service.dart';

/// Resumo automático do treino no Google Drive (`treinos.md`).
///
/// Fluxo: ao concluir um treino no player, o app monta um bloco do dia e o
/// acrescenta num arquivo único na pasta "Calis Timer" do Drive do usuário
/// (login Google que já existe, escopo `drive.file` — só arquivos do app).
/// Tudo é best-effort e nunca quebra o salvamento do treino.
///
/// Regras duras (pedido do usuário):
/// - o arquivo NUNCA recebe medidas, notas, uid, e-mail, tokens ou chaves — o
///   montador só recebe conclusão/treino/progressão/check-ins do dia;
/// - idempotência por marcador `<!-- conclusao:<id> -->` (a entrega pode
///   repetir; o mesmo treino nunca conta duas vezes);
/// - totais acumulados incrementais nas prefs (fonte da verdade); a poda dos
///   blocos > 4 meses nunca altera os totais.

const _escopoDriveFile = 'https://www.googleapis.com/auth/drive.file';
const _nomePasta = 'Calis Timer';
const _nomeArquivo = 'treinos.md';

const chaveDriveResumoFileId = 'drive_resumo_fileid_v1';
const chaveDriveResumoTotais = 'drive_resumo_totais_v1';
const chaveDriveResumoPendentes = 'drive_resumo_pendentes_v1';
const chaveDriveResumoRecusado = 'drive_resumo_recusado_v1';
const chaveDriveResumoCarga = 'drive_resumo_carga_inicial_v1';

/// Totais acumulados (nunca descartados; vivem nas prefs e no topo do arquivo).
class TotaisResumo {
  final int primeiroTreinoMs; // 0 = nenhum treino ainda
  final int completos;
  final int incompletos;
  final List<String> dias; // 'YYYY-MM-DD' únicos, ordenados
  final int checkins;
  final Map<String, int> contados; // conclusaoId -> check-ins já somados

  const TotaisResumo({
    this.primeiroTreinoMs = 0,
    this.completos = 0,
    this.incompletos = 0,
    this.dias = const [],
    this.checkins = 0,
    this.contados = const {},
  });

  Map<String, dynamic> toJson() => {
        'primeiro': primeiroTreinoMs,
        'completos': completos,
        'incompletos': incompletos,
        'dias': dias,
        'checkins': checkins,
        'contados': contados,
      };

  factory TotaisResumo.fromJson(Map<String, dynamic> j) => TotaisResumo(
        primeiroTreinoMs: (j['primeiro'] as num?)?.toInt() ?? 0,
        completos: (j['completos'] as num?)?.toInt() ?? 0,
        incompletos: (j['incompletos'] as num?)?.toInt() ?? 0,
        dias: [(j['dias'] as List?) ?? const []]
            .expand((e) => e)
            .map((e) => e.toString())
            .toSet()
            .toList()
          ..sort(),
        checkins: (j['checkins'] as num?)?.toInt() ?? 0,
        contados: {
          for (final e in ((j['contados'] as Map?) ?? const {}).entries)
            e.key.toString(): (e.value as num?)?.toInt() ?? 0,
        },
      );
}

/// Um bloco diário pendente (texto já montado — reenvio não precisa dos repos).
class PendenteResumo {
  final String id;
  final String diaKey;
  final String bloco;
  final bool completo;
  final int checkinsDia;

  const PendenteResumo({
    required this.id,
    required this.diaKey,
    required this.bloco,
    required this.completo,
    required this.checkinsDia,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dia': diaKey,
        'bloco': bloco,
        'completo': completo,
        'checks': checkinsDia,
      };

  factory PendenteResumo.fromJson(Map<String, dynamic> j) => PendenteResumo(
        id: j['id'].toString(),
        diaKey: j['dia'].toString(),
        bloco: j['bloco'].toString(),
        completo: j['completo'] == true,
        checkinsDia: (j['checks'] as num?)?.toInt() ?? 0,
      );
}

/// 'YYYY-MM-DD' pelos campos locais (conclusões já são meia-noite local —
/// sem conta de fuso, sem risco de virar o dia).
String diaChave(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Hoje em America/Sao_Paulo (UTC-3, sem horário de verão desde 2019).
String hojeChaveSP([DateTime? agora]) {
  final sp = (agora ?? DateTime.now()).toUtc().subtract(
        const Duration(hours: 3),
      );
  return diaChave(DateTime(sp.year, sp.month, sp.day));
}

/// Primeiro dia a manter: mês atual - 3 (ex.: em nov/2026, mantém >= ago/2026).
String corte4Meses([String? hojeKey]) {
  final h = hojeKey ?? hojeChaveSP();
  final ano = int.parse(h.substring(0, 4));
  final mes = int.parse(h.substring(5, 7));
  final total = ano * 12 + (mes - 1) - 3;
  final a = total ~/ 12;
  final m = total % 12 + 1;
  return '${a.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-01';
}

String _fmtDataLonga(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Linha do bloco para "completo" ou "tentativa".
String _estadoBloco(bool completo) => completo ? 'completo' : 'tentativa';

/// Monta o bloco do dia. Só usa conclusão/treino/progressão/check-ins —
/// nunca medidas, notas, uid ou e-mail (nem chegam aqui como parâmetro).
String blocoDia({
  required Conclusao conclusao,
  Treino? treino,
  List<RegistroProgressao> progressoes = const [],
  List<CheckIn> checkins = const [],
}) {
  final dia = diaChave(conclusao.data);
  final nome = conclusao.treino.trim().isEmpty ? 'Treino' : conclusao.treino;
  final b = StringBuffer(
      '## $dia — $nome (${_estadoBloco(conclusao.completo)})\n');
  final plano = {for (final e in (treino?.exercicios ?? const [])) e.nome: e};
  final nomesFeitos = <String>{};
  final porExercicio = <String, List<RegistroProgressao>>{};
  for (final p in progressoes) {
    nomesFeitos.add(p.exercicio);
    porExercicio.putIfAbsent(p.exercicio, () => []).add(p);
  }
  for (final c in checkins) {
    nomesFeitos.add(c.exercicio);
  }
  final ordem = [
    for (final e in (treino?.exercicios ?? const [])) e.nome,
    for (final n in nomesFeitos)
      if (!plano.containsKey(n)) n,
  ];
  for (final n in ordem) {
    final e = plano[n];
    final regs = porExercicio[n] ?? const [];
    final partes = <String>[];
    if (e != null) {
      var s = 'plano ${e.series}×${e.repeticoes}';
      if (e.pesoKg > 0) s += ' · ${fmtPeso(e.pesoKg)}';
      partes.add(s);
    }
    if (regs.isNotEmpty) {
      final r = regs.first;
      var s = 'feito ${r.valor} reps';
      if (r.peso > 0) s += ' · ${fmtPeso(r.peso)}';
      partes.add(s);
    } else if (checkins.any((c) => c.exercicio == n)) {
      partes.add('feito (check-in)');
    } else {
      partes.add('não feito');
    }
    b.writeln('- $n: ${partes.join(' · ')}');
  }
  b.writeln('- Check-ins do dia: ${checkins.length}');
  b.writeln('<!-- conclusao:${conclusao.id}:${conclusao.completo ? 'c' : 't'} -->');
  return b.toString();
}

/// Um bloco diário extraído do arquivo (para poda e idempotência).
class BlocoArquivo {
  final String chave; // 'YYYY-MM-DD' ou '' (fora do padrão)
  final String? conclusaoId;
  final bool? completo; // null = sem marcador / não é bloco de treino
  final String texto;

  const BlocoArquivo({
    required this.chave,
    this.conclusaoId,
    this.completo,
    required this.texto,
  });
}

final _reCabecalhoDia = RegExp(r'^## (\d{4}-\d{2}-\d{2})\b', multiLine: true);
final _reMarcador = RegExp(r'<!-- conclusao:([^>\s]+?)(?::(c|t))? -->');

/// Divide o conteúdo em blocos `## ...`. O preâmbulo (título + totais) volta
/// como bloco de chave '' e é sempre preservado.
List<BlocoArquivo> extrairBlocos(String conteudo) {
  final out = <BlocoArquivo>[];
  final inicios = _reCabecalhoDia.allMatches(conteudo).map((m) => m.start);
  final cortes = [0, ...inicios];
  if (cortes.length == 1) {
    if (conteudo.trim().isNotEmpty) {
      out.add(BlocoArquivo(chave: '', texto: conteudo));
    }
    return out;
  }
  for (var i = 0; i < cortes.length; i++) {
    final fim = i + 1 < cortes.length ? cortes[i + 1] : conteudo.length;
    final texto = conteudo.substring(cortes[i], fim);
    if (texto.trim().isEmpty) continue;
    if (i == 0) {
      out.add(BlocoArquivo(chave: '', texto: texto));
      continue;
    }
    final cab = _reCabecalhoDia.firstMatch(texto);
    final marc = _reMarcador.firstMatch(texto);
    out.add(BlocoArquivo(
      chave: cab != null ? cab.group(1)! : '',
      conclusaoId: marc?.group(1),
      completo: marc == null
          ? null
          : (marc.group(2) == null ? null : marc.group(2) == 'c'),
      texto: texto,
    ));
  }
  return out;
}

/// Remove blocos diários mais antigos que o corte (preâmbulo/totais intactos).
String podarBlocos(String conteudo, String corteKey) {
  final blocos = extrairBlocos(conteudo);
  final mantidos = blocos.where((b) =>
      b.chave.isEmpty || b.chave.compareTo(corteKey) >= 0);
  final corpo = mantidos.map((b) => b.texto).join().trimRight();
  return '$corpo\n';
}

String blocoTotais(TotaisResumo t, String atualizadoEm) {
  final b = StringBuffer('# Calis Timer — treinos\n\n');
  b.writeln('## Totais acumulados (atualizado em $atualizadoEm)');
  b.writeln(
      '- Primeiro treino: ${t.primeiroTreinoMs <= 0 ? '—' : _fmtDataLonga(DateTime.fromMillisecondsSinceEpoch(t.primeiroTreinoMs))}');
  b.writeln(
      '- Treinos concluídos: ${t.completos + t.incompletos} (${t.completos} completos · ${t.incompletos} tentativas)');
  b.writeln('- Dias treinados: ${t.dias.length}');
  b.writeln('- Check-ins: ${t.checkins}');
  return b.toString();
}

String montarArquivo({
  required TotaisResumo totais,
  required String atualizadoEm,
  required List<BlocoArquivo> diarios,
  String plano = '',
}) {
  final b = StringBuffer(blocoTotais(totais, atualizadoEm));
  b.writeln();
  if (plano.isNotEmpty) {
    b.write(plano.endsWith('\n') ? plano : '$plano\n');
    b.writeln();
  }
  for (final d in diarios) {
    b.write(d.texto);
    if (!d.texto.endsWith('\n')) b.write('\n');
  }
  final corpo = b.toString().trimRight();
  return '$corpo\n';
}

/// Carga inicial ÚNICA dos totais a partir do que já existe no app.
/// Dias treinados = união dos dias de conclusões e check-ins (mesma regra do
/// app: dia treinado = check-in OU conclusão). Todos os ids já existentes
/// entram em `contados` — o primeiro envio de um deles só anexa o bloco,
/// sem contar de novo (a conclusão nova já está persistida quando o player
/// chama o envio).
TotaisResumo cargaInicialTotais(
  List<Conclusao> conclusoes,
  List<CheckIn> checkins,
) {
  var primeiro = 0;
  var completos = 0;
  var incompletos = 0;
  final dias = <String>{};
  final checksPorDia = <String, int>{};
  for (final k in checkins) {
    final ms = k.data.millisecondsSinceEpoch;
    if (primeiro == 0 || ms < primeiro) primeiro = ms;
    final chave = diaChave(k.data);
    dias.add(chave);
    checksPorDia.update(chave, (v) => v + 1, ifAbsent: () => 1);
  }
  for (final c in conclusoes) {
    final ms = c.data.millisecondsSinceEpoch;
    if (primeiro == 0 || ms < primeiro) primeiro = ms;
    if (c.completo) {
      completos++;
    } else {
      incompletos++;
    }
    dias.add(diaChave(c.data));
  }
  final lista = dias.toList()..sort();
  return TotaisResumo(
    primeiroTreinoMs: primeiro,
    completos: completos,
    incompletos: incompletos,
    dias: lista,
    checkins: checkins.length,
    contados: {
      for (final c in conclusoes)
        c.id: checksPorDia[diaChave(c.data)] ?? 0,
    },
  );
}

/// Soma UM treino novo (só chamar com o marcador de idempotência ausente).
TotaisResumo somarTotais(
  TotaisResumo t,
  Conclusao c,
  int checkinsDia,
  String diaKey,
) {
  final dias = {...t.dias, diaKey}.toList()..sort();
  var primeiro = t.primeiroTreinoMs;
  final ms = c.data.millisecondsSinceEpoch;
  if (primeiro == 0 || ms < primeiro) primeiro = ms;
  return TotaisResumo(
    primeiroTreinoMs: primeiro,
    completos: t.completos + (c.completo ? 1 : 0),
    incompletos: t.incompletos + (c.completo ? 0 : 1),
    dias: dias,
    checkins: t.checkins + checkinsDia,
    contados: {...t.contados, c.id: checkinsDia},
  );
}

/// Ajusta quando uma tentativa vira completo (mesmo id, bloco substituído).
TotaisResumo trocarFlagTotais(TotaisResumo t, int checkinsDiaNovo) {
  return TotaisResumo(
    primeiroTreinoMs: t.primeiroTreinoMs,
    completos: t.completos + 1,
    incompletos: t.incompletos > 0 ? t.incompletos - 1 : 0,
    dias: t.dias,
    checkins: t.checkins + checkinsDiaNovo,
    contados: t.contados,
  );
}

/// IO do Drive atrás de interface (testes usam fake; app usa a real).
abstract class DriveArquivos {
  Future<String?> acharArquivoId(String nomePasta, String nomeArquivo);
  Future<String> ler(String fileId);
  Future<void> salvar(String fileId, String texto);
  Future<String> criar(String nomePasta, String nomeArquivo, String texto);
}

/// Provedor de token OAuth (`drive.file`); null = sem autorização.
typedef ProvedorToken = Future<String?> Function({required bool interativo});

class _ClienteToken extends http.BaseClient {
  _ClienteToken(this._token);
  final String _token;
  final _interno = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _interno.send(request);
  }
}

bool _ehNaoEncontrado(Object e) =>
    e.toString().contains('notFound') ||
    e.toString().contains(' 404') ||
    e.toString().contains('File not found');

class DriveArquivosGoogle implements DriveArquivos {
  DriveArquivosGoogle(this._token);
  final String _token;

  drive.DriveApi get _api => drive.DriveApi(_ClienteToken(_token));

  @override
  Future<String?> acharArquivoId(String nomePasta, String nomeArquivo) async {
    final api = _api;
    final pastas = await api.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and "
          "name = '$nomePasta' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id)',
      pageSize: 5,
    );
    if ((pastas.files ?? const []).isEmpty) return null;
    final res = await api.files.list(
      q: "name = '$nomeArquivo' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id)',
      pageSize: 10,
    );
    if ((res.files ?? const []).isEmpty) return null;
    return res.files!.first.id;
  }

  Future<String> _pastaIdOuCriar(String nomePasta) async {
    final api = _api;
    final pastas = await api.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and "
          "name = '$nomePasta' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id)',
      pageSize: 5,
    );
    if ((pastas.files ?? const []).isNotEmpty) {
      return pastas.files!.first.id!;
    }
    final criada = await api.files.create(
      drive.File(
        name: nomePasta,
        mimeType: 'application/vnd.google-apps.folder',
      ),
      $fields: 'id',
    );
    return criada.id!;
  }

  drive.Media _midia(String texto) {
    final bytes = utf8.encode(texto);
    return drive.Media(Stream.value(bytes), bytes.length);
  }

  @override
  Future<String> ler(String fileId) async {
    final media =
        await _api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia)
            as drive.Media;
    final bytes = await media.stream.fold<List<int>>(
        [], (acum, parte) => acum..addAll(parte));
    return utf8.decode(bytes);
  }

  @override
  Future<void> salvar(String fileId, String texto) async {
    await _api.files.update(drive.File(), fileId, uploadMedia: _midia(texto));
  }

  @override
  Future<String> criar(
      String nomePasta, String nomeArquivo, String texto) async {
    final pastaId = await _pastaIdOuCriar(nomePasta);
    final criado = await _api.files.create(
      drive.File(
          name: nomeArquivo, parents: [pastaId], mimeType: 'text/markdown'),
      uploadMedia: _midia(texto),
      $fields: 'id',
    );
    return criado.id!;
  }
}

/// Orquestra o envio (nunca lança: erro vira pendente + log eventual).
class DriveResumoService {
  DriveResumoService({DriveArquivos? arquivos, ProvedorToken? tokens})
      : _arquivosFixo = arquivos,
        _tokensFixo = tokens;

  final DriveArquivos? _arquivosFixo;
  final ProvedorToken? _tokensFixo;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  TotaisResumo _totaisDoJson(String? raw) {
    if (raw == null || raw.isEmpty) return const TotaisResumo();
    try {
      return TotaisResumo.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TotaisResumo();
    }
  }

  List<PendenteResumo> _pendentesDoJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return [(jsonDecode(raw) as List)]
          .expand((e) => e)
          .map((e) => PendenteResumo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<DriveArquivos?> _arquivos({required bool interativo}) async {
    final token = await _token(interativo: interativo);
    if (token == null) return null;
    if (_arquivosFixo != null) return _arquivosFixo;
    return DriveArquivosGoogle(token);
  }

  Future<String?> _token({required bool interativo}) async {
    final tokens = _tokensFixo;
    if (tokens != null) {
      return tokens(interativo: interativo);
    }
    try {
      if (FirebaseAuth.instance.currentUser == null) return null;
      final cliente = GoogleSignIn.instance.authorizationClient;
      final silencioso =
          await cliente.authorizationForScopes([_escopoDriveFile]);
      if (silencioso != null) return silencioso.accessToken;
      if (!interativo) return null;
      try {
        final prefs = await _prefs();
        if (prefs.getBool(chaveDriveResumoRecusado) == true) return null;
        final comUi = await cliente.authorizeScopes([_escopoDriveFile]);
        return comUi.accessToken;
      } catch (_) {
        final prefs = await _prefs();
        await prefs.setBool(chaveDriveResumoRecusado, true);
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Carga inicial ÚNICA (primeira execução): totais do que já existe no app.
  Future<TotaisResumo> _garantirCargaInicial(
    SharedPreferences prefs,
    List<Conclusao> conclusoes,
    List<CheckIn> checkins,
  ) async {
    var totais = _totaisDoJson(prefs.getString(chaveDriveResumoTotais));
    if (prefs.getBool(chaveDriveResumoCarga) == true) return totais;
    totais = cargaInicialTotais(conclusoes, checkins);
    await prefs.setString(
        chaveDriveResumoTotais, jsonEncode(totais.toJson()));
    await prefs.setBool(chaveDriveResumoCarga, true);
    return totais;
  }

  /// Entrada do player, logo após `registrar()` retornar a conclusão.
  /// Nunca lança.
  Future<void> enviarAposConclusao({
    required Conclusao conclusao,
    Treino? treino,
    List<RegistroProgressao> progressoes = const [],
    List<CheckIn> checkins = const [],
    List<Conclusao> conclusoes = const [],
    List<Treino> treinos = const [],
    bool interativo = true,
    DateTime? agora,
  }) async {
    try {
      final diaKey = diaChave(conclusao.data);
      final progsDia = progressoes
          .where((p) => diaChave(p.data) == diaKey)
          .toList();
      final checksDia =
          checkins.where((c) => diaChave(c.data) == diaKey).toList();
      final bloco = blocoDia(
        conclusao: conclusao,
        treino: treino,
        progressoes: progsDia,
        checkins: checksDia,
      );
      final pendente = PendenteResumo(
        id: conclusao.id,
        diaKey: diaKey,
        bloco: bloco,
        completo: conclusao.completo,
        checkinsDia: checksDia.length,
      );
      final prefs = await _prefs();
      await _guardarPendente(prefs, pendente);
      await _enviarPendente(
        prefs,
        pendente,
        conclusoes: conclusoes,
        checkinsTodos: checkins,
        treinos: treinos,
        interativo: interativo,
        agora: agora,
      );
    } catch (_) {
      // best-effort: o treino já está salvo; o pendente tenta depois.
      return;
    }
  }

  /// Reenvia os pendentes (arranque do app = silencioso; nunca lança).
  Future<void> tentarPendentes({
    required List<Conclusao> conclusoes,
    required List<CheckIn> checkins,
    List<Treino> treinos = const [],
    bool interativo = false,
    DateTime? agora,
  }) async {
    try {
      final prefs = await _prefs();
      final pendentes =
          _pendentesDoJson(prefs.getString(chaveDriveResumoPendentes));
      for (final p in pendentes) {
        await _enviarPendente(
          prefs,
          p,
          conclusoes: conclusoes,
          checkinsTodos: checkins,
          treinos: treinos,
          interativo: interativo,
          agora: agora,
        );
      }
    } catch (_) {
      /* best-effort */
    }
  }

  Future<void> _guardarPendente(
      SharedPreferences prefs, PendenteResumo p) async {
    final lista = _pendentesDoJson(prefs.getString(chaveDriveResumoPendentes))
        .where((e) => e.id != p.id)
        .toList()
      ..add(p);
    await prefs.setString(chaveDriveResumoPendentes,
        jsonEncode(lista.map((e) => e.toJson()).toList()));
  }

  Future<void> _removerPendente(SharedPreferences prefs, String id) async {
    final lista = _pendentesDoJson(prefs.getString(chaveDriveResumoPendentes))
        .where((e) => e.id != id)
        .toList();
    await prefs.setString(chaveDriveResumoPendentes,
        jsonEncode(lista.map((e) => e.toJson()).toList()));
  }

  Future<void> _enviarPendente(
    SharedPreferences prefs,
    PendenteResumo pendente, {
    required List<Conclusao> conclusoes,
    required List<CheckIn> checkinsTodos,
    required List<Treino> treinos,
    required bool interativo,
    DateTime? agora,
  }) async {
    var totais = await _garantirCargaInicial(prefs, conclusoes, checkinsTodos);
    final drive = await _arquivos(interativo: interativo);
    if (drive == null) return; // sem login/autorização: fica pendente
    final agoraSp = (agora ?? DateTime.now()).toUtc().subtract(
          const Duration(hours: 3),
        );
    final hojeTxt = _fmtDataLonga(agoraSp);
    var fileId = prefs.getString(chaveDriveResumoFileId);
    String? conteudo;
    if (fileId != null) {
      try {
        conteudo = await drive.ler(fileId);
      } catch (e) {
        if (!_ehNaoEncontrado(e)) return; // offline/outro erro: tenta depois
        fileId = null; // sumiu: recria abaixo a partir das prefs
      }
    }
    final plano = ResumoClaude.blocoPlanoSemanal(treinos, hojeTxt);
    if (fileId == null) {
      fileId = await drive.criar(
          _nomePasta,
          _nomeArquivo,
          montarArquivo(
              totais: totais,
              atualizadoEm: hojeTxt,
              diarios: const [],
              plano: plano));
      await prefs.setString(chaveDriveResumoFileId, fileId);
      conteudo = null;
    }
    conteudo ??= await drive.ler(fileId);
    final blocos = extrairBlocos(conteudo);
    final marcador = 'conclusao:${pendente.id}';
    final existente = blocos.where((b) => b.texto.contains(marcador));
    final corte = corte4Meses(diaChave(agoraSp));
    if (existente.isNotEmpty) {
      final flagArquivo = existente.first.completo;
      final mesmoEstado = flagArquivo ??
          existente.first.texto
              .contains('(${_estadoBloco(pendente.completo)})');
      if (mesmoEstado) {
        if (!totais.contados.containsKey(pendente.id)) {
          // Arquivo tem o bloco mas as prefs perderam a conta: recupera.
          totais = _somarComControle(
              totais, pendente.completo, pendente.checkinsDia, pendente.diaKey, pendente.id);
          await prefs.setString(chaveDriveResumoTotais,
              jsonEncode(totais.toJson()));
        }
        await _removerPendente(prefs, pendente.id);
        return;
      }
      // Upgrade tentativa -> completo: troca o bloco e move a contagem.
      final restantes =
          blocos.where((b) => !b.texto.contains(marcador)).toList();
      totais = _trocarFlag(totais, pendente.checkinsDia,
          pendente.diaKey, pendente.id);
      final diarios = _diariosMantidos(restantes, corte)
        ..add(BlocoArquivo(
            chave: pendente.diaKey,
            conclusaoId: pendente.id,
            completo: pendente.completo,
            texto: pendente.bloco));
      await drive.salvar(
          fileId,
          montarArquivo(
              totais: totais,
              atualizadoEm: hojeTxt,
              diarios: diarios,
              plano: plano));
      await prefs.setString(
          chaveDriveResumoTotais, jsonEncode(totais.toJson()));
      await _removerPendente(prefs, pendente.id);
      return;
    }
    // Novo: acrescenta e soma (só se o marcador ainda não contou).
    final diarios = _diariosMantidos(blocos, corte)
      ..add(BlocoArquivo(
          chave: pendente.diaKey,
          conclusaoId: pendente.id,
          completo: pendente.completo,
          texto: pendente.bloco));
    if (!totais.contados.containsKey(pendente.id)) {
      totais = _somarComControle(totais, pendente.completo,
          pendente.checkinsDia, pendente.diaKey, pendente.id);
    }
    await prefs.setString(
        chaveDriveResumoTotais, jsonEncode(totais.toJson()));
    await drive.salvar(
        fileId,
        montarArquivo(
            totais: totais,
            atualizadoEm: hojeTxt,
            diarios: diarios,
            plano: plano));
    await _removerPendente(prefs, pendente.id);
  }

  TotaisResumo _somarComControle(TotaisResumo t, bool completo,
      int checkinsDia, String diaKey, String id) {
    final dias = {...t.dias, diaKey}.toList()..sort();
    return TotaisResumo(
      primeiroTreinoMs: t.primeiroTreinoMs,
      completos: t.completos + (completo ? 1 : 0),
      incompletos: t.incompletos + (completo ? 0 : 1),
      dias: dias,
      checkins: t.checkins + checkinsDia,
      contados: {...t.contados, id: checkinsDia},
    );
  }

  /// Troca tentativa -> completo (o registrar nunca rebaixa): move 1 de
  /// incompletos para completos, mantendo o id contado uma única vez.
  TotaisResumo _trocarFlag(TotaisResumo t, int checkinsNovo,
      String diaKey, String id) {
    final anterior = t.contados[id] ?? 0;
    final dias = {...t.dias, diaKey}.toList()..sort();
    return TotaisResumo(
      primeiroTreinoMs: t.primeiroTreinoMs,
      completos: t.completos + 1,
      incompletos: t.incompletos > 0 ? t.incompletos - 1 : 0,
      dias: dias,
      checkins: t.checkins - anterior + checkinsNovo,
      contados: {...t.contados, id: checkinsNovo},
    );
  }

  List<BlocoArquivo> _diariosMantidos(
      List<BlocoArquivo> blocos, String corte) {
    return blocos
        .where((b) => b.chave.isNotEmpty && b.chave.compareTo(corte) >= 0)
        .toList();
  }
}

final driveResumoServiceProvider = Provider<DriveResumoService>((ref) {
  return DriveResumoService();
});
