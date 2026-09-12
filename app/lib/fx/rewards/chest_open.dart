import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../effects/bounce.dart';
import '../effects/fly_to_target.dart';
import '../effects/screen_flash.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';

/// **Recompensa: baú abrindo** — a molécula mais composta, showcase da camada.
/// Timeline (fração do tempo): antecipação + `Shake` (0–0.3) → tampa abre em
/// 2.5D (0.32–0.66) → clarão (`ScreenFlash`) + luz + `ParticleBurst` → a
/// recompensa salta pra fora (`FlyToTarget` + `Bounce`, 0.55–1.0).
class ChestOpen extends StatefulWidget {
  const ChestOpen({super.key, this.params = const FxParams()});

  final FxParams params;

  @override
  State<ChestOpen> createState() => _ChestOpenState();
}

class _ChestOpenState extends State<ChestOpen>
    with SingleTickerProviderStateMixin {
  static const _corpo1 = Color(0xFF9A5B2A);
  static const _corpo2 = Color(0xFF7A4420);
  static const _tampa1 = Color(0xFF8A4E22);
  static const _tampa2 = Color(0xFF5E3417);
  static const _ouro = Color(0xFFF4C542);

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

  /// Parâmetros mais curtos para os átomos que entram no meio do timeline.
  FxParams get _revealParams => FxParams(
        duration: Duration(
            milliseconds:
                (widget.params.effectiveDuration.inMilliseconds * 0.55).round()),
        intensity: widget.params.intensity,
        scale: widget.params.scale,
      );

  double get _intensity => widget.params.intensity.clamp(0.0, 2.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final v = _ctrl.value;
          final aberto = v > 0.34;
          final glowA = (Interval(0.34, 0.52).transform(v)) *
              (1 - 0.4 * Interval(0.75, 1.0).transform(v)) *
              0.5 *
              _intensity;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Partículas saindo para cima (leque), atrás.
              aberto
                  ? ParticleBurst(
                      params: widget.params,
                      colors: const [_ouro, Colors.white, Color(0xFFFFC93C)],
                      shapes: const [ParticleShape.spark, ParticleShape.circle],
                      direction: -pi / 2,
                      spread: 1.7,
                      gravity: 420,
                    )
                  : const SizedBox.shrink(),
              // Luz saindo do interior.
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _ouro.withValues(alpha: glowA.clamp(0.0, 1.0)),
                    _ouro.withValues(alpha: 0),
                  ]),
                ),
              ),
              // O baú (corpo + tampa articulada).
              _chest(v),
              // A recompensa saltando pra fora.
              v > 0.55
                  ? FlyToTarget(
                      params: _revealParams,
                      begin: const Offset(0, 8),
                      end: Offset(0, -92 * _intensity.clamp(0.4, 2.0)),
                      child: Bounce(
                        params: _revealParams,
                        drop: 8,
                        child: Icon(Icons.star_rounded,
                            size: 48,
                            color: AppColors.estrela,
                            shadows: [
                              Shadow(
                                  color:
                                      AppColors.estrela.withValues(alpha: 0.6),
                                  blurRadius: 20),
                            ]),
                      ),
                    )
                  : const SizedBox.shrink(),
              // Clarão breve ao abrir.
              v > 0.30
                  ? ScreenFlash(params: _revealParams, peak: 0.30)
                  : const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }

  Widget _chest(double v) {
    // Antecipação: tremida que amortece nos primeiros 30%.
    final shakeT = Interval(0.0, 0.30).transform(v);
    final dx = sin(shakeT * 4 * 2 * pi) * 6 * (1 - shakeT) * _intensity;
    // Tampa abre para trás (rotateX) entre 32% e 66%.
    final lidT = Interval(0.32, 0.66, curve: Curves.easeOutBack).transform(v);
    final lidAngle = -1.45 * lidT.clamp(0.0, 1.2);

    return Transform.translate(
      offset: Offset(dx, 0),
      child: SizedBox(
        width: 150,
        height: 120,
        child: Stack(
          children: [
            // Corpo.
            Positioned(
              bottom: 0,
              left: 15,
              right: 15,
              height: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_corpo1, _corpo2],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _ouro.withValues(alpha: 0.7), width: 2),
                ),
              ),
            ),
            // Faixa dourada.
            Positioned(
              bottom: 28,
              left: 15,
              right: 15,
              height: 9,
              child: const ColoredBox(color: _ouro),
            ),
            // Fechadura.
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 16,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _ouro,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            // Tampa (articulada na base = borda de trás).
            Positioned(
              bottom: 70,
              left: 11,
              right: 11,
              height: 40,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016)
                  ..rotateX(lidAngle),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_tampa1, _tampa2],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10), bottom: Radius.circular(3)),
                    border: Border.all(color: _ouro.withValues(alpha: 0.7), width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
