import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shading.dart';

/// **Conteúdo: estrela 3D facetada** — o "desenho" da recompensa Estrela.
///
/// Pintura à mão (`CustomPainter`) para dar VOLUME: silhueta arredondada,
/// extrusão (espessura nas costas), 10 facetas com iluminação direcional,
/// bisel (luz no topo-esquerda / sombra embaixo-direita), núcleo em relevo e
/// brilhos especulares. Não anima: quem gira no próprio eixo é o átomo
/// `Spin3D` — conteúdo e movimento continuam separados.
class Star3D extends StatelessWidget {
  const Star3D({
    super.key,
    this.size = 104,
    this.color = const Color(0xFFF4C542),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _Star3DPainter(color: color),
  );
}

class _Star3DPainter extends CustomPainter {
  _Star3DPainter({required this.color});

  final Color color;

  /// Direção da luz (topo-esquerda), normalizada.
  static const _light = Offset(-0.50, -0.87);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    final r = s * 0.5 - s * 0.045;
    final ri = r * 0.52;
    final path = _starPath(c, r, ri);

    // Silhueta arredondada: o contorno grosso de base "engorda" as pontas.
    final silhouette = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeJoin = StrokeJoin.round
      ..color = shade(color, 0.30);

    // 1) Sombra projetada — descola a estrela do fundo.
    canvas.drawShadow(path, const Color(0xAA3A2400), s * 0.12, false);

    // 2) Extrusão: 3 cópias deslocadas (o "lado" da estrela).
    for (var k = 3; k >= 1; k--) {
      final off = Offset(s * 0.020 * k, s * 0.020 * k);
      canvas.drawPath(path.shift(off), silhouette);
    }

    // 3) Face principal com gradiente (luz → sombra).
    final faceRect = Rect.fromCircle(center: c, radius: r * 1.18);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighten(color, 0.42), color, shade(color, 0.26)],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(faceRect),
    );

    // 4) Facetas: 2 triângulos por ponta (sulco central → relevo 3D).
    final pts = _starPoints(c, r, ri);
    for (var i = 0; i < 5; i++) {
      final tip = pts[i * 2];
      final left = pts[(i * 2 - 1 + 10) % 10];
      final right = pts[(i * 2 + 1) % 10];
      _facet(canvas, c, tip, left);
      _facet(canvas, c, tip, right);
      // Sulco central de cada ponta (aresta do relevo).
      final lit = ((tip - c).direction <= 0) || (tip.dx < c.dx);
      canvas.drawLine(
        c + (tip - c) * 0.30,
        c + (tip - c) * 0.94,
        Paint()
          ..color = (lit ? Colors.white : Colors.black).withValues(alpha: 0.16)
          ..strokeWidth = s * 0.014
          ..strokeCap = StrokeCap.round,
      );
    }

    // 5) Núcleo: pentágono em relevo + estrela interna gravada.
    final core = _starPath(c, ri, ri * 0.55, points: 5);
    canvas.drawPath(
      core,
      Paint()
        ..shader = RadialGradient(
          colors: [
            lighten(color, 0.22).withValues(alpha: 0.85),
            shade(color, 0.32).withValues(alpha: 0.85),
          ],
          radius: 0.9,
        ).createShader(Rect.fromCircle(center: c, radius: ri)),
    );
    canvas.drawPath(
      _starPath(c, ri * 0.62, ri * 0.30),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..strokeJoin = StrokeJoin.round
        ..color = shade(color, 0.45).withValues(alpha: 0.55),
    );

    // 6) Bisel: luz na borda de cima-esquerda, sombra na de baixo-direita.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.038
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.0),
            shade(color, 0.55).withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(faceRect),
    );

    // 7) Brilhos especulares.
    final glint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.022);
    canvas.save();
    canvas.translate(c.dx - r * 0.26, c.dy - r * 0.34);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.24, height: s * 0.085),
      glint,
    );
    canvas.restore();
    canvas.drawCircle(
      c + Offset(r * 0.20, 0),
      s * 0.022,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );

    // 8) Faíscas de canto.
    _sparkle(canvas, c + Offset(-r * 0.62, -r * 0.10), s * 0.045);
    _sparkle(canvas, c + Offset(r * 0.36, -r * 0.58), s * 0.032);
    _sparkle(canvas, c + Offset(r * 0.46, r * 0.34), s * 0.024);
  }

  /// Triângulo de uma faceta, com tom conforme a luz que incide nela.
  void _facet(Canvas canvas, Offset c, Offset tip, Offset inner) {
    final tri = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(inner.dx, inner.dy)
      ..close();
    final mid = (c + tip + inner) / 3;
    var dir = mid - c;
    final len = dir.distance;
    if (len > 0) dir = dir / len;
    final lambert = (dir.dx * _light.dx + dir.dy * _light.dy).clamp(-1.0, 1.0);
    final t = (0.5 + 0.5 * lambert).clamp(0.0, 1.0);
    canvas.drawPath(
      tri,
      Paint()
        ..color = Color.lerp(
          shade(color, 0.48),
          lighten(color, 0.55),
          t,
        )!.withValues(alpha: 0.72),
    );
  }

  /// Faísca de 4 pontas (losango côncavo).
  void _sparkle(Canvas canvas, Offset p, double r) {
    canvas.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  Path _starPath(
    Offset c,
    double outer,
    double inner, {
    int points = 5,
    double start = -math.pi / 2,
  }) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final rad = i.isEven ? outer : inner;
      final a = start + i * math.pi / points;
      final p = c + Offset(math.cos(a), math.sin(a)) * rad;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  List<Offset> _starPoints(Offset c, double outer, double inner) => [
    for (var i = 0; i < 10; i++)
      c +
          Offset(
                math.cos(-math.pi / 2 + i * math.pi / 5),
                math.sin(-math.pi / 2 + i * math.pi / 5),
              ) *
              (i.isEven ? outer : inner),
  ];

  @override
  bool shouldRepaint(_Star3DPainter old) => old.color != color;
}
