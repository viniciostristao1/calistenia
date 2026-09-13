import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shading.dart';

/// **Conteúdo: troféu 3D (ouro/prata)** — taça no formato da Liga dos Campeões,
/// a "orelhuda": copo em **trombeta** (borda bem aberta, cintura estreita),
/// **nó** na base do copo, haste curta, base cilíndrica com a faixa dos nomes e
/// as **orelhas grandes** presas no aro e no nó. O metal é pintado com bandas de
/// reflexo, oclusões e brilhos. Parametrizado por [metal] (ouro/prata).
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

  /// Faixas de reflexo do cilindro metálico.
  Paint _metal(Rect r, {double escurece = 0, double clareia = 0}) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            shade(metal, 0.58 + escurece),
            lighten(metal, 0.18 + clareia),
            lighten(metal, 0.80 + clareia),
            metal,
            shade(metal, 0.20 + escurece),
            lighten(metal, 0.42 + clareia),
            shade(metal, 0.62 + escurece),
          ],
          stops: const [0.0, 0.08, 0.20, 0.44, 0.66, 0.84, 1.0],
        ).createShader(r);

  void _groundShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 110), width: 70, height: 11),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 108), width: 44, height: 6),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  /// As orelhas: placas grandes presas no aro e no nó do copo.
  void _ears(Canvas canvas) {
    for (final sign in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(60 + sign * 26, 22)
        ..cubicTo(60 + sign * 53, 25, 60 + sign * 53, 62, 60 + sign * 10, 73)
        ..cubicTo(60 + sign * 27, 58, 60 + sign * 31, 36, 60 + sign * 26, 22)
        ..close();
      final b = ear.getBounds();
      canvas.drawPath(ear, _metal(b));
      // Volume: sombra do lado de dentro + luz na borda de fora.
      canvas.drawPath(
        ear,
        Paint()
          ..shader = LinearGradient(
            begin: sign < 0 ? Alignment.centerRight : Alignment.centerLeft,
            end: sign < 0 ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.30),
            ],
          ).createShader(b),
      );
      final outer = Path()
        ..moveTo(60 + sign * 26, 22)
        ..cubicTo(60 + sign * 53, 25, 60 + sign * 53, 62, 60 + sign * 10, 73);
      final inner = Path()
        ..moveTo(60 + sign * 26, 22)
        ..cubicTo(60 + sign * 31, 36, 60 + sign * 27, 58, 60 + sign * 10, 73);
      canvas.drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..color = lighten(metal, 0.85).withValues(alpha: 0.8),
      );
      canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = shade(metal, 0.62).withValues(alpha: 0.8),
      );
      canvas.drawPath(
        ear,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = shade(metal, 0.6).withValues(alpha: 0.9),
      );
    }
  }

  /// O copo em trombeta: aro bem aberto, cintura estreita e o nó embaixo.
  void _cup(Canvas canvas) {
    final bowl = Path()
      ..moveTo(33, 21)
      ..cubicTo(35, 33, 43, 48, 51, 60)
      ..cubicTo(54, 64, 55, 68, 54, 71)
      ..lineTo(66, 71)
      ..cubicTo(65, 68, 66, 64, 69, 60)
      ..cubicTo(77, 48, 85, 33, 87, 21)
      ..close();
    final b = bowl.getBounds();
    canvas.drawPath(bowl, _metal(b));

    canvas.save();
    canvas.clipPath(bowl);
    // Oclusão rente ao aro.
    canvas.drawRect(
      Rect.fromLTWH(30, 21, 60, 9),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(30, 21, 60, 9)),
    );
    // Sombra na cintura.
    canvas.drawRect(
      Rect.fromLTWH(40, 56, 40, 16),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTWH(40, 56, 40, 16)),
    );
    // Faixa gravada (letras sugeridas) perto do aro.
    final letra = Paint()
      ..color = shade(metal, 0.45).withValues(alpha: 0.3)
      ..strokeWidth = 1.1;
    for (var x = 39.0; x < 82; x += 3.6) {
      canvas.drawLine(Offset(x, 30.5), Offset(x, 36.5), letra);
    }
    canvas.drawLine(
      const Offset(30, 30),
      const Offset(90, 30),
      Paint()
        ..strokeWidth = 1
        ..color = lighten(metal, 0.7).withValues(alpha: 0.5),
    );
    canvas.drawLine(
      const Offset(30, 37),
      const Offset(90, 37),
      Paint()
        ..strokeWidth = 1
        ..color = shade(metal, 0.5).withValues(alpha: 0.55),
    );
    // Reflexos verticais.
    canvas.save();
    canvas.translate(43, 48);
    canvas.rotate(-0.05);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 5.5, height: 42),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(76, 46);
    canvas.rotate(0.05);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 3, height: 28),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );
    canvas.restore();
    canvas.restore();

    // Contorno da silhueta.
    canvas.drawPath(
      bowl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = shade(metal, 0.65).withValues(alpha: 0.9),
    );

    // Nó (disco) entre o copo e a haste.
    final knop = Rect.fromCenter(
      center: const Offset(60, 72),
      width: 25,
      height: 8,
    );
    canvas.drawOval(knop, _metal(knop));
    canvas.drawOval(
      knop.deflate(2.6),
      Paint()..color = shade(metal, 0.4).withValues(alpha: 0.45),
    );
    canvas.drawOval(
      knop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = shade(metal, 0.6).withValues(alpha: 0.85),
    );

    // Aro: boca escura + anel metálico + luz/sombra.
    final inside = Rect.fromCenter(
      center: const Offset(60, 21),
      width: 49,
      height: 10.5,
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
      center: const Offset(60, 21),
      width: 54,
      height: 13,
    );
    canvas.drawOval(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..shader = _metal(rim).shader,
    );
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
    // Haste.
    final stem = Rect.fromLTWH(56, 75, 8, 13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stem, const Radius.circular(2.5)),
      _metal(stem),
    );
    canvas.drawRect(
      Rect.fromLTWH(58, 76, 1.6, 11),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    // Sombra do nó sobre a haste.
    canvas.drawRect(
      Rect.fromLTWH(55, 75, 10, 3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(55, 75, 10, 3)),
    );

    // Colar.
    final collar = Rect.fromLTWH(50, 87, 20, 6);
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
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(collar),
    );

    // Base cilíndrica (com a faixa dos nomes).
    final base = Rect.fromLTWH(38, 92, 44, 13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, const Radius.circular(4)),
      _metal(base),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 92), width: 44, height: 9),
      _metal(base, clareia: 0.1),
    );
    // Faixa escura central + nomes gravados (tracinhos claros).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(39.5, 97, 41, 5.5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF241A10),
    );
    final nome = Paint()
      ..color = const Color(0xFFB9A87A).withValues(alpha: 0.45)
      ..strokeWidth = 0.8;
    for (var x = 43.0; x < 78; x += 2.6) {
      canvas.drawLine(Offset(x, 98.2), Offset(x, 101.2), nome);
    }
    // Sombra inferior.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(39, 104.5, 42, 2.5),
        const Radius.circular(1.5),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTWH(39, 104.5, 42, 2.5)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = shade(metal, 0.6).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_TrophyPainter old) => old.metal != metal;
}
