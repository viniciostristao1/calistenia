import 'dart:math';

import 'package:flutter/material.dart';

import '../effects/delayed.dart';
import '../effects/glow.dart';
import '../effects/pop_in.dart';
import '../effects/rays.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';
import '../../theme/app_colors.dart';

/// **Recompensa: sequência (chama).** A chama é desenhada à mão e **anima de
/// verdade**: cada língua balança no próprio ritmo (senos com fases diferentes)
/// e o corpo pulsa como fogo. Compõe holofote + halo + faíscas subindo + a
/// chama + o rótulo.
class FlameReveal extends StatefulWidget {
  const FlameReveal({
    super.key,
    this.params = const FxParams(),
    this.color = const Color(0xFFFF7A1A),
    this.label,
  });

  final FxParams params;
  final Color color;
  final String? label;

  @override
  State<FlameReveal> createState() => _FlameRevealState();
}

class _FlameRevealState extends State<FlameReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.params.effectiveDuration,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.color;
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RadialRays(color: cor, diameter: 220, params: widget.params),
          // Faíscas subindo (gravidade negativa = sobem e aceleram).
          Delayed(
            delay: Duration(
              milliseconds:
                  (widget.params.effectiveDuration.inMilliseconds * 0.35)
                      .round(),
            ),
            child: ParticleBurst(
              params: widget.params,
              colors: [cor, const Color(0xFFFFD43B), Colors.white],
              shapes: const [ParticleShape.spark, ParticleShape.circle],
              direction: -pi / 2,
              spread: 1.2,
              gravity: -140,
            ),
          ),
          GlowHalo(color: cor, diameter: 190, params: widget.params),
          PopIn(
            params: widget.params,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                size: const Size(150, 196),
                painter: _FlamePainter(t: _ctrl.value, color: cor),
              ),
            ),
          ),
          if (widget.label != null) ...[
            Positioned(
              bottom: 8,
              child: _Label(texto: widget.label!, params: widget.params),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.texto, required this.params});

  final String texto;
  final FxParams params;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: params.effectiveDuration,
    builder: (context, t, child) {
      final op = Interval(0.35, 0.7).transform(t).clamp(0.0, 1.0);
      return Opacity(
        opacity: op,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - op)),
          child: child,
        ),
      );
    },
    child: Text(
      texto,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// Pinta a chama: 3 línguas + núcleo, com as pontas balançando.
class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.t, required this.color});

  final double t; // 0..1 (loop)
  final Color color;

  static Color _shade(Color base, double amount) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _lighten(Color base, double amount) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness(
          (hsl.lightness + (1 - hsl.lightness) * amount).clamp(0.0, 1.0),
        )
        .toColor();
  }

  void _tongue(
    Canvas canvas, {
    required double cx,
    required double baseY,
    required double w,
    required double h,
    required double tipDx,
    required double tipDy,
    required List<Color> colors,
  }) {
    final tip = Offset(cx + tipDx, baseY - h + tipDy);
    final path = Path()
      ..moveTo(cx - w / 2, baseY)
      ..cubicTo(
        cx - w * 0.60,
        baseY - h * 0.42,
        tip.dx - w * 0.36,
        tip.dy + h * 0.34,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        tip.dx + w * 0.36,
        tip.dy + h * 0.34,
        cx + w * 0.60,
        baseY - h * 0.42,
        cx + w / 2,
        baseY,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: colors,
        ).createShader(Rect.fromLTRB(cx - w, tip.dy, cx + w, baseY)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * 2 * pi;
    final s = size.width;
    final cx = size.width / 2;
    final baseY = size.height - 4;

    // Respiração/pulso do fogo (squash & stretch em torno da base).
    final pulso = sin(phase * 1.7);
    canvas.save();
    canvas.translate(cx, baseY);
    canvas.scale(1 + 0.035 * pulso, 1 - 0.035 * pulso);
    canvas.translate(-cx, -baseY);

    // Base arredondada (une as línguas).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY),
        width: s * 0.52,
        height: s * 0.16,
      ),
      Paint()..color = color,
    );

    // Língua externa (laranja escuro nas pontas).
    _tongue(
      canvas,
      cx: cx,
      baseY: baseY,
      w: s * 0.80,
      h: s * 1.18,
      tipDx: sin(phase) * s * 0.055,
      tipDy: sin(phase * 1.3 + 0.6) * s * 0.03,
      colors: [color, _shade(color, 0.35)],
    );
    // Língua média.
    _tongue(
      canvas,
      cx: cx,
      baseY: baseY,
      w: s * 0.56,
      h: s * 0.84,
      tipDx: sin(phase + 1.2) * s * 0.04,
      tipDy: sin(phase * 1.5 + 1.0) * s * 0.022,
      colors: [_lighten(color, 0.10), color],
    );
    // Língua interna (amarela).
    _tongue(
      canvas,
      cx: cx,
      baseY: baseY,
      w: s * 0.34,
      h: s * 0.56,
      tipDx: sin(phase + 2.4) * s * 0.028,
      tipDy: sin(phase * 1.8 + 2.0) * s * 0.015,
      colors: [const Color(0xFFFFD43B), _lighten(color, 0.28)],
    );
    // Núcleo.
    _tongue(
      canvas,
      cx: cx,
      baseY: baseY,
      w: s * 0.17,
      h: s * 0.33,
      tipDx: sin(phase + 3.3) * s * 0.018,
      tipDy: 0,
      colors: [Colors.white, const Color(0xFFFFE07A)],
    );

    // Brasas subindo dentro da chama.
    for (var i = 0; i < 3; i++) {
      final f = (t * 1.6 + i / 3) % 1.0;
      final dy = baseY - f * s * 0.95 + sin(phase * 2 + i) * 4;
      final dx = cx + sin(phase * 1.6 + i * 2.1) * s * 0.10 * (1 - f);
      final alpha = (1 - f) * 0.7;
      canvas.drawCircle(
        Offset(dx, dy),
        s * 0.016 * (1 - f * 0.4),
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.t != t || old.color != color;
}
