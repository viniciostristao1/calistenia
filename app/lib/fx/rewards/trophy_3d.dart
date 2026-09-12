import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shading.dart';

/// **Conteúdo: troféu 3D (ouro/prata)** — copo metálico desenhado à mão, com
/// alças, aro, haste, base e brilhos. Parametrizado por [metal], serve aos dois
/// troféus (`trophyGold`/`trophySilver`). Não anima: o giro no próprio eixo
/// fica com o átomo `Spin3D`.
class Trophy3D extends StatelessWidget {
  const Trophy3D({
    super.key,
    this.size = 116,
    this.metal = const Color(0xFFF4C542),
  });

  final double size;
  final Color metal;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _TrophyPainter(metal: metal),
  );
}

class _TrophyPainter extends CustomPainter {
  _TrophyPainter({required this.metal});

  final Color metal;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 120);
    _groundShadow(canvas);
    _handles(canvas);
    _cup(canvas);
    _stem(canvas);
    _base(canvas);
    canvas.restore();
  }

  /// Gradiente "cilindro metálico": sombra, reflexo, cor, reflexo, sombra.
  Paint _metalFill(Rect rect) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        shade(metal, 0.52),
        lighten(metal, 0.55),
        metal,
        lighten(metal, 0.40),
        shade(metal, 0.62),
      ],
      stops: const [0.0, 0.20, 0.45, 0.68, 1.0],
    ).createShader(rect);

  void _groundShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 113), width: 64, height: 10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _handles(Canvas canvas) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = shade(metal, 0.55);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..shader = _metalFill(const Rect.fromLTWH(0, 20, 120, 45)).shader;
    final light = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = lighten(metal, 0.85).withValues(alpha: 0.9);

    for (final sign in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(60 + sign * 29, 28)
        ..cubicTo(60 + sign * 48, 21, 60 + sign * 53, 47, 60 + sign * 31, 54);
      canvas.drawPath(path, outline);
      canvas.drawPath(path, fill);
      canvas.save();
      canvas.translate(sign * -1.2, -1.6);
      canvas.drawPath(path, light);
      canvas.restore();
    }
  }

  void _cup(Canvas canvas) {
    final bowl = Path()
      ..moveTo(34, 20)
      ..cubicTo(30, 38, 34, 54, 46, 61)
      ..cubicTo(50, 63, 55, 65, 60, 65)
      ..cubicTo(65, 65, 70, 63, 74, 61)
      ..cubicTo(86, 54, 90, 38, 86, 20)
      ..close();
    final bounds = bowl.getBounds();
    canvas.drawPath(bowl, _metalFill(bounds));

    canvas.save();
    canvas.clipPath(bowl);
    // Sombra à direita (volume do cilindro).
    canvas.drawRect(
      Rect.fromLTWH(76, 18, 16, 52),
      Paint()..color = shade(metal, 0.38).withValues(alpha: 0.5),
    );
    // Reflexo à esquerda.
    canvas.drawRect(
      Rect.fromLTWH(37, 18, 6, 54),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );
    // Glint difuso.
    canvas.save();
    canvas.translate(43, 37);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 17, height: 7),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.restore();
    // Estrela gravada.
    _engravedStar(canvas, const Offset(60, 42), 12);
    canvas.restore();

    // Contorno (separa do fundo e dá peso).
    canvas.drawPath(
      bowl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = shade(metal, 0.6).withValues(alpha: 0.8),
    );

    // Aro: boca escura + anel metálico + luz.
    final inside = Rect.fromCenter(
      center: const Offset(60, 21),
      width: 54,
      height: 11,
    );
    canvas.drawOval(inside, Paint()..color = shade(metal, 0.78));
    final rim = Rect.fromCenter(
      center: const Offset(60, 20.5),
      width: 58,
      height: 14,
    );
    canvas.drawOval(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..shader = _metalFill(rim).shader,
    );
    canvas.drawArc(
      rim.deflate(0.5),
      math.pi * 1.08,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  void _stem(Canvas canvas) {
    final stem = Rect.fromLTWH(54, 64, 12, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stem, const Radius.circular(3)),
      _metalFill(stem),
    );
    final collar = Rect.fromLTWH(50, 61.5, 20, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar, const Radius.circular(2.5)),
      _metalFill(collar),
    );
    canvas.drawRect(
      Rect.fromLTWH(57, 66, 2.2, 16),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _base(Canvas canvas) {
    final plinth = Rect.fromLTWH(43, 80, 34, 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plinth, const Radius.circular(3)),
      _metalFill(plinth),
    );

    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(31, 86.5, 58, 23),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF54402E), Color(0xFF241A12)],
        ).createShader(base.outerRect),
    );

    final plaque = Rect.fromLTWH(36, 89, 48, 6.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plaque, const Radius.circular(2)),
      _metalFill(plaque),
    );

    canvas.drawRRect(
      base.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = metal.withValues(alpha: 0.35),
    );
    canvas.drawLine(
      const Offset(33, 87.5),
      const Offset(87, 87.5),
      Paint()
        ..strokeWidth = 1.6
        ..color = lighten(metal, 0.5).withValues(alpha: 0.5),
    );

    // Faíscas no metal.
    _sparkle(canvas, const Offset(41, 30), 3.6);
    _sparkle(canvas, const Offset(78, 47), 2.4);
  }

  void _engravedStar(Canvas canvas, Offset c, double r) {
    final path = _starPath(c, r, r * 0.52);
    canvas.drawPath(
      path,
      Paint()..color = shade(metal, 0.6).withValues(alpha: 0.55),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = lighten(metal, 0.8).withValues(alpha: 0.5),
    );
  }

  Path _starPath(Offset c, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * rad;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  void _sparkle(Canvas canvas, Offset p, double r) {
    canvas.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_TrophyPainter old) => old.metal != metal;
}
