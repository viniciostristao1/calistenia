import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../effects/glow.dart';
import '../fx_params.dart';

/// **Baú-intro (abertura rápida).** Um baú compacto que aparece **fechado** e
/// espera um **toque**: a tampa abre só um pouco (mal mostra o interior) e o
/// baú **sai de cena** — quem entra em seguida é a revelação de verdade
/// (medalha/troféu/chama), chamada por quem usa este widget via [onFim].
///
/// É só a introdução: quem conduz a cerimônia é a tela que o chamou.
class ChestQuick extends StatefulWidget {
  const ChestQuick({super.key, this.params = const FxParams(), this.onFim});

  final FxParams params;

  /// Chamado quando a abertura termina (para a cerimônia seguir).
  final VoidCallback? onFim;

  @override
  State<ChestQuick> createState() => _ChestQuickState();
}

class _ChestQuickState extends State<ChestQuick> with TickerProviderStateMixin {
  /// Abre a tampa em ~300 ms.
  late final AnimationController _abre = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Pulsa o "toque para abrir".
  late final AnimationController _pulsa = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  bool _iniciado = false;

  @override
  void initState() {
    super.initState();
    _abre.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFim?.call();
    });
  }

  @override
  void dispose() {
    _abre.dispose();
    _pulsa.dispose();
    super.dispose();
  }

  void _tocar() {
    if (_iniciado) return;
    setState(() => _iniciado = true);
    _abre.forward();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tocar,
      child: SizedBox(
        width: 200,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GlowHalo(color: accent, diameter: 160, params: widget.params),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bau(accent),
                const SizedBox(height: 18),
                // Dica enquanto está fechado.
                AnimatedBuilder(
                  animation: _pulsa,
                  builder: (context, child) => Opacity(
                    opacity: _iniciado ? 0 : 0.35 + 0.4 * _pulsa.value,
                    child: child,
                  ),
                  child: Text(
                    'Toque para abrir',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bau(Color accent) {
    const corpo1 = Color(0xFF9A5B2A);
    const corpo2 = Color(0xFF6E3D1C);
    const tampa1 = Color(0xFF8A4E22);
    const tampa2 = Color(0xFF5E3417);
    const ouro = Color(0xFFF4C542);

    return SizedBox(
      width: 150,
      height: 116,
      child: AnimatedBuilder(
        animation: _abre,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_abre.value);
          // Dobradiça atrás: a tampa sobe um pouco e recua (abre ~28°).
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0016)
            ..translateByDouble(0, 0, 22, 1)
            ..rotateX(0.5 * t)
            ..translateByDouble(0, 0, -22, 1);
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Corpo.
              Positioned(
                bottom: 0,
                left: 12,
                right: 12,
                height: 62,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [corpo1, corpo2],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: ouro.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Faixa + fechadura.
              Positioned(
                bottom: 24,
                left: 12,
                right: 12,
                height: 8,
                child: const ColoredBox(color: ouro),
              ),
              Positioned(
                bottom: 18,
                child: Container(
                  width: 15,
                  height: 19,
                  decoration: BoxDecoration(
                    color: ouro,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Tampa (articulada atrás).
              Positioned(
                bottom: 58,
                left: 8,
                right: 8,
                height: 34,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: m,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [tampa1, tampa2],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                        bottom: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: ouro.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
