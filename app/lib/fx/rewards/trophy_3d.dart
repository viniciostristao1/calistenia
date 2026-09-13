import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shading.dart';

/// **Conteúdo: troféu 3D (ouro/prata)** — agora no formato da taça da Liga dos
/// Campeões, a "orelhuda": copo alto em sino, **alças grandes** (as orelhas),
/// haste com colar e base em pedestal. Parametrizado por [metal], serve aos
/// dois troféus (`trophyGold`/`trophySilver`). Não anima: o giro no próprio
/// eixo fica com o átomo `Spin3D`.
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
    _ears(canvas);
    _cup(canvas);
    _stemAndBase(canvas);
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

  /// As "orelhas": alças grandes que saem da borda e reencontram o copo
  /// embaixo — a marca registrada do troféu.
  void _ears(Canvas canvas) {
    for (final sign in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(60 + sign * 22, 26)
        ..cubicTo(60 + sign * 43, 21, 60 + sign * 45, 57, 60 + sign * 12, 75);
      final bounds = path.getBounds();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..color = shade(metal, 0.55),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..shader = _metalFill(bounds).shader,
      );
      canvas.save();
      canvas.translate(sign * -1.4, -1.6);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = lighten(metal, 0.85).withValues(alpha: 0.8),
      );
      canvas.restore();
    }
  }

  /// Copo em sino (alto e afunilado), com aro, painéis e estrela gravada.
  void _cup(Canvas canvas) {
    final bowl = Path()
      ..moveTo(37, 24)
      ..cubicTo(38.5, 42, 44, 62, 53, 76)
      ..cubicTo(55.5, 80, 56.5, 83, 56, 86)
      ..lineTo(64, 86)
      ..cubicTo(63.5, 83, 64.5, 80, 67, 76)
      ..cubicTo(76, 62, 81.5, 42, 83, 24)
      ..close();
    final bounds = bowl.getBounds();
    canvas.drawPath(bowl, _metalFill(bounds));

    canvas.save();
    canvas.clipPath(bowl);
    // Sombra à direita (volume do cilindro).
    canvas.drawRect(
      Rect.fromLTWH(76, 18, 14, 72),
      Paint()..color = shade(metal, 0.38).withValues(alpha: 0.5),
    );
    // Reflexo à esquerda.
    canvas.drawRect(
      Rect.fromLTWH(42, 18, 5, 72),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );
    // Costuras verticais (os gomos da taça).
    final seam = Paint()
      ..color = shade(metal, 0.4).withValues(alpha: 0.30)
      ..strokeWidth = 1.2;
    for (final x in [52.0, 60.0, 68.0]) {
      canvas.drawLine(Offset(x, 20), Offset(x, 90), seam);
    }
    // Glint difuso.
    canvas.save();
    canvas.translate(48, 42);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12, height: 5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.restore();
    // Estrela gravada.
    _engravedStar(canvas, const Offset(60, 52), 9);
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
      center: const Offset(60, 23),
      width: 46,
      height: 11,
    );
    canvas.drawOval(inside, Paint()..color = shade(metal, 0.78));
    final rim = Rect.fromCenter(
      center: const Offset(60, 22.5),
      width: 50,
      height: 13,
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

  void _stemAndBase(Canvas canvas) {
    // Haste.
    final stem = Rect.fromLTWH(55.5, 84, 9, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stem, const Radius.circular(3)),
      _metalFill(stem),
    );
    canvas.drawRect(
      Rect.fromLTWH(57.5, 86, 1.8, 12),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
    // Colar.
    final collar = Rect.fromLTWH(50, 82, 20, 7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar, const Radius.circular(2.5)),
      _metalFill(collar),
    );

    // Base em pedestal (cilindro baixo).
    final base = Rect.fromLTWH(38, 100, 44, 11);
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, const Radius.circular(4)),
      _metalFill(base),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 100.5), width: 44, height: 9),
      _metalFill(base),
    );
    // Entalhe escuro + sombra na base.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, 103.5, 40, 3.5),
        const Radius.circular(2),
      ),
      Paint()..color = shade(metal, 0.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, 107, 40, 4),
        const Radius.circular(2),
      ),
      Paint()..color = shade(metal, 0.3).withValues(alpha: 0.4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = metal.withValues(alpha: 0.4),
    );
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

  @override
  bool shouldRepaint(_TrophyPainter old) => old.metal != metal;
}
