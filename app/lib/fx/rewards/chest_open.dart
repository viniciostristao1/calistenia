import 'dart:math';

import 'package:flutter/material.dart';

import '../effects/fly_to_target.dart';
import '../effects/rays.dart';
import '../effects/screen_flash.dart';
import '../effects/spin3d.dart';
import '../fx_params.dart';
import '../particles/particle.dart';
import '../particles/particle_burst.dart';
import '../shading.dart';
import 'star_3d.dart';

/// **Recompensa: baú abrindo** — a molécula mais composta, showcase da camada.
///
/// Timeline (fração do tempo): antecipação — o baú treme e **afunda a tampa**
/// (0–0.32) → a tampa abre de verdade, girando na **dobradiça traseira** com
/// perspectiva e espessura (0.32–0.62) → clarão (`ScreenFlash`) + `RadialRays`
/// + `ParticleBurst` → a recompensa salta pra fora girando no próprio eixo
/// (`Spin3D` + `FlyToTarget`, 0.55–1.0).
///
/// A tampa é desenhada por `_ChestPainter` como uma **caixa projetada em 3D**
/// (função de projeção com perspectiva + tombo da câmera): face externa, face
/// interna, cintas e a boca do baú aparecendo conforme o ângulo — nada de
/// retângulo que gira "deitado".
class ChestOpen extends StatefulWidget {
  const ChestOpen({super.key, this.params = const FxParams()});

  final FxParams params;

  @override
  State<ChestOpen> createState() => _ChestOpenState();
}

class _ChestOpenState extends State<ChestOpen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.params.effectiveDuration,
  );

  @override
  void initState() {
    super.initState();
    widget.params.loopForever ? _ctrl.repeat() : _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Parâmetros mais curtos para os átomos que entram no meio do timeline.
  FxParams get _revealParams => FxParams(
    duration: Duration(
      milliseconds: (widget.params.effectiveDuration.inMilliseconds * 0.55)
          .round(),
    ),
    intensity: widget.params.intensity,
    scale: widget.params.scale,
  );

  double get _intensity => widget.params.intensity.clamp(0.0, 2.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final v = _ctrl.value;
          final aberto = v > 0.42;
          final glowA =
              (Interval(0.34, 0.52).transform(v)) *
              (1 - 0.4 * Interval(0.75, 1.0).transform(v)) *
              0.5 *
              _intensity;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Holofote dourado girando atrás do baú aberto.
              if (aberto)
                RadialRays(
                  color: const Color(0xFFF4C542),
                  diameter: 210,
                  params: widget.params,
                ),
              // Partículas saindo para cima (leque), atrás.
              aberto
                  ? ParticleBurst(
                      params: widget.params,
                      colors: const [
                        Color(0xFFF4C542),
                        Colors.white,
                        Color(0xFFFFC93C),
                      ],
                      shapes: const [ParticleShape.spark, ParticleShape.circle],
                      direction: -pi / 2,
                      spread: 1.7,
                      gravity: 420,
                    )
                  : const SizedBox.shrink(),
              // Luz saindo do interior.
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFFF4C542,
                      ).withValues(alpha: glowA.clamp(0.0, 1.0)),
                      const Color(0xFFF4C542).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              // O baú (corpo + tampa 3D projetada).
              _chest(v),
              // A recompensa saltando pra fora girando no próprio eixo.
              v > 0.55
                  ? FlyToTarget(
                      params: _revealParams,
                      begin: const Offset(0, 16),
                      end: Offset(0, -92 * _intensity.clamp(0.4, 2.0)),
                      child: Spin3D(
                        params: _revealParams,
                        turns: 2,
                        fromScale: 0.3,
                        child: const Star3D(size: 52),
                      ),
                    )
                  : const SizedBox.shrink(),
              // Clarão breve ao abrir.
              v > 0.30
                  ? ScreenFlash(params: _revealParams, peak: 0.30)
                  : const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }

  Widget _chest(double v) {
    // Antecipação: tremida que amortece, com torção no próprio eixo.
    final shakeT = Interval(0.0, 0.30).transform(v);
    final dx = sin(shakeT * 4 * 2 * pi) * 6 * (1 - shakeT) * _intensity;
    final yaw = sin(shakeT * 2 * pi) * 0.22 * (1 - shakeT) * _intensity;
    // Tranco no batente: o baú dá um pulinho (sobe, cai, assenta).
    final recT = Interval(0.62, 0.90).transform(v);
    final dy = -3.5 * sin(recT * 2.2 * pi) * (1 - recT) * _intensity;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..translateByDouble(dx, dy, 0.0, 1.0)
        ..rotateY(yaw),
      child: CustomPaint(
        size: const Size.square(200),
        painter: _ChestPainter(v: v, intensity: _intensity),
      ),
    );
  }
}

/// **Baú projetado em 3D.** Modelo simples: eixos `x` (direita), `y` (baixo) e
/// `z` (para o observador). O corpo fica no plano `z = 0`; a tampa é uma caixa
/// (frente + fundo) presa numa dobradiça no topo traseiro (`z = -depth`) e gira
/// em torno do eixo X. A projeção tem **perspectiva** e um **tombo de câmera**
/// (quem olha de cima enxerga a boca do baú).
class _ChestPainter extends CustomPainter {
  _ChestPainter({required this.v, required this.intensity});

  final double v;
  final double intensity;

  static const _corpo1 = Color(0xFF9A5B2A);
  static const _corpo2 = Color(0xFF6E3D1C);
  static const _tampa1 = Color(0xFF8A4E22);
  static const _tampa2 = Color(0xFF4A2912);
  static const _ouro = Color(0xFFF4C542);

  static const _cx = 100.0; // centro horizontal
  static const _cy = 96.0; // linha da dobradiça (topo do corpo)
  static const _bodyHalf = 68.0;
  static const _bodyH = 76.0;
  static const _lidHalf = 73.0;
  static const _lidT = 44.0; // altura da frente da tampa fechada
  static const _depth = 42.0; // profundidade (dobradiça → frente)
  static const _sag = 15.0; // concavidade da parte de dentro da tampa
  static const _persp = 430.0;
  static const _tilt = 0.26; // tombo da câmera (vê um pouco por cima)

  /// Ângulo da tampa (0 = fechada). Antecipa "sentando", destranca e abre com
  /// inércia (rápida no início, freia no fim), bate no batente e volta
  /// amortecendo — dois rebotes.
  double get _theta {
    final dip = -0.12 * sin(Interval(0.12, 0.30).transform(v) * pi);
    final openT = Interval(0.30, 0.64, curve: Curves.easeOutCubic).transform(v);
    var open = 2.0 * openT;
    final st = ((v - 0.64) / 0.30).clamp(0.0, 1.0);
    if (st > 0) {
      open += sin(st * 2.6 * pi) * 0.10 * (1 - st);
    }
    return dip + open;
  }

  /// Projeta um ponto do mundo (x centrado, y a partir da dobradiça, z = +frente).
  Offset _p(double x, double y, double z) {
    final s = _persp / (_persp - z);
    return Offset(_cx + x * s, _cy + (y + _tilt * z) * s);
  }

  /// Ponto da tampa já girado em torno da dobradiça.
  Offset _lidPoint(double x, double y, double z, double th) {
    final zr = z + _depth; // 0 = dobradiça; +depth = frente
    final yR = y * cos(th) - zr * sin(th);
    final zR = y * sin(th) + zr * cos(th);
    return _p(x, yR, zR - _depth);
  }

  /// Ponto da face INTERNA (côncava) da tampa. `w` = -1..1 (largura),
  /// `u` = 0 (dobradiça) → 1 (frente). O meio afunda [_sag]: a parte de dentro
  /// é um **bojo curvo**, não um painel reto.
  Offset _innerPoint(double w, double u, double th) =>
      _lidPoint(_lidHalf * w, -_sag * sin(pi * u), -_depth * (1 - u), th);

  /// Curva da face interna numa largura `w`, da dobradiça à frente.
  Path _innerEdge(double w, double th) {
    final path = Path();
    for (var i = 0; i <= 10; i++) {
      final p = _innerPoint(w, i / 10, th);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  /// A face interna inteira (borda esquerda + frente + direita).
  Path _innerFace(double th) {
    final path = Path();
    for (var i = 0; i <= 10; i++) {
      final p = _innerPoint(-1, i / 10, th);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    for (var i = 10; i >= 0; i--) {
      final p = _innerPoint(1, i / 10, th);
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    final th = _theta;
    _groundShadow(canvas);
    _body(canvas);
    _opening(canvas);
    _lid(canvas, th);
    _hinges(canvas);
    canvas.restore();
  }

  void _groundShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(_cx, _cy + _bodyH - 1),
        width: 178,
        height: 20,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _body(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_cx - _bodyHalf, _cy, _bodyHalf * 2, _bodyH),
      const Radius.circular(9),
    );
    final bounds = rect.outerRect;

    canvas.drawRRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_corpo1, _corpo2],
        ).createShader(bounds),
    );

    // Veios da madeira.
    final grain = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 1.2;
    for (final dy in [14.0, 30.0, 60.0]) {
      canvas.drawLine(
        Offset(_cx - _bodyHalf + 9, _cy + dy),
        Offset(_cx + _bodyHalf - 9, _cy + dy),
        grain,
      );
    }

    // Faixa dourada.
    const bandTop = _cy + 46;
    canvas.drawRect(
      const Rect.fromLTWH(_cx - _bodyHalf, bandTop, _bodyHalf * 2, 10),
      Paint()..color = _ouro,
    );
    canvas.drawRect(
      const Rect.fromLTWH(_cx - _bodyHalf, bandTop + 10, _bodyHalf * 2, 2),
      Paint()..color = shade(_ouro, 0.35),
    );

    // Borda dourada.
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _ouro.withValues(alpha: 0.8),
    );

    // Fechadura.
    final lock = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(_cx, bandTop - 2),
        width: 20,
        height: 24,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(lock, Paint()..color = _ouro);
    canvas.drawRRect(
      lock,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = shade(_ouro, 0.4),
    );
    final dark = Paint()..color = const Color(0xFF3A2408);
    canvas.drawCircle(const Offset(_cx, bandTop - 7), 3, dark);
    canvas.drawRect(
      Rect.fromCenter(
        center: const Offset(_cx, bandTop + 1),
        width: 3.4,
        height: 8,
      ),
      dark,
    );

    // Rebites.
    final rivet = Paint()..color = _ouro.withValues(alpha: 0.9);
    for (final p in [
      const Offset(_cx - _bodyHalf + 10, _cy + 10),
      const Offset(_cx + _bodyHalf - 10, _cy + 10),
      const Offset(_cx - _bodyHalf + 10, _cy + _bodyH - 10),
      const Offset(_cx + _bodyHalf - 10, _cy + _bodyH - 10),
    ]) {
      canvas.drawCircle(p, 2.4, rivet);
    }
  }

  /// Boca do baú (interior escuro) + luz saindo de dentro.
  void _opening(Canvas canvas) {
    final fl = _p(-_bodyHalf, 0, 0);
    final fr = _p(_bodyHalf, 0, 0);
    final rl = _p(-_bodyHalf, 0, -_depth);
    final rr = _p(_bodyHalf, 0, -_depth);
    final path = Path()
      ..moveTo(fl.dx, fl.dy)
      ..lineTo(fr.dx, fr.dy)
      ..lineTo(rr.dx, rr.dy)
      ..lineTo(rl.dx, rl.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF1C0F05));

    final glow =
        (0.45 + 0.55 * Interval(0.30, 0.62).transform(v)) *
        intensity.clamp(0.0, 1.4);
    canvas.save();
    canvas.clipPath(path);
    final center = Offset(_cx, _cy - 4);
    canvas.drawCircle(
      center,
      66,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(
              0xFFFFC93C,
            ).withValues(alpha: (0.55 * glow).clamp(0.0, 1.0)),
            const Color(0xFFFFC93C).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 66)),
    );
    canvas.restore();

    // Filete dourado na aresta da frente.
    canvas.drawLine(
      fl,
      fr,
      Paint()
        ..color = _ouro.withValues(alpha: 0.9)
        ..strokeWidth = 2.4,
    );
  }

  /// A tampa é um **painel rígido** preso na dobradiça traseira: gira para trás
  /// como um todo (movimento natural) e a face de dentro é **côncava** (bojo
  /// com ripas que seguem a curva). A visibilidade de cada face vem da normal
  /// contra a câmera (que olha um pouco de cima, com [_tilt]).
  void _lid(Canvas canvas, double th) {
    final cosT = cos(th);
    final sinT = sin(th);

    // Parte de DENTRO côncava — o bojo que olha para o observador.
    if (sinT - _tilt * cosT > 0.02) {
      final inner = _innerFace(th);
      final bounds = inner.getBounds();
      // Luz quente que sobe da boca do baú e bate no fundo da tampa.
      final warm =
          (Interval(0.34, 0.64).transform(v) *
                  (1 - 0.35 * Interval(0.82, 1.0).transform(v)))
              .clamp(0.0, 1.0);
      canvas.drawPath(
        inner,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(shade(_tampa1, 0.10), const Color(0xFFC8802A), warm)!,
              Color.lerp(_tampa2, const Color(0xFF6B4010), warm)!,
            ],
          ).createShader(bounds),
      );
      // Vinheta: centro do bojo mais escuro que as bordas → concavidade.
      canvas.drawPath(
        inner,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.30),
              Colors.black.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0.30),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
      );
      // Ripas (madeira) acompanhando a curva — de baixo para cima.
      final plank = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = shade(_tampa2, 0.3).withValues(alpha: 0.5);
      for (final w in [-0.6, -0.2, 0.2, 0.6]) {
        canvas.drawPath(_innerEdge(w, th), plank);
      }
      // Aresta de cima (a "boca" da tampa) iluminada.
      final frontEdge = Path();
      for (var i = 0; i <= 10; i++) {
        final p = _innerPoint(-1 + 2 * i / 10, 1, th);
        i == 0 ? frontEdge.moveTo(p.dx, p.dy) : frontEdge.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        frontEdge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = _ouro.withValues(alpha: 0.7),
      );
      // Aresta da dobradiça iluminada.
      final hingeEdge = Path();
      for (var i = 0; i <= 10; i++) {
        final p = _innerPoint(-1 + 2 * i / 10, 0, th);
        i == 0 ? hingeEdge.moveTo(p.dx, p.dy) : hingeEdge.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        hingeEdge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = _ouro.withValues(alpha: 0.45),
      );
    }

    // "Testa" da tampa (face da frente) — some ao passar do vertical; depois o
    // que aparece é a parte de dentro.
    if (cosT + _tilt * sinT > 0.04) {
      final bl = _lidPoint(-_lidHalf, 0, 0, th);
      final br = _lidPoint(_lidHalf, 0, 0, th);
      final tl = _lidPoint(-_lidHalf, -_lidT, 0, th);
      final tr = _lidPoint(_lidHalf, -_lidT, 0, th);
      final plate = Path()
        ..moveTo(bl.dx, bl.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(tl.dx, tl.dy)
        ..close();
      final bounds = plate.getBounds();
      canvas.drawPath(
        plate,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_tampa1, _tampa2],
          ).createShader(bounds),
      );
      canvas.drawPath(
        plate,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = _ouro.withValues(alpha: 0.8),
      );
      // Cinta central atravessando a testa.
      final midL = Offset.lerp(bl, tl, 0.5)!;
      final midR = Offset.lerp(br, tr, 0.5)!;
      canvas.drawLine(
        midL,
        midR,
        Paint()
          ..color = shade(_ouro, 0.2).withValues(alpha: 0.6)
          ..strokeWidth = 3,
      );
    }
  }

  /// Dobradiças no topo traseiro (não giram com a tampa).
  void _hinges(Canvas canvas) {
    final paint = Paint()..color = shade(_ouro, 0.1);
    for (final x in [-_lidHalf + 12, _lidHalf - 12]) {
      final p = _p(x, 0, -_depth + 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 13, height: 9),
          const Radius.circular(2.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ChestPainter old) =>
      old.v != v || old.intensity != intensity;
}
