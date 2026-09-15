import 'dart:async';

import 'package:flutter/material.dart';

import 'fx_params.dart';
import 'reward_registry.dart';
import 'reward_type.dart';

/// **A API pública da camada de efeitos — o "QUANDO/ONDE".**
///
/// Dispara uma recompensa flutuando sobre a tela atual, via [Overlay] nativo:
/// zero acoplamento com o layout de quem chama. É o jeito recomendado de
/// celebrar algo de qualquer tela:
///
/// ```dart
/// RewardFx.show(context, RewardType.star, value: 50);
/// RewardFx.show(context, RewardType.chest, onDone: () { ... });
/// ```
///
/// Quando quiser o efeito EMBUTIDO numa caixa específica (ex.: a tela "Treino
/// concluído"), use `RewardRegistry.build(context, type, params)` direto num
/// widget, sem overlay.
class RewardFx {
  RewardFx._();

  /// Mostra [type] sobre a tela. Auto-descarta ao terminar.
  /// [value] fica reservado para efeitos que exibem um número (ex.: "+50 XP").
  static void show(
    BuildContext context,
    RewardType type, {
    FxParams params = const FxParams(),
    num? value,
    VoidCallback? onDone,
    bool dismissOnTap = true,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _RewardHost(
        params: params,
        dismissOnTap: dismissOnTap,
        onDone: () {
          if (entry.mounted) entry.remove();
          onDone?.call();
        },
        child: RewardRegistry.build(ctx, type, params, value: value),
      ),
    );
    overlay.insert(entry);
  }
}

/// Camada de tela que centraliza o efeito e o remove sozinha quando termina.
class _RewardHost extends StatefulWidget {
  const _RewardHost({
    required this.child,
    required this.params,
    required this.onDone,
    this.dismissOnTap = true,
  });

  final Widget child;
  final FxParams params;
  final VoidCallback onDone;

  /// `false` = o primeiro toque é do filho (ex.: abrir o baú), não dispensa.
  final bool dismissOnTap;

  @override
  State<_RewardHost> createState() => _RewardHostState();
}

class _RewardHostState extends State<_RewardHost> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Uma passada só no overlay (o loop é um recurso do Laboratório).
    // Com o toque do filho (baú), damos mais tempo para o usuário abrir.
    final ms =
        widget.params.delay.inMilliseconds +
        widget.params.effectiveDuration.inMilliseconds +
        (widget.dismissOnTap ? 600 : 3200);
    _timer = Timer(Duration(milliseconds: ms), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Toque em qualquer lugar dispensa (útil e inofensivo). Nos efeitos com
    // toque próprio (baú), o toque vai para o filho.
    return GestureDetector(
      behavior: widget.dismissOnTap
          ? HitTestBehavior.opaque
          : HitTestBehavior.deferToChild,
      onTap: widget.dismissOnTap ? widget.onDone : null,
      child: Center(child: widget.child),
    );
  }
}
