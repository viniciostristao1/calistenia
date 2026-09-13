import 'package:flutter/material.dart';

import '../shading.dart';

/// **Conteúdo: troféu 3D (ouro/prata)** — taça no formato da Liga dos Campeões
/// ("a orelhuda"), seguindo a referência do usuário: corpo **esguio** em urna
/// (ombro que abre e afina num cone suave até a cintura), **gargalo** com aro,
/// **pé em trombeta** com aro na base e **alças finas em gancho** que sobem
/// acima do aro, abrem, descem abraçando o corpo e fecham na cintura.
/// Parametrizado por [metal] (ouro/prata).
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
    _neck(canvas);
    _body(canvas);
    _foot(canvas);
    canvas.restore();
  }

  // ─────────────────────────── metal ───────────────────────────

  /// Faixas de reflexo do cilindro metálico.
  Paint _metal(Rect r, {double escurece = 0, double clareia = 0}) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            shade(metal, 0.55 + escurece),
            lighten(metal, 0.12 + clareia),
            lighten(metal, 0.62 + clareia),
            metal,
            shade(metal, 0.16 + escurece),
            lighten(metal, 0.38 + clareia),
            shade(metal, 0.58 + escurece),
          ],
          stops: const [0.0, 0.07, 0.18, 0.42, 0.62, 0.83, 1.0],
        ).createShader(r);

  void _groundShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 110), width: 66, height: 10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 107.5), width: 44, height: 5.5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  /// Alças finas em gancho: sobem acima do aro, abrem, descem abraçando o
  /// corpo e fecham na cintura.
  void _handles(Canvas canvas) {
    for (final sign in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(60 + sign * 8, 20)
        ..cubicTo(60 + sign * 15, 10, 60 + sign * 26, 12, 60 + sign * 24, 23)
        ..cubicTo(60 + sign * 23, 30, 60 + sign * 15, 30, 60 + sign * 11, 37)
        ..cubicTo(60 + sign * 20, 40, 60 + sign * 30, 70, 60 + sign * 6, 86);
      final b = path.getBounds();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round
          ..color = shade(metal, 0.55),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..shader = _metal(b).shader,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = lighten(metal, 0.85).withValues(alpha: 0.75),
      );
    }
  }

  /// Gargalo: cilindro com o aro da boca e o anel da base.
  void _neck(Canvas canvas) {
    final neck = Rect.fromLTWH(52, 16, 16, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, const Radius.circular(1.8)),
      _metal(neck),
    );
    canvas.drawRect(
      Rect.fromLTWH(52, 16, 16, 12),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: 0.24),
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.24),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(neck),
    );
    final ring = Rect.fromLTWH(50, 25.5, 20, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ring, const Radius.circular(1.8)),
      _metal(ring, clareia: 0.05),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ring, const Radius.circular(1.8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = shade(metal, 0.6).withValues(alpha: 0.8),
    );

    final rim = Rect.fromCenter(
      center: const Offset(60, 16),
      width: 19,
      height: 5,
    );
    canvas.drawOval(rim, _metal(rim, clareia: 0.12));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 16.4), width: 13, height: 3),
      Paint()..color = shade(metal, 0.72),
    );
    canvas.drawOval(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = shade(metal, 0.55).withValues(alpha: 0.9),
    );
    canvas.drawArc(
      rim.deflate(0.5),
      -2.6,
      1.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  /// Corpo esguio: ombro que abre no máximo e afina até a cintura.
  void _body(Canvas canvas) {
    final body = Path()
      ..moveTo(51, 30)
      ..cubicTo(46, 34, 43, 38, 43, 48)
      ..cubicTo(43, 62, 50, 78, 55.5, 88)
      ..lineTo(64.5, 88)
      ..cubicTo(70, 78, 77, 62, 77, 48)
      ..cubicTo(77, 38, 74, 34, 69, 30)
      ..close();
    final b = body.getBounds();
    canvas.drawPath(body, _metal(b));

    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      Rect.fromLTWH(40, 30, 40, 7),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.34),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(40, 30, 40, 7)),
    );
    canvas.drawRect(
      Rect.fromLTWH(46, 78, 28, 10),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.34),
          ],
        ).createShader(Rect.fromLTWH(46, 78, 28, 10)),
    );
    canvas.save();
    canvas.translate(50, 58);
    canvas.rotate(-0.04);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 7, height: 42),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(70, 56);
    canvas.rotate(0.05);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 3, height: 26),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
    canvas.restore();
    canvas.restore();

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = shade(metal, 0.65).withValues(alpha: 0.9),
    );
  }

  /// Pé em trombeta (côncavo), com aro na base.
  void _foot(Canvas canvas) {
    final foot = Path()
      ..moveTo(55.5, 88)
      ..cubicTo(54, 92, 47, 95, 43, 99)
      ..cubicTo(41, 101, 41.5, 103, 44, 104)
      ..lineTo(76, 104)
      ..cubicTo(78.5, 103, 79, 101, 77, 99)
      ..cubicTo(73, 95, 66, 92, 64.5, 88)
      ..close();
    final b = foot.getBounds();
    canvas.drawPath(foot, _metal(b));

    canvas.save();
    canvas.clipPath(foot);
    canvas.drawRect(
      Rect.fromLTWH(46, 88, 28, 5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(46, 88, 28, 5)),
    );
    canvas.save();
    canvas.translate(53, 97);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 13, height: 4.4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
    canvas.restore();
    canvas.restore();

    // Aro da base (torus).
    final baseRing = Rect.fromLTWH(41, 100.5, 38, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRing, const Radius.circular(2.6)),
      _metal(baseRing, clareia: 0.08),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRing, const Radius.circular(2.6)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = shade(metal, 0.6).withValues(alpha: 0.85),
    );

    canvas.drawPath(
      foot,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = shade(metal, 0.65).withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_TrophyPainter old) => old.metal != metal;
}
