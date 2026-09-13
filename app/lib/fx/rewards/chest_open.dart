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

  // Modelo (y p/ cima, z p/ frente).
  static const _bodyW = 122.0;
  static const _bodyH = 74.0;
  static const _depth = 88.0;
  static const _lidH = 32.0;
  static const _wall = 4.0;
  static const _floorY = _bodyH - 20.0;
  static const _hx = _bodyW / 2;
  static const _hd = _depth / 2;
  static const _hxi = _hx - _wall;
  static const _hzi = _hd - _wall;
  static const _hl = _hx + 3; // tampa um pouco maior

  // Câmera axonométrica (vista 3/4: frente + lateral direita).
  static const _yaw = 0.66; // ~38° (diagonal)
  static const _pitch = 0.38; // ~22° (vê o fundo)
  static const _scale = 0.90;
  static const _cx = 100.0;
  static const _cy = 174.0;

  static final _luz = _norm(const _V(-0.38, 0.72, 0.58));

  /// Ângulo da tampa (0 = fechada). Antecipa "sentando", destranca e abre com
  /// inércia (rápida no início, freia no fim), bate no batente e volta
  /// amortecendo.
  double get _theta {
    final dip = -0.12 * sin(Interval(0.12, 0.30).transform(v) * pi);
    final openT = Interval(0.30, 0.64, curve: Curves.easeOutCubic).transform(v);
    var open = 1.78 * openT;
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

    // ── Interior (fundo de madeira + paredes + aro da boca) ──
    final glow =
        (0.45 + 0.55 * Interval(0.30, 0.62).transform(v)) *
        intensity.clamp(0.0, 1.4);
    const madeiraDentro = Color(0xFF4A2A12);
    // Fundo (assoalho do baú) — é o que dá a sensação de "ter fundo".
    face(
      _outward([
        const _V(-_hxi, _floorY, _hzi),
        const _V(_hxi, _floorY, _hzi),
        const _V(_hxi, _floorY, -_hzi),
        const _V(-_hxi, _floorY, -_hzi),
      ], const _V(0, 1, 0)),
      madeiraDentro,
      shader: (r) => RadialGradient(
        colors: [
          const Color(0xFFFFC93C).withValues(alpha: (glow * 0.5).clamp(0, 1)),
          madeiraDentro,
        ],
      ).createShader(r),
      detail: (c, path, proj) {
        // Tábuas do fundo.
        final grain = Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..strokeWidth = 1.4;
        for (final x in [-_hxi * 0.5, 0.0, _hxi * 0.5]) {
          c.drawLine(
            _proj(_V(x, _floorY, -_hzi), yaw),
            _proj(_V(x, _floorY, _hzi), yaw),
            grain,
          );
        }
      },
    );
    // Paredes internas (madeira mais escura).
    face(
      _outward([
        const _V(-_hxi, _floorY, _hzi),
        const _V(_hxi, _floorY, _hzi),
        const _V(_hxi, _bodyH, _hzi),
        const _V(-_hxi, _bodyH, _hzi),
      ], const _V(0, 0, -1)),
      shade(madeiraDentro, 0.3),
    );
    face(
      _outward([
        const _V(_hxi, _floorY, -_hzi),
        const _V(_hxi, _floorY, _hzi),
        const _V(_hxi, _bodyH, _hzi),
        const _V(_hxi, _bodyH, -_hzi),
      ], const _V(-1, 0, 0)),
      shade(madeiraDentro, 0.45),
    );
    // Parede interna do FUNDO (lado esquerdo na perspectiva) — sem ela o
    // interior abria para o cenário.
    face(
      _outward([
        const _V(-_hxi, _floorY, -_hzi),
        const _V(-_hxi, _floorY, _hzi),
        const _V(-_hxi, _bodyH, _hzi),
        const _V(-_hxi, _bodyH, -_hzi),
      ], const _V(1, 0, 0)),
      shade(madeiraDentro, 0.55),
    );
    face(
      _outward([
        const _V(-_hxi, _floorY, -_hzi),
        const _V(_hxi, _floorY, -_hzi),
        const _V(_hxi, _bodyH, -_hzi),
        const _V(-_hxi, _bodyH, -_hzi),
      ], const _V(0, 0, 1)),
      shade(madeiraDentro, 0.35),
    );
    // Aro das paredes (topo) — fecha a boca e dá espessura.
    const aro = Color(0xFF7A4A20);
    face(
      _outward([
        const _V(-_hx, _bodyH, _hzi),
        const _V(_hx, _bodyH, _hzi),
        const _V(_hx, _bodyH, _hd),
        const _V(-_hx, _bodyH, _hd),
      ], const _V(0, 1, 0)),
      aro,
    );
    face(
      _outward([
        const _V(_hxi, _bodyH, -_hd),
        const _V(_hx, _bodyH, -_hd),
        const _V(_hx, _bodyH, _hd),
        const _V(_hxi, _bodyH, _hd),
      ], const _V(0, 1, 0)),
      shade(aro, 0.12),
    );
    face(
      _outward([
        const _V(-_hxi, _bodyH, -_hd),
        const _V(_hxi, _bodyH, -_hd),
        const _V(_hxi, _bodyH, -_hzi),
        const _V(-_hxi, _bodyH, -_hzi),
      ], const _V(0, 1, 0)),
      shade(aro, 0.2),
    );
    // Aro do lado do FUNDO (esquerdo na perspectiva).
    face(
      _outward([
        const _V(-_hx, _bodyH, -_hd),
        const _V(-_hxi, _bodyH, -_hd),
        const _V(-_hxi, _bodyH, _hd),
        const _V(-_hx, _bodyH, _hd),
      ], const _V(0, 1, 0)),
      shade(aro, 0.08),
    );
    // Filete dourado na aresta interna da boca.
    final aroDepth = _centroid([
      const _V(-_hxi, _bodyH, _hzi),
      const _V(_hxi, _bodyH, _hzi),
      const _V(_hxi, _bodyH, -_hzi),
      const _V(-_hxi, _bodyH, -_hzi),
    ]).dot(cam);
    push(aroDepth + 2, (c) {
      final o = Paint()
        ..color = _ouro.withValues(alpha: 0.6)
        ..strokeWidth = 1.8;
      c.drawLine(
        _proj(const _V(-_hxi, _bodyH, _hzi), yaw),
        _proj(const _V(_hxi, _bodyH, _hzi), yaw),
        o,
      );
      c.drawLine(
        _proj(const _V(_hxi, _bodyH, -_hzi), yaw),
        _proj(const _V(_hxi, _bodyH, _hzi), yaw),
        o,
      );
      c.drawLine(
        _proj(const _V(-_hxi, _bodyH, -_hzi), yaw),
        _proj(const _V(-_hxi, _bodyH, _hzi), yaw),
        o,
      );
    });

    // ── Estrelinhas no fundo do baú (monte de tesouro) ──
    // Cada estrela tem a mesma cara da estrela que salta (`Star3D`): gradiente
    // de luz, contorno arredondado e núcleo gravado. Ficam encostadas no
    // assoalho (plano inclinado) em camadas, formando um monte. A ordenação
    // por profundidade faz as paredes/tampa cobrirem o que estiver atrás.
    void starOnFloor(
      double cx,
      double cz,
      double r,
      double rot, {
      double lift = 0,
      double tone = 0,
      double order = 0,
      double tilt = 0.82,
    }) {
      final st = sin(tilt);
      final ct = cos(tilt);
      _V at(double u, double v, double dy, double dz) =>
          _V(cx + u, _floorY + lift + (r - v) * st + dy, cz + v * ct + dz);
      List<_V> outline(double dy, double dz) {
        final pts = <_V>[];
        for (var i = 0; i < 10; i++) {
          final rad = i.isEven ? r : r * 0.55;
          final a = rot - pi / 2 + i * pi / 5;
          pts.add(at(cos(a) * rad, sin(a) * rad, dy, dz));
        }
        return pts;
      }

      final cor = Color.lerp(_ouro, shade(_ouro, 0.42), tone)!;
      // Sombra no assoalho.
      face(
        _outward([
          for (var i = 0; i < 12; i++)
            _V(
              cx + cos(i * pi / 6) * r * 1.05,
              _floorY + 0.05,
              cz - r * ct * 0.15 + sin(i * pi / 6) * r * 0.9 + 1.8,
            ),
        ], const _V(0, 1, 0)),
        shade(madeiraDentro, 0.3),
        bias: order,
      );
      // Espessura (cópia mais baixa, deslocada para trás).
      face(
        _outward(outline(-2.6, 2.0), const _V(0, 1, 0)),
        shade(cor, 0.52),
        bias: order + 0.1,
      );
      // Face principal: gradiente de luz + contorno arredondado + núcleo.
      face(
        _outward(outline(0, 0), const _V(0, 1, 0)),
        cor,
        bias: order + 0.2,
        stroke: lighten(cor, 0.05),
        sw: 3.2,
        shader: (b) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighten(cor, 0.5), cor, shade(cor, 0.38)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(b),
        detail: (c, path, proj) {
          // Núcleo gravado (estrela menor em relevo).
          final inner = <Offset>[];
          for (var i = 0; i < 10; i++) {
            final rad = i.isEven ? r * 0.52 : r * 0.27;
            final a = rot - pi / 2 + i * pi / 5;
            inner.add(_proj(at(cos(a) * rad, sin(a) * rad, 0, 0), yaw));
          }
          final ip = Path()..moveTo(inner[0].dx, inner[0].dy);
          for (var i = 1; i < inner.length; i++) {
            ip.lineTo(inner[i].dx, inner[i].dy);
          }
          ip.close();
          c.drawPath(
            ip,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3
              ..color = shade(cor, 0.5).withValues(alpha: 0.85),
          );
          c.drawPath(
            ip.shift(const Offset(0, -1)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8
              ..color = Colors.white.withValues(alpha: 0.35),
          );
        },
      );
    }

    // Monte: camadas que cobrem o fundo e sobem no meio.
    // Base (chão) — tom mais escuro (sombra da parede).
    starOnFloor(-40, -25, 16.0, 0.2, tone: 0.30, order: 0.0);
    starOnFloor(-21, -14, 15.5, -0.5, tone: 0.30, order: 0.1);
    starOnFloor(0, -27, 16.0, 0.6, tone: 0.30, order: 0.2);
    starOnFloor(21, -13, 15.5, -0.2, tone: 0.30, order: 0.3);
    starOnFloor(39, -24, 15.0, 0.4, tone: 0.30, order: 0.4);
    starOnFloor(-33, -5, 15.0, 0.9, tone: 0.34, order: 0.5);
    starOnFloor(33, -4, 15.0, -0.7, tone: 0.34, order: 0.6);
    // Frente (cobre o resto do assoalho visível).
    starOnFloor(-14, -2, 14.0, -0.35, tone: 0.42, order: 0.7);
    starOnFloor(17, -1, 14.0, 0.65, tone: 0.42, order: 0.75);
    // Segunda camada.
    starOnFloor(-29, -19, 14.0, 0.1, lift: 9, tone: 0.16, order: 1.0);
    starOnFloor(-9, -19, 14.0, -0.6, lift: 9, tone: 0.16, order: 1.1);
    starOnFloor(13, -22, 13.5, 0.5, lift: 9, tone: 0.16, order: 1.2);
    starOnFloor(34, -16, 13.0, -0.3, lift: 9, tone: 0.16, order: 1.3);
    // Terceira camada.
    starOnFloor(-20, -18, 12.5, 0.3, lift: 17, tone: 0.05, order: 2.0);
    starOnFloor(2, -18, 12.5, -0.5, lift: 17, tone: 0.05, order: 2.1);
    // Topo do monte.
    starOnFloor(-8, -17, 11.0, 0.5, lift: 24, tone: 0.0, order: 3.0);

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

    // Parte de dentro CÔNCAVA (curva de verdade): a superfície sobe para
    // dentro da tampa no meio e as tábuas acompanham a curva.
    const sagLid = 10.0;
    _V inner(double x, double u) =>
        _lidV(x, _bodyH + sagLid * sin(pi * u), -_hd + 2 * _hd * u, th);
    const passes = 6;
    for (var i = 0; i < passes; i++) {
      final u0 = i / passes;
      final u1 = (i + 1) / passes;
      final um = (u0 + u1) / 2;
      face(
        _outward([
          inner(-_hl, u0),
          inner(_hl, u0),
          inner(_hl, u1),
          inner(-_hl, u1),
        ], _lidN(const _V(0, -1, 0), th)),
        shade(_tampa1, 0.16 + 0.42 * sin(pi * um)),
        bias: 0.02 * i,
      );
    }
    // Tábuas + aresta dourada da boca (seguem a curva), por cima das faixas.
    final lidDepth = _centroid([
      inner(-_hl, 0),
      inner(_hl, 0),
      inner(-_hl, 1),
      inner(_hl, 1),
    ]).dot(cam);
    push(lidDepth + 2, (c) {
      final plank = Paint()
        ..color = shade(_tampa2, 0.30).withValues(alpha: 0.55)
        ..strokeWidth = 2.2;
      for (final x in [-_hl * 0.6, -_hl * 0.2, _hl * 0.2, _hl * 0.6]) {
        final path = Path();
        for (var i = 0; i <= 10; i++) {
          final p = _proj(inner(x, i / 10), yaw);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        c.drawPath(path, plank);
      }
      // Aresta da frente (boca da tampa) dourada.
      c.drawLine(
        _proj(inner(-_hl, 1), yaw),
        _proj(inner(_hl, 1), yaw),
        Paint()
          ..color = _ouro.withValues(alpha: 0.8)
          ..strokeWidth = 2.2,
      );
    });

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
