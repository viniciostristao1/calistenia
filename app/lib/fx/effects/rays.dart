import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fx_params.dart';

/// **Átomo: raios radiais girando ao fundo (holofote).**
///
/// Leque de raios alternados que gira devagar e "respira" com a intensidade —
/// o palco de recompensa da linguagem de jogos mobile, atrás do item.
/// Pintura à mão em [CustomPainter], zero dependências.
class RadialRays extends StatefulWidget {
  const RadialRays({
    super.key,
    this.color = Colors.white,
    this.diameter = 220,
    this.rayCount = 12,
    this.params = const FxParams(),
  });

  final Color color;
  final double diameter;
  final int rayCount;
  final FxParams params;

  @override
  State<RadialRays> createState() => _RadialRaysState();
}

class _RadialRaysState extends State<RadialRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (widget.params.effectiveDuration.inMilliseconds * 2.4)
          .round()
          .clamp(400, 8000),
    ),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter * widget.params.scale;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => IgnorePointer(
        child: CustomPaint(
          size: Size.square(d),
          painter: _RaysPainter(
            color: widget.color,
            rotation: _ctrl.value * 2 * math.pi,
            rayCount: widget.rayCount,
            intensity: widget.params.intensity.clamp(0.0, 2.0),
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter({
    required this.color,
    required this.rotation,
    required this.rayCount,
    required this.intensity,
  });

  final Color color;
  final double rotation;
  final int rayCount;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final half = math.pi / rayCount * 0.5;
    for (var i = 0; i < rayCount; i++) {
      final alpha = ((i.isEven ? 0.28 : 0.13) * intensity).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      final ang = rotation + i * 2 * math.pi / rayCount;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rect, ang - half, half * 2, false)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) =>
      old.rotation != rotation ||
      old.color != color ||
      old.intensity != intensity ||
      old.rayCount != rayCount;
}
