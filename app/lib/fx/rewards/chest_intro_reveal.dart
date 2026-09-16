import 'dart:async';

import 'package:flutter/material.dart';

import '../fx_params.dart';
import 'chest_open2.dart';

/// **Baú-intro + revelação** (conquista/sequência): mostra o **mesmo baú** dos
/// outros no modo rápido (fechado → toque → tampa abre só um pouco) e, quando a
/// abertura termina, ele **sai de cena** e entra o [child] — a revelação de
/// verdade (medalha/troféu via `IconReveal`, chama via `FlameReveal`), como já
/// era. Ao fim da revelação, chama [onFim] para a cerimônia seguir.
class ChestIntroReveal extends StatefulWidget {
  const ChestIntroReveal({
    super.key,
    this.params = const FxParams(),
    required this.child,
    this.onFim,
    this.esperaRevelacao = const Duration(milliseconds: 1200),
  });

  final FxParams params;

  /// A revelação mostrada depois que o baú abre.
  final Widget child;

  /// Chamado quando a revelação termina.
  final VoidCallback? onFim;

  /// Quanto tempo a revelação fica em cena antes de avisar o [onFim].
  final Duration esperaRevelacao;

  @override
  State<ChestIntroReveal> createState() => _ChestIntroRevealState();
}

class _ChestIntroRevealState extends State<ChestIntroReveal> {
  bool _revelado = false;
  Timer? _fim;

  @override
  void dispose() {
    _fim?.cancel();
    super.dispose();
  }

  void _abriu() {
    if (_revelado) return;
    setState(() => _revelado = true);
    _fim = Timer(widget.esperaRevelacao, () => widget.onFim?.call());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _revelado
          ? KeyedSubtree(key: const ValueKey('revelacao'), child: widget.child)
          : ChestOpen2(
              key: const ValueKey('bau'),
              params: widget.params,
              rapido: true,
              onFim: _abriu,
            ),
    );
  }
}
