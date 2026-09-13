import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shading.dart';

/// **Conteúdo: troféu 3D (ouro/prata)** — taça no formato da Liga dos Campeões
/// (a "orelhuda"): copo em sino, **alças grandes**, haste com colar e base em
/// pedestal. O metal é pintado com bandas de reflexo, oclusões (sombra no aro e
/// na base) e brilhos especulares, para parecer metal de verdade.
/// Parametrizado por [metal], serve aos dois troféus.
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

  // ─────────────────────────── metal ───────────────────────────

  /// Faixas de reflexo do cilindro metálico (mais stops = mais real).
  Paint _metal(Rect r, {double escurece = 0, double clareia = 0}) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            shade(metal, 0.58 + escurece),
            lighten(metal, 0.18 + clareia),
            lighten(metal, 0.78 + clareia),
            metal,
            shade(metal, 0.18 + escurece),
            lighten(metal, 0.45 + clareia),
            shade(metal, 0.62 + escurece),
          ],
          stops: const [0.0, 0.09, 0.22, 0.44, 0.64, 0.82, 1.0],
        ).createShader(r);

  void _groundShadow(Canvas canvas) {
    // Sombra difusa + contato.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 112), width: 66, height: 11),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 110), width: 40, height: 6),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  /// As orelhas: alças cheias, com sombra onde entram no copo e fio de luz
  /// na borda de fora.
  void _ears(Canvas canvas) {
    for (final sign in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(60 + sign * 24, 24)
        ..cubicTo(60 + sign * 50, 27, 60 + sign * 48, 64, 60 + sign * 11, 80)
        ..cubicTo(60 + sign * 26, 66, 60 + sign * 32, 40, 60 + sign * 24, 24)
        ..close();
      final b = ear.getBounds();
      canvas.drawPath(ear, _metal(b));
      // Sombra interna (lado de dentro da alça).
      canvas.drawPath(
        ear,
        Paint()
          ..shader = LinearGradient(
            begin: sign < 0 ? Alignment.centerRight : Alignment.centerLeft,
            end: sign < 0 ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.28),
            ],
          ).createShader(b),
      );
      // Fio de luz na borda externa.
      final outer = Path()
        ..moveTo(60 + sign * 24, 24)
        ..cubicTo(60 + sign * 50, 27, 60 + sign * 48, 64, 60 + sign * 11, 80);
      canvas.drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = lighten(metal, 0.85).withValues(alpha: 0.75),
      );
      // Sombra na borda interna (folga da alça).
      final inner = Path()
        ..moveTo(60 + sign * 24, 24)
        ..cubicTo(60 + sign * 32, 40, 60 + sign * 26, 66, 60 + sign * 11, 80);
      canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = shade(metal, 0.6).withValues(alpha: 0.75),
      );
      // Contorno.
      canvas.drawPath(
        ear,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = shade(metal, 0.58).withValues(alpha: 0.9),
      );
    }
  }

  /// O copo em sino, com aro, bandas, oclusões e brilhos.
  void _cup(Canvas canvas) {
    final bowl = Path()
      ..moveTo(34, 22)
      ..cubicTo(35, 41, 41, 59, 50, 72)
      ..cubicTo(53, 77, 54, 81, 54.5, 85)
      ..lineTo(65.5, 85)
      ..cubicTo(66, 81, 67, 77, 70, 72)
      ..cubicTo(79, 59, 85, 41, 86, 22)
      ..close();
    final b = bowl.getBounds();

    canvas.drawPath(bowl, _metal(b));

    canvas.save();
    canvas.clipPath(bowl);
    // Oclusões: sombra rente ao aro e na base.
    canvas.drawRect(
      Rect.fromLTWH(30, 22, 60, 10),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.42),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(30, 22, 60, 10)),
    );
    canvas.drawRect(
      Rect.fromLTWH(30, 72, 60, 16),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.38),
          ],
        ).createShader(Rect.fromLTWH(30, 72, 60, 16)),
    );
    // Barra gravada (faixa com texto sugerido) perto do aro.
    canvas.drawRect(
      Rect.fromLTWH(30, 31, 60, 8),
      Paint()..color = shade(metal, 0.28).withValues(alpha: 0.35),
    );
    canvas.drawLine(
      const Offset(30, 31),
      const Offset(90, 31),
      Paint()
        ..strokeWidth = 1
        ..color = lighten(metal, 0.7).withValues(alpha: 0.5),
    );
    canvas.drawLine(
      const Offset(30, 39),
      const Offset(90, 39),
      Paint()
        ..strokeWidth = 1
        ..color = shade(metal, 0.5).withValues(alpha: 0.5),
    );
    // Brilho vertical (reflexo principal) e segundo menor.
    canvas.save();
    canvas.translate(45, 52);
    canvas.rotate(-0.06);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 6, height: 52),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(76, 50);
    canvas.rotate(0.05);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 3.4, height: 34),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
    canvas.restore();
    // Estrela gravada (relevo).
    _engravedStar(canvas, const Offset(60, 55), 8.5);
    canvas.restore();

    // Contorno escuro fino (define a silhueta).
    canvas.drawPath(
      bowl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = shade(metal, 0.65).withValues(alpha: 0.9),
    );

    // Aro: boca escura, anel metálico, sombra interna e luz de cima.
    final inside = Rect.fromCenter(
      center: const Offset(60, 22),
      width: 47,
      height: 11,
    );
    canvas.drawOval(inside, Paint()..color = shade(metal, 0.82));
    canvas.drawArc(
      inside.deflate(1),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.black.withValues(alpha: 0.45),
    );
    final rim = Rect.fromCenter(
      center: const Offset(60, 22),
      width: 52,
      height: 13.5,
    );
    canvas.drawOval(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..shader = _metal(rim).shader,
    );
    // Luz superior do aro (esquerda) + sombra (direita).
    canvas.drawArc(
      rim.deflate(0.5),
      math.pi * 1.05,
      math.pi * 0.72,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawArc(
      rim.deflate(0.5),
      math.pi * 0.05,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = shade(metal, 0.55).withValues(alpha: 0.7),
    );
  }

  void _stemAndBase(Canvas canvas) {
    // Colar sob o copo (sombra do copo em cima dele).
    final collar = Rect.fromLTWH(49, 84, 22, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar, const Radius.circular(3)),
      _metal(collar),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(collar),
    );

    // Haste com reflexo.
    final stem = Rect.fromLTWH(56, 89, 8, 13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stem, const Radius.circular(2.5)),
      _metal(stem),
    );
    canvas.drawRect(
      Rect.fromLTWH(58, 90, 1.6, 11),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      const Offset(57, 89),
      const Offset(57, 102),
      Paint()
        ..strokeWidth = 1
        ..color = shade(metal, 0.5).withValues(alpha: 0.6),
    );

    // Base em pedestal.
    final base = Rect.fromLTWH(37, 101, 46, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, const Radius.circular(4)),
      _metal(base),
    );
    // Topo elíptico (luz) e anel escuro (entalhe).
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 101), width: 46, height: 8),
      _metal(base, clareia: 0.1),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 101), width: 34, height: 5),
      Paint()..color = shade(metal, 0.45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(39, 105, 42, 2.6),
        const Radius.circular(1.5),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    // Sombra na parte de baixo do pedestal.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(39, 108, 42, 3),
        const Radius.circular(2),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTWH(39, 108, 42, 3)),
    );
    // Reflexo na base.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(43, 102.5, 5, 5),
        const Radius.circular(2),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = shade(metal, 0.6).withValues(alpha: 0.8),
    );
  }

  void _engravedStar(Canvas canvas, Offset c, double r) {
    final path = _starPath(c, r, r * 0.52);
    canvas.drawPath(
      path,
      Paint()..color = shade(metal, 0.62).withValues(alpha: 0.55),
    );
    canvas.drawPath(
      path.shift(const Offset(0, 1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = lighten(metal, 0.85).withValues(alpha: 0.45),
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
