import 'package:flutter/material.dart';

import '../shading.dart';

/// **Conteúdo: troféu 3D (ouro/prata)** — taça da Liga dos Campeões ("a
/// orelhuda") copiada da referência do usuário: corpo em urna **cheio** (ombro
/// largo afinando até a cintura), gargalo com aro e anel, pé em trombeta com
/// aro na base e **alças em gancho grande** que sobem acima do aro, abrem,
/// descem abraçando o corpo e fecham na cintura. Metal com bandas de reflexo,
/// oclusões e brilhos. Parametrizado por [metal] (ouro/prata).
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

  /// Faixas de reflexo (mais stops = mais real).
  Paint _metal(Rect r, {double escurece = 0, double clareia = 0}) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            shade(metal, 0.55 + escurece),
            lighten(metal, 0.10 + clareia),
            lighten(metal, 0.58 + clareia),
            metal,
            shade(metal, 0.14 + escurece),
            lighten(metal, 0.36 + clareia),
            shade(metal, 0.58 + escurece),
          ],
          stops: const [0.0, 0.06, 0.16, 0.40, 0.60, 0.82, 1.0],
        ).createShader(r);

  double _cub(double p0, double p1, double p2, double p3, double t) {
    final u = 1 - t;
    return u * u * u * p0 +
        3 * u * u * t * p1 +
        3 * u * t * t * p2 +
        t * t * t * p3;
  }

  void _groundShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 110), width: 74, height: 10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 107.5), width: 52, height: 5.5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  /// Alças em gancho grande (como na referência): sobem acima do aro, abrem
  /// num laço, retornam e descem abraçando o corpo até a cintura.
  void _handles(Canvas canvas) {
    for (final sign in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(60 + sign * 9, 20)
        ..cubicTo(60 + sign * 14, 8, 60 + sign * 30, 9, 60 + sign * 29, 22)
        ..cubicTo(60 + sign * 28.5, 30, 60 + sign * 20, 31, 60 + sign * 16, 35);
      // Desce abraçando a borda do corpo com uma folga pequena.
      for (var i = 0; i <= 12; i++) {
        final double x;
        final double y;
        if (i <= 3) {
          final t = 0.25 + 0.75 * (i / 3);
          x = _cub(68, 76, 80, 80, t);
          y = _cub(30, 33, 37, 44, t);
        } else {
          final t = (i - 3) / 9.0;
          x = _cub(80, 80, 72, 65, t);
          y = _cub(44, 60, 76, 88, t);
        }
        path.lineTo(60 + sign * (x - 60 + 4.5), y);
      }
      final b = path.getBounds();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.6
          ..strokeCap = StrokeCap.round
          ..color = shade(metal, 0.55),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.3
          ..strokeCap = StrokeCap.round
          ..shader = _metal(b).shader,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round
          ..color = lighten(metal, 0.85).withValues(alpha: 0.75),
      );
    }
  }

  /// Gargalo: cilindro com aro na boca e anel na base.
  void _neck(Canvas canvas) {
    final neck = Rect.fromLTWH(51, 16, 18, 13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, const Radius.circular(1.8)),
      _metal(neck),
    );
    canvas.drawRect(
      Rect.fromLTWH(51, 16, 18, 13),
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
    final ring = Rect.fromLTWH(49, 27, 22, 5);
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
      width: 21,
      height: 5.5,
    );
    canvas.drawOval(rim, _metal(rim, clareia: 0.12));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 16.4), width: 15, height: 3.4),
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
        ..strokeWidth = 1.3
        ..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  /// Corpo em urna cheio: ombro largo, afina em curva até a cintura.
  void _body(Canvas canvas) {
    final body = Path()
      ..moveTo(52, 30)
      ..cubicTo(44, 33, 40, 37, 40, 44)
      ..cubicTo(40, 60, 48, 76, 55, 88)
      ..lineTo(65, 88)
      ..cubicTo(72, 76, 80, 60, 80, 44)
      ..cubicTo(80, 37, 76, 33, 68, 30)
      ..close();
    final b = body.getBounds();
    canvas.drawPath(body, _metal(b));

    canvas.save();
    canvas.clipPath(body);
    // Sombra do gargalo no ombro.
    canvas.drawRect(
      Rect.fromLTWH(38, 30, 44, 8),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.36),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(38, 30, 44, 8)),
    );
    // Sombra na cintura.
    canvas.drawRect(
      Rect.fromLTWH(44, 76, 32, 12),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.34),
          ],
        ).createShader(Rect.fromLTWH(44, 76, 32, 12)),
    );
    // Reflexo amplo (esquerda-centro) + segundo menor.
    canvas.save();
    canvas.translate(47, 58);
    canvas.rotate(-0.04);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 8.5, height: 46),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(74, 56);
    canvas.rotate(0.05);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 3.4, height: 30),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
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
      ..moveTo(55, 88)
      ..cubicTo(53.5, 92, 45, 94, 41, 98)
      ..cubicTo(38.5, 100.5, 39, 103, 42, 104)
      ..lineTo(78, 104)
      ..cubicTo(81, 103, 81.5, 100.5, 79, 98)
      ..cubicTo(75, 94, 66.5, 92, 65, 88)
      ..close();
    final b = foot.getBounds();
    canvas.drawPath(foot, _metal(b));

    canvas.save();
    canvas.clipPath(foot);
    canvas.drawRect(
      Rect.fromLTWH(44, 88, 32, 5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(44, 88, 32, 5)),
    );
    canvas.save();
    canvas.translate(52, 97);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 14, height: 4.6),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
    canvas.restore();
    canvas.restore();

    // Aro da base (torus).
    final baseRing = Rect.fromLTWH(38.5, 100.5, 43, 6.5);
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
