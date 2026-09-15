import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **Relógio da UI.** Emite `DateTime.now()` no arranque, a cada 30 s e sempre
/// que o app volta do segundo plano.
///
/// Existe porque textos com hora (ex.: a previsão "~hora" de fim do treino nos
/// cartões) eram calculados só no `build`: sem nada mudando na tela, o valor
/// ficava **preso** (aparecia no passado depois de um treino longo ou de o app
/// voltar do fundo). Quem mostra hora deve `ref.watch(relogioProvider)` — e,
/// ao voltar de uma rota que pode ter consumido tempo (ex.: o player), chamar
/// `ref.invalidate(relogioProvider)` para reemitir na hora.
final relogioProvider = StreamProvider<DateTime>((ref) {
  final ctrl = StreamController<DateTime>();
  void agora() {
    if (!ctrl.isClosed) ctrl.add(DateTime.now());
  }

  agora();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => agora());
  final obs = _VoltaDoFundo(agora);
  WidgetsBinding.instance.addObserver(obs);

  ref.onDispose(() {
    timer.cancel();
    WidgetsBinding.instance.removeObserver(obs);
    ctrl.close();
  });
  return ctrl.stream;
});

class _VoltaDoFundo with WidgetsBindingObserver {
  _VoltaDoFundo(this.aoVoltar);

  final VoidCallback aoVoltar;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) aoVoltar();
  }
}
