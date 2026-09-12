import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../fx_params.dart';

/// **Recompensa: +XP.** "+N XP" surge com um pequeno salto, sobe e some
/// suavemente — o feedback rápido de ganho.
class XpGain extends StatefulWidget {
  const XpGain({
    super.key,
    this.params = const FxParams(),
    this.value = 10,
  });

  final FxParams params;
  final num value;

  @override
  State<XpGain> createState() => _XpGainState();
}

class _XpGainState extends State<XpGain> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.params.effectiveDuration,
  );

  @override
  void initState() {
    super.initState();
    widget.params.loopForever ? _ctrl.repeat() : _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rise = 70 * widget.params.intensity.clamp(0.0, 2.0);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final v = _ctrl.value;
        // Salto de entrada (escala) nos primeiros 25%.
        final pop = 0.6 +
            0.4 * Interval(0.0, 0.25, curve: Curves.easeOutBack).transform(v);
        // Sobe ao longo de todo o efeito.
        final dy = -rise * Curves.easeOut.transform(v);
        // Aparece rápido, some no fim.
        final fadeIn = Interval(0.0, 0.15).transform(v);
        final fadeOut = 1 - Interval(0.65, 1.0).transform(v);
        final op = (fadeIn * fadeOut).clamp(0.0, 1.0);
        return Opacity(
          opacity: op,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
                scale: (pop * widget.params.scale).clamp(0.0, 3.0), child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.estrela.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.estrela, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.estrela, size: 22),
            const SizedBox(width: 4),
            Text(
              '+${widget.value.round()} XP',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
