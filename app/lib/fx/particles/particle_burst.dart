import 'dart:math';

import 'package:flutter/material.dart';

import '../fx_params.dart';
import 'particle.dart';
import 'particle_painter.dart';
import 'particle_system.dart';

/// **Explosão radial de partículas** — átomo visual pronto para compor dentro
/// de recompensas (estrela, baú, reveal). Emite uma rajada e a integra por
/// frame com um [AnimationController].
///
/// Respeita [FxParams]: `particleCount` (× `intensity`), `intensity` (alcance),
/// `speed`/`duration` (tempo de vida) e `repeat`/loop.
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.colors,
    this.params = const FxParams(),
    this.shapes = const [ParticleShape.circle, ParticleShape.spark],
    this.direction = -pi / 2,
    this.spread = 2 * pi,
    this.gravity = 220,
  });

  final List<Color> colors;
  final FxParams params;
  final List<ParticleShape> shapes;

  /// Ângulo central (radianos) e abertura do leque. Padrão: explosão radial.
  final double direction;
  final double spread;

  /// Gravidade (px/seg²) — dá um arco natural às partículas.
  final double gravity;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final ParticleSystem _system;
  late final AnimationController _ctrl;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _system = ParticleSystem(gravity: widget.gravity, drag: 0.6);
    _emit();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.params.effectiveDuration + const Duration(milliseconds: 250),
    )..addListener(_tick);
    _run();
  }

  void _emit() {
    final p = widget.params;
    final life = (p.effectiveDuration.inMilliseconds / 1000).clamp(0.4, 3.0);
    _system.emitBurst(
      count: (p.particleCount * p.intensity).round().clamp(0, 400),
      colors: widget.colors,
      shapes: widget.shapes,
      direction: widget.direction,
      spread: widget.spread,
      speedMin: 90 * p.intensity,
      speedMax: 300 * p.intensity,
      lifeMin: life * 0.55,
      lifeMax: life,
    );
  }

  void _run() {
    _last = Duration.zero;
    _ctrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      if (widget.params.loopForever) {
        _emit();
        _run();
      }
    });
  }

  void _tick() {
    final now = _ctrl.lastElapsedDuration ?? Duration.zero;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt > 0) {
      _system.step(dt);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: ParticlePainter(_system),
        size: Size.infinite,
      ),
    );
  }
}
