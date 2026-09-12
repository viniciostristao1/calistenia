import 'dart:async';

import 'package:flutter/material.dart';

/// **Átomo: atrasar o nascimento do filho.** Monta o filho só depois de
/// [delay] — como cada átomo inicia seus controllers no `initState`, isso
/// sincroniza o efeito com um momento específico da timeline (ex.: partículas
/// explodindo no pouso do item, não no nascimento dele).
class Delayed extends StatefulWidget {
  const Delayed({super.key, required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<Delayed> {
  Timer? _timer;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay <= Duration.zero) {
      _show = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _show = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _show ? widget.child : const SizedBox.shrink();
}
