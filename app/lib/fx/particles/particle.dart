import 'dart:ui';

/// Forma de uma partícula desenhada pelo [ParticlePainter].
enum ParticleShape { circle, spark, square }

/// **Uma partícula** — estado mutável integrado a cada frame pelo
/// [ParticleSystem]. Posição em pixels relativa ao centro do emissor.
class Particle {
  Offset pos;
  Offset vel; // px por segundo
  double life; // segundos restantes
  final double maxLife;
  final double size;
  final Color color;
  double rotation; // radianos
  final double spin; // rad/seg
  final ParticleShape shape;

  Particle({
    required this.pos,
    required this.vel,
    required this.maxLife,
    required this.size,
    required this.color,
    this.rotation = 0,
    this.spin = 0,
    this.shape = ParticleShape.circle,
  }) : life = maxLife;

  bool get alive => life > 0;

  /// Progresso de vida: 0 ao nascer → 1 ao morrer (para fade/encolher).
  double get t => maxLife <= 0 ? 1 : (1 - life / maxLife).clamp(0.0, 1.0);

  /// Integra um passo de tempo [dt] (segundos) com gravidade e arrasto.
  void step(double dt, {double gravity = 0, double drag = 0}) {
    final k = (1 - drag * dt).clamp(0.0, 1.0);
    vel = Offset(vel.dx * k, vel.dy * k + gravity * dt);
    pos += vel * dt;
    rotation += spin * dt;
    life -= dt;
  }
}
