import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'checkin_repository.dart';
import 'conclusao_repository.dart';
import 'conquistas_repository.dart';
import 'insignias_repository.dart';
import 'progressao_repository.dart';
import 'treinos_repository.dart';

/// Sincroniza treinos, check-ins, progressão, conclusões, conquistas e insígnias
/// com o Firestore quando o usuário está logado. Cada store é guardado como o
/// MESMO JSON do shared_preferences, num campo do documento `users/{uid}`.
///
/// Estratégia: no 1º carregamento faz **união por id** (não perde dados de
/// nenhum lado); depois, "última escrita vence" por documento — o SDK do
/// Firestore cuida do cache offline e do reenvio.
class SyncController {
  SyncController(this.ref);
  final Ref ref;

  String? _uid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _debounce;
  bool _aplicandoRemoto = false;
  bool _primeiroSnapshot = true;
  String? _ultimoSync; // "impressão" do último estado sincronizado (anti-loop)

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  /// Liga a sincronização para [uid].
  void start(String uid) {
    if (_uid == uid) return;
    stop();
    _uid = uid;
    _primeiroSnapshot = true;
    _ultimoSync = null;
    _sub = _doc(uid).snapshots().listen(_onRemote, onError: (_) {});
  }

  /// Desliga (logout).
  void stop() {
    _sub?.cancel();
    _sub = null;
    _debounce?.cancel();
    _uid = null;
  }

  void dispose() => stop();

  /// Chamado quando um store local muda -> agenda um envio para a nuvem.
  void onLocalChange() {
    if (_aplicandoRemoto || _uid == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final uid = _uid;
      if (uid == null) return;
      await _push(uid, await SharedPreferences.getInstance());
    });
  }

  Future<void> _onRemote(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final uid = _uid;
    if (uid == null) return;
    // Ignora o "eco" das próprias escritas locais ainda não confirmadas.
    if (snap.metadata.hasPendingWrites) return;

    final prefs = await SharedPreferences.getInstance();

    if (!snap.exists || snap.data() == null) {
      // Nuvem vazia (1º uso da conta): sobe o que está local.
      _primeiroSnapshot = false;
      await _push(uid, prefs);
      return;
    }

    final data = snap.data()!;
    if (_primeiroSnapshot) {
      // 1ª vez neste aparelho: une local + nuvem (não perde de nenhum lado).
      _primeiroSnapshot = false;
      _aplicandoRemoto = true;
      _mergeChave(prefs, chaveTreinos, data['treinos']);
      _mergeChave(prefs, chaveCheckin, data['checkins']);
      _mergeChave(prefs, chaveProgressao, data['progressao']);
      _mergeChave(prefs, chaveConclusao, data['conclusao']);
      _mergeChave(prefs, chaveConquistas, data['conquistas']);
      _mergeChave(prefs, chaveInsignias, data['insignias']);
      _invalidar();
      _aplicandoRemoto = false;
      _ultimoSync = _estado(prefs);
      await _push(uid, prefs); // grava o resultado da união na nuvem
      return;
    }
    // Se o conteúdo remoto é o que já temos, ignora (evita o loop de
    // updatedAt: cada push muda o timestamp e voltaria como "mudança").
    final estadoRemoto = _estadoDe(data['treinos'], data['checkins'],
        data['progressao'], data['conclusao'], data['conquistas'],
        data['insignias']);
    if (estadoRemoto == _ultimoSync) return;
    // Outro aparelho editou de verdade: a nuvem manda.
    _aplicandoRemoto = true;
    _aplicarChave(prefs, chaveTreinos, data['treinos']);
    _aplicarChave(prefs, chaveCheckin, data['checkins']);
    _aplicarChave(prefs, chaveProgressao, data['progressao']);
    _aplicarChave(prefs, chaveConclusao, data['conclusao']);
    _aplicarChave(prefs, chaveConquistas, data['conquistas']);
    _aplicarChave(prefs, chaveInsignias, data['insignias']);
    _invalidar();
    _aplicandoRemoto = false;
    _ultimoSync = _estado(prefs);
  }

  Future<void> _push(String uid, SharedPreferences prefs) async {
    final estado = _estado(prefs);
    if (estado == _ultimoSync) return; // nada mudou de verdade -> não empurra
    _ultimoSync = estado;
    try {
      await _doc(uid).set({
        'treinos': prefs.getString(chaveTreinos) ?? '[]',
        'checkins': prefs.getString(chaveCheckin) ?? '[]',
        'progressao': prefs.getString(chaveProgressao) ?? '[]',
        'conclusao': prefs.getString(chaveConclusao) ?? '[]',
        'conquistas': prefs.getString(chaveConquistas) ?? '[]',
        'insignias': prefs.getString(chaveInsignias) ?? '[]',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // offline/sem permissão: o cache do Firestore reenvia quando possível.
    }
  }

  /// "Impressão" do conteúdo dos 3 stores (sem o updatedAt), para detectar se
  /// algo mudou de verdade e cortar o loop de sincronização.
  String _estado(SharedPreferences prefs) => _estadoDe(
        prefs.getString(chaveTreinos),
        prefs.getString(chaveCheckin),
        prefs.getString(chaveProgressao),
        prefs.getString(chaveConclusao),
        prefs.getString(chaveConquistas),
        prefs.getString(chaveInsignias),
      );

  String _estadoDe(dynamic t, dynamic c, dynamic p, dynamic cc, dynamic cq,
          dynamic ci) =>
      '${t ?? ''}§${c ?? ''}§${p ?? ''}§${cc ?? ''}§${cq ?? ''}§${ci ?? ''}';

  void _aplicarChave(SharedPreferences prefs, String chave, dynamic remoto) {
    if (remoto is String) prefs.setString(chave, remoto);
  }

  /// União por id: nuvem vence em conflito; itens só-locais são preservados.
  void _mergeChave(SharedPreferences prefs, String chave, dynamic remoto) {
    final local = _parse(prefs.getString(chave));
    final rem = _parse(remoto is String ? remoto : null);
    final porId = <String, Map<String, dynamic>>{};
    for (final e in rem) {
      final id = e['id'];
      if (id is String) porId[id] = e;
    }
    for (final e in local) {
      final id = e['id'];
      if (id is String) porId.putIfAbsent(id, () => e);
    }
    prefs.setString(chave, jsonEncode(porId.values.toList()));
  }

  List<Map<String, dynamic>> _parse(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  void _invalidar() {
    ref.invalidate(treinosProvider);
    ref.invalidate(checkinProvider);
    ref.invalidate(progressaoProvider);
    ref.invalidate(conclusaoProvider);
    ref.invalidate(conquistasProvider);
    ref.invalidate(insigniasProvider);
  }
}

/// Mantém a sincronização ligada conforme o login e observa os stores locais.
/// Instancie-o com um `ref.watch(syncProvider)` em um ponto vivo do app.
final syncProvider = Provider<SyncController>((ref) {
  final controller = SyncController(ref);
  ref.onDispose(controller.dispose);

  ref.listen(authStateProvider, (prev, next) {
    final user = next.asData?.value;
    if (user != null) {
      controller.start(user.uid);
    } else {
      controller.stop();
    }
  }, fireImmediately: true);

  // Mudanças locais -> envio (o controller decide se está logado).
  ref.listen(treinosProvider, (_, _) => controller.onLocalChange());
  ref.listen(checkinProvider, (_, _) => controller.onLocalChange());
  ref.listen(progressaoProvider, (_, _) => controller.onLocalChange());
  ref.listen(conclusaoProvider, (_, _) => controller.onLocalChange());
  ref.listen(conquistasProvider, (_, _) => controller.onLocalChange());
  ref.listen(insigniasProvider, (_, _) => controller.onLocalChange());

  return controller;
});
