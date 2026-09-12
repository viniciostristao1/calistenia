import 'dart:math';

import 'package:flutter/material.dart';

import 'particle.dart';
import 'particle_system.dart';

/// Desenha as partículas do [ParticleSystem] centradas no meio da área. Cada
/// partícula some (fade) e encolhe conforme envelhece.
class ParticlePainter extends CustomPainter {
  ParticlePainter(this.system) : super(repaint: null);

  final ParticleSystem system;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in system.particles) {
      final fade = (1 - p.t).clamp(0.0, 1.0);
      if (fade <= 0) continue;
      paint.color = p.color.withValues(alpha: fade);
      final o = center + p.pos;
      final r = p.size * (0.4 + 0.6 * fade); // encolhe ao morrer

      switch (p.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(o, r, paint);
        case ParticleShape.square:
          canvas.save();
          canvas.translate(o.dx, o.dy);
          canvas.rotate(p.rotation);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2), paint);
          canvas.restore();
        case ParticleShape.spark:
          _drawSpark(canvas, o, r * 1.4, p.rotation, paint);
      }
    }
  }

  /// Brilho de 4 pontas (estrelinha).
  void _drawSpark(Canvas canvas, Offset c, double r, double rot, Paint paint) {
    final path = Path();
    const points = 4;
    for (var i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final rr = isOuter ? r : r * 0.32;
      final a = rot + i * pi / points;
      final pt = c + Offset(cos(a) * rr, sin(a) * rr);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
