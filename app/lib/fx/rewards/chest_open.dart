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

/// **Recompensa: baú abrindo** — showcase da camada, agora em **vista 3/4**
/// (frente + lateral direita, o "90 graus").
///
/// Timeline: antecipação (0–0.30) — treme e dá uma torção no próprio eixo →
/// a tampa abre de verdade na dobradiça traseira, mostrando a parte de dentro
/// côncava (0.30–0.64) → clarão + holofote + partículas → a recompensa salta
/// girando (0.55–1.0), com um "tranco" no fim.
///
/// O desenho é um mini-renderizador 3D em `CustomPainter`: projeção
/// axonométrica (yaw + pitch), faces com culling por normal, luz direcional e
/// ordenação por profundidade. A tampa gira em torno do eixo X (dobradiça
/// traseira).
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
      width: 260,
      height: 260,
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
                  diameter: 220,
                  params: widget.params,
                ),
              // Partículas saindo para cima (leque), atrás.
              if (aberto)
                ParticleBurst(
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
                ),
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
              // O baú em 3/4.
              _chest(v),
              // A recompensa saltando pra fora girando no próprio eixo.
              if (v > 0.55)
                FlyToTarget(
                  params: _revealParams,
                  begin: const Offset(0, 16),
                  end: Offset(0, -92 * _intensity.clamp(0.4, 2.0)),
                  child: Spin3D(
                    params: _revealParams,
                    turns: 2,
                    fromScale: 0.3,
                    child: const Star3D(size: 52),
                  ),
                ),
              // Clarão breve ao abrir.
              if (v > 0.30) ScreenFlash(params: _revealParams, peak: 0.30),
            ],
          );
        },
      ),
    );
  }

  Widget _chest(double v) {
    // Antecipação: tremida que amortece.
    final shakeT = Interval(0.0, 0.30).transform(v);
    final dx = sin(shakeT * 4 * 2 * pi) * 5 * (1 - shakeT) * _intensity;
    // Tranco no batente: o baú dá um pulinho (sobe, cai, assenta).
    final recT = Interval(0.62, 0.90).transform(v);
    final dy = -3.5 * sin(recT * 2.2 * pi) * (1 - recT) * _intensity;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: CustomPaint(
        size: const Size.square(200),
        painter: _ChestPainter(v: v, intensity: _intensity),
      ),
    );
  }
}

// ───────────────────────────── mini-3D ─────────────────────────────

/// Ponto 3D: `x` direita, `y` para cima, `z` para a frente.
class _V {
  const _V(this.x, this.y, this.z);
  final double x, y, z;

  _V operator -(_V o) => _V(x - o.x, y - o.y, z - o.z);
  _V cross(_V o) => _V(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double dot(_V o) => x * o.x + y * o.y + z * o.z;
  _V scaled(double k) => _V(x * k, y * k, z * k);
}

_V _norm(_V p) {
  final l = sqrt(p.dot(p));
  return l == 0 ? p : p.scaled(1 / l);
}

_V _centroid(List<_V> pts) {
  var x = 0.0, y = 0.0, z = 0.0;
  for (final p in pts) {
    x += p.x;
    y += p.y;
    z += p.z;
  }
  final n = pts.length.toDouble();
  return _V(x / n, y / n, z / n);
}

Path _quad(Offset a, Offset b, Offset c, Offset d) => Path()
  ..moveTo(a.dx, a.dy)
  ..lineTo(b.dx, b.dy)
  ..lineTo(c.dx, c.dy)
  ..lineTo(d.dx, d.dy)
  ..close();

/// **Baú em vista 3/4** — renderizador axonométrico com culling, luz
/// direcional e ordenação por profundidade.
class _ChestPainter extends CustomPainter {
  _ChestPainter({required this.v, required this.intensity});

  final double v;
  final double intensity;

  static const _corpo1 = Color(0xFF9A5B2A);
  static const _corpo2 = Color(0xFF6E3D1C);
  static const _tampa1 = Color(0xFF8A4E22);
  static const _tampa2 = Color(0xFF4A2912);
  static const _ouro = Color(0xFFF4C542);
  static const _interior = Color(0xFF160C05);

  // Modelo (y p/ cima, z p/ frente).
  static const _bodyW = 136.0;
  static const _bodyH = 76.0;
  static const _depth = 48.0;
  static const _lidH = 34.0;
  static const _wall = 4.0;
  static const _floorY = _bodyH - 46.0;
  static const _hx = _bodyW / 2;
  static const _hd = _depth / 2;
  static const _hxi = _hx - _wall;
  static const _hzi = _hd - _wall;
  static const _hl = _hx + 3; // tampa um pouco maior

  // Câmera axonométrica (vista 3/4: frente + lateral direita).
  static const _yaw = 0.66; // ~38° (diagonal)
  static const _pitch = 0.22; // ~13° (vê um pouco por cima)
  static const _scale = 1.0;
  static const _cx = 100.0;
  static const _cy = 184.0;

  static final _luz = _norm(const _V(-0.38, 0.72, 0.58));

  /// Ângulo da tampa (0 = fechada). Antecipa "sentando", destranca e abre com
  /// inércia (rápida no início, freia no fim), bate no batente e volta
  /// amortecendo.
  double get _theta {
    final dip = -0.12 * sin(Interval(0.12, 0.30).transform(v) * pi);
    final openT = Interval(0.30, 0.64, curve: Curves.easeOutCubic).transform(v);
    var open = 1.85 * openT;
    final st = ((v - 0.64) / 0.30).clamp(0.0, 1.0);
    if (st > 0) open += sin(st * 2.6 * pi) * 0.10 * (1 - st);
    return dip + open;
  }

  /// Torção de antecipação no próprio eixo (some antes de abrir).
  double get _twist {
    final shakeT = Interval(0.0, 0.30).transform(v);
    return sin(shakeT * 2 * pi) * 0.16 * (1 - shakeT) * intensity;
  }

  Offset _proj(_V p, double yaw) {
    final x1 = p.x * cos(yaw) - p.z * sin(yaw);
    final z1 = p.x * sin(yaw) + p.z * cos(yaw);
    final y1 = p.y * cos(_pitch) - z1 * sin(_pitch);
    return Offset(_cx + x1 * _scale, _cy - y1 * _scale);
  }

  /// Gira um ponto da tampa em torno da dobradiça traseira (y = [_bodyH],
  /// z = −[_hd]).
  _V _lidV(double x, double y, double z, double th) {
    final yl = y - _bodyH;
    final zl = z + _hd;
    return _V(
      x,
      _bodyH + yl * cos(th) + zl * sin(th),
      -_hd - yl * sin(th) + zl * cos(th),
    );
  }

  /// Gira a normal local da tampa junto com a tampa.
  _V _lidN(_V n, double th) =>
      _V(n.x, n.y * cos(th) + n.z * sin(th), -n.y * sin(th) + n.z * cos(th));

  /// Ordena os vértices para a normal apontar para [outward].
  List<_V> _outward(List<_V> pts, _V wanted) {
    final n = _norm((pts[1] - pts[0]).cross(pts[2] - pts[0]));
    return n.dot(wanted) < 0 ? pts.reversed.toList() : pts;
  }

  Color _lit(Color base, _V n) {
    final d = n.dot(_luz).clamp(-1.0, 1.0);
    return Color.lerp(Colors.black, base, 0.72 + 0.28 * d)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);

    final yaw = _yaw + _twist;
    final th = _theta;
    final cam = _norm(
      _V(sin(yaw) * cos(_pitch), sin(_pitch), cos(yaw) * cos(_pitch)),
    );
    final cmds = <(double, void Function(Canvas))>[];

    void push(double depth, void Function(Canvas) draw) =>
        cmds.add((depth, draw));

    /// Face com culling por normal, luz e ordenação por profundidade.
    void face(
      List<_V> pts,
      Color color, {
      Color? stroke,
      double sw = 1.6,
      double bias = 0,
      Shader Function(Rect)? shader,
      void Function(Canvas canvas, Path path, List<Offset> proj)? detail,
    }) {
      final n = _norm((pts[1] - pts[0]).cross(pts[2] - pts[0]));
      if (n.dot(cam) <= 0.001) return;
      final proj = [for (final p in pts) _proj(p, yaw)];
      push(_centroid(pts).dot(cam) + bias, (c) {
        final path = Path()..moveTo(proj[0].dx, proj[0].dy);
        for (var i = 1; i < proj.length; i++) {
          path.lineTo(proj[i].dx, proj[i].dy);
        }
        path.close();
        final paint = Paint();
        if (shader != null) {
          paint.shader = shader(path.getBounds());
        } else {
          paint.color = _lit(color, n);
        }
        c.drawPath(path, paint);
        if (stroke != null) {
          c.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = sw
              ..color = stroke,
          );
        }
        detail?.call(c, path, proj);
      });
    }

    // Pontos de enfeite nos planos da frente / lateral / tampa.
    Offset fp(double x, double y) => _proj(_V(x, y, _hd), yaw);
    Offset sp(double y, double z) => _proj(_V(_hx, y, z), yaw);
    Offset lp(double x, double y, double z) => _proj(_lidV(x, y, z, th), yaw);

    // ── Interior (boca escura + luz saindo do fundo) ──
    final glow =
        (0.45 + 0.55 * Interval(0.30, 0.62).transform(v)) *
        intensity.clamp(0.0, 1.4);
    face(
      _outward([
        const _V(-_hxi, _floorY, _hzi),
        const _V(_hxi, _floorY, _hzi),
        const _V(_hxi, _floorY, -_hzi),
        const _V(-_hxi, _floorY, -_hzi),
      ], const _V(0, 1, 0)),
      _interior,
      shader: (r) => RadialGradient(
        colors: [
          const Color(0xFFFFC93C).withValues(alpha: (glow * 0.55).clamp(0, 1)),
          _interior,
        ],
      ).createShader(r),
    );
    face(
      _outward([
        const _V(-_hxi, _floorY, _hzi),
        const _V(_hxi, _floorY, _hzi),
        const _V(_hxi, _bodyH, _hzi),
        const _V(-_hxi, _bodyH, _hzi),
      ], const _V(0, 0, -1)),
      _interior,
    );
    face(
      _outward([
        const _V(_hxi, _floorY, -_hzi),
        const _V(_hxi, _floorY, _hzi),
        const _V(_hxi, _bodyH, _hzi),
        const _V(_hxi, _bodyH, -_hzi),
      ], const _V(-1, 0, 0)),
      lighten(_interior, 0.10),
    );

    // ── Corpo: frente ──
    face(
      _outward([
        const _V(-_hx, 0, _hd),
        const _V(_hx, 0, _hd),
        const _V(_hx, _bodyH, _hd),
        const _V(-_hx, _bodyH, _hd),
      ], const _V(0, 0, 1)),
      _corpo1,
      stroke: _ouro.withValues(alpha: 0.85),
      sw: 2.6,
      shader: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lighten(_corpo1, 0.10), shade(_corpo2, 0.10)],
      ).createShader(r),
      detail: (c, path, proj) {
        // Veios da madeira.
        final grain = Paint()
          ..color = Colors.black.withValues(alpha: 0.10)
          ..strokeWidth = 1.1;
        for (final y in [14.0, 30.0, 66.0]) {
          c.drawLine(fp(-_hx + 10, y), fp(_hx - 10, y), grain);
        }
        // Faixa dourada.
        c.drawPath(
          _quad(fp(-_hx, 40), fp(_hx, 40), fp(_hx, 50), fp(-_hx, 50)),
          Paint()..color = _ouro,
        );
        // Fechadura.
        c.drawPath(
          _quad(fp(-9, 50), fp(9, 50), fp(9, 70), fp(-9, 70)),
          Paint()..color = _ouro,
        );
        final keyhole = Paint()..color = const Color(0xFF3A2408);
        c.drawCircle(fp(0, 58), 2.6, keyhole);
        c.drawRect(
          Rect.fromCenter(center: fp(0, 64), width: 3.2, height: 7),
          keyhole,
        );
        // Rebites.
        final rivet = Paint()..color = _ouro;
        for (final r in [
          fp(-_hx + 10, 10),
          fp(_hx - 10, 10),
          fp(-_hx + 10, 66),
          fp(_hx - 10, 66),
        ]) {
          c.drawCircle(r, 2.3, rivet);
        }
      },
    );

    // ── Corpo: lateral direita ──
    face(
      _outward([
        const _V(_hx, 0, -_hd),
        const _V(_hx, 0, _hd),
        const _V(_hx, _bodyH, _hd),
        const _V(_hx, _bodyH, -_hd),
      ], const _V(1, 0, 0)),
      shade(_corpo1, 0.16),
      stroke: _ouro.withValues(alpha: 0.65),
      sw: 2.2,
      shader: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shade(_corpo1, 0.05), shade(_corpo2, 0.22)],
      ).createShader(r),
      detail: (c, path, proj) {
        final grain = Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..strokeWidth = 1.1;
        for (final y in [14.0, 30.0, 66.0]) {
          c.drawLine(sp(y, -_hd + 8), sp(y, _hd - 8), grain);
        }
        // A faixa continua na lateral (mais escura, na sombra).
        c.drawPath(
          _quad(sp(40, -_hd), sp(40, _hd), sp(50, _hd), sp(50, -_hd)),
          Paint()..color = shade(_ouro, 0.18),
        );
        // Rebites.
        final rivet = Paint()..color = shade(_ouro, 0.2);
        for (final r in [
          sp(10, -_hd + 8),
          sp(10, _hd - 8),
          sp(66, -_hd + 8),
          sp(66, _hd - 8),
        ]) {
          c.drawCircle(r, 2.3, rivet);
        }
      },
    );

    // ── Tampa ──
    List<_V> lid(List<_V> local, _V nLocal) => _outward([
      for (final p in local) _lidV(p.x, p.y, p.z, th),
    ], _lidN(nLocal, th));

    // Parte de dentro côncava (aparece quando abre e tomba para trás).
    face(
      lid([
        const _V(-_hl, _bodyH, _hd),
        const _V(_hl, _bodyH, _hd),
        const _V(_hl, _bodyH, -_hd),
        const _V(-_hl, _bodyH, -_hd),
      ], const _V(0, -1, 0)),
      _tampa2,
      shader: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(shade(_tampa1, 0.10), const Color(0xFFC8802A), 0.45)!,
          shade(_tampa2, 0.12),
        ],
      ).createShader(r),
      detail: (c, path, proj) {
        // Sombra no fundo do bojo (centro escuro) — vende a concavidade.
        c.drawPath(
          path,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(0, -0.15),
              radius: 0.95,
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.30),
              ],
              stops: const [0.35, 1.0],
            ).createShader(path.getBounds()),
        );
        // Ripas de madeira da dobradiça para a frente.
        final plank = Paint()
          ..color = shade(_tampa2, 0.35).withValues(alpha: 0.6)
          ..strokeWidth = 2.2;
        for (final x in [-_hl * 0.6, -_hl * 0.2, _hl * 0.2, _hl * 0.6]) {
          c.drawLine(lp(x, _bodyH, -_hd), lp(x, _bodyH, _hd), plank);
        }
        // Aresta da frente (boca da tampa) dourada.
        c.drawLine(
          lp(-_hl, _bodyH, _hd),
          lp(_hl, _bodyH, _hd),
          Paint()
            ..color = _ouro.withValues(alpha: 0.8)
            ..strokeWidth = 2.2,
        );
      },
    );

    // Frente da tampa (some ao passar do vertical).
    face(
      lid([
        const _V(-_hl, _bodyH, _hd),
        const _V(_hl, _bodyH, _hd),
        const _V(_hl, _bodyH + _lidH, _hd),
        const _V(-_hl, _bodyH + _lidH, _hd),
      ], const _V(0, 0, 1)),
      _tampa1,
      stroke: _ouro.withValues(alpha: 0.85),
      sw: 2.4,
      shader: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lighten(_tampa1, 0.08), shade(_tampa2, 0.05)],
      ).createShader(r),
      detail: (c, path, proj) {
        c.drawLine(
          lp(-_hl, _bodyH + _lidH * 0.5, _hd),
          lp(_hl, _bodyH + _lidH * 0.5, _hd),
          Paint()
            ..color = shade(_ouro, 0.2).withValues(alpha: 0.65)
            ..strokeWidth = 3,
        );
      },
    );

    // Topo e lateral direita da tampa.
    face(
      lid([
        const _V(-_hl, _bodyH + _lidH, _hd),
        const _V(_hl, _bodyH + _lidH, _hd),
        const _V(_hl, _bodyH + _lidH, -_hd),
        const _V(-_hl, _bodyH + _lidH, -_hd),
      ], const _V(0, 1, 0)),
      _tampa1,
    );
    face(
      lid([
        const _V(_hl, _bodyH, -_hd),
        const _V(_hl, _bodyH, _hd),
        const _V(_hl, _bodyH + _lidH, _hd),
        const _V(_hl, _bodyH + _lidH, -_hd),
      ], const _V(1, 0, 0)),
      shade(_tampa1, 0.2),
      stroke: _ouro.withValues(alpha: 0.55),
      sw: 1.8,
    );

    // Dobradiças no topo traseiro (não giram com a tampa).
    for (final x in [-_hl + 13, _hl - 13]) {
      final hp = _proj(_V(x, _bodyH, -_hd), yaw);
      final r = Rect.fromCenter(center: hp, width: 13, height: 9);
      push(5, (c) {
        c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2.5)),
          Paint()..color = shade(_ouro, 0.1),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2.5)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = shade(_ouro, 0.45),
        );
      });
    }

    // Desenha do mais longe para o mais perto.
    cmds.sort((a, b) => a.$1.compareTo(b.$1));
    for (final cmd in cmds) {
      cmd.$2(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChestPainter old) =>
      old.v != v || old.intensity != intensity;
}
