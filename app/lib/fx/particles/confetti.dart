import 'dart:math';

import 'package:flutter/material.dart';

import '../fx_params.dart';
import 'particle.dart';
import 'particle_painter.dart';
import 'particle_system.dart';

/// **Chuva de confete.** Papéizinhos caem do topo, girando e derivando, e somem
/// ao chegar embaixo. Evolução do antigo `_ConfettiLayer` (que vivia solto no
/// `player_screen.dart`). Preenche o espaço disponível.
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({
    super.key,
    required this.colors,
    this.params = const FxParams(),
  });

  final List<Color> colors;
  final FxParams params;

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late final ParticleSystem _system =
      ParticleSystem(gravity: 260, drag: 0.15, rng: _rng);
  late final AnimationController _ctrl;
  Duration _last = Duration.zero;
  Size _area = Size.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: (widget.params.effectiveDuration.inMilliseconds * 2.4)
              .round()
              .clamp(1400, 7000)),
    )..addListener(_tick);
    _run();
  }

  void _seed(Size area) {
    final p = widget.params;
    final count = (p.particleCount * 1.4 * p.intensity).round().clamp(6, 400);
    final shapes = [ParticleShape.square, ParticleShape.circle];
    for (var i = 0; i < count; i++) {
      final x = (_rng.nextDouble() - 0.5) * area.width;
      final y = -area.height / 2 - _rng.nextDouble() * area.height * 0.6;
      _system.particles.add(Particle(
        pos: Offset(x, y),
        vel: Offset((_rng.nextDouble() - 0.5) * 60, 80 + _rng.nextDouble() * 120),
        maxLife: 1.6 + _rng.nextDouble() * 1.6,
        size: 4 + _rng.nextDouble() * 5,
        color: widget.colors[_rng.nextInt(widget.colors.length)],
        rotation: _rng.nextDouble() * pi,
        spin: (_rng.nextDouble() - 0.5) * 10,
        shape: shapes[_rng.nextInt(shapes.length)],
      ));
    }
  }

  void _run() {
    _last = Duration.zero;
    _ctrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      if (widget.params.loopForever && _area != Size.zero) {
        _seed(_area);
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
      child: LayoutBuilder(
        builder: (context, c) {
          final area = Size(
            c.maxWidth.isFinite ? c.maxWidth : 300.0,
            c.maxHeight.isFinite ? c.maxHeight : 400.0,
          );
          if (_area == Size.zero) {
            _area = area;
            _seed(area);
          }
          return CustomPaint(painter: ParticlePainter(_system), size: Size.infinite);
        },
      ),
    );
  }
}
