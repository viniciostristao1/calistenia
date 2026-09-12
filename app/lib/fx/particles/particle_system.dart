import 'dart:math';
import 'dart:ui';

import 'particle.dart';

/// **Física simples de um conjunto de partículas.** Emite rajadas e integra o
/// tempo. Sem dependências — só matemática. Desenho fica no [ParticlePainter].
class ParticleSystem {
  ParticleSystem({this.gravity = 0, this.drag = 0, Random? rng})
      : _rng = rng ?? Random();

  final double gravity; // px/seg² (positivo = cai)
  final double drag; // 0..~4 (atrito do ar)
  final Random _rng;

  final List<Particle> particles = [];

  bool get isEmpty => particles.isEmpty;

  double _lerp(double a, double b) => a + (b - a) * _rng.nextDouble();

  /// Emite uma rajada a partir da origem (0,0 = centro do emissor).
  ///
  /// [direction] é o ângulo central (radianos; -π/2 = para cima) e [spread] a
  /// abertura total do leque (2π = explosão radial completa).
  void emitBurst({
    required int count,
    required List<Color> colors,
    double direction = -pi / 2,
    double spread = 2 * pi,
    double speedMin = 120,
    double speedMax = 320,
    double sizeMin = 3,
    double sizeMax = 7,
    double lifeMin = 0.6,
    double lifeMax = 1.1,
    List<ParticleShape> shapes = const [ParticleShape.circle],
  }) {
    for (var i = 0; i < count; i++) {
      final ang = direction + (_rng.nextDouble() - 0.5) * spread;
      final speed = _lerp(speedMin, speedMax);
      particles.add(Particle(
        pos: Offset.zero,
        vel: Offset(cos(ang) * speed, sin(ang) * speed),
        maxLife: _lerp(lifeMin, lifeMax),
        size: _lerp(sizeMin, sizeMax),
        color: colors[_rng.nextInt(colors.length)],
        rotation: _rng.nextDouble() * pi,
        spin: (_rng.nextDouble() - 0.5) * 8,
        shape: shapes[_rng.nextInt(shapes.length)],
      ));
    }
  }

  /// Integra [dt] segundos e remove as partículas mortas.
  void step(double dt) {
    for (final p in particles) {
      p.step(dt, gravity: gravity, drag: drag);
    }
    particles.removeWhere((p) => !p.alive);
  }
}
