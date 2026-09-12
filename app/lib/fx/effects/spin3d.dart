import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fx_params.dart';

/// Eixo do giro 3D — a rotação acontece no **próprio eixo** do elemento.
enum SpinAxis { x, y, z }

/// **Átomo: giro 3D no próprio eixo (moeda de pé).**
///
/// O filho gira em torno do próprio eixo com **perspectiva de verdade**
/// (`Matrix4` + `setEntry(3,2,…)`) — como uma moeda girando de pé (eixo Y,
/// padrão), e **não** um giro "deitado" no plano da tela (`Transform.rotate`,
/// que roda como ponteiro de relógio).
///
/// Numa passada: dá [turns] voltas desacelerando, pousa com overshoot elástico,
/// cambaleia no eixo que amortece e dá um squash de impacto. A face de trás é
/// espelhada (o desenho aparece nas duas faces, como numa moeda), então o ícone
/// nunca surge "de costas". Quando fica de perfil, um fio de luz marca a aresta.
/// Com `params.loopForever` (modo vitrine do Laboratório), gira para sempre em
/// velocidade constante, sem pouso.
class Spin3D extends StatefulWidget {
  const Spin3D({
    super.key,
    required this.child,
    this.params = const FxParams(),
    this.axis = SpinAxis.y,
    this.turns = 2,
    this.direction = 1,
    this.perspective = 0.0018,
    this.fromScale = 0.3,
    this.spinFraction = 0.62,
    this.mirrorBack = true,
    this.glint = true,
  });

  final Widget child;
  final FxParams params;

  /// Eixo de rotação (no próprio eixo do elemento).
  final SpinAxis axis;

  /// Voltas completas até parar (inteiro → termina alinhado ao inicial).
  final int turns;

  /// Sentido: `1` horário, `-1` anti-horário.
  final double direction;

  /// Força da perspectiva (maior = mais dramática).
  final double perspective;

  /// Escala de nascença (0..1): cresce girando, como item surgindo.
  final double fromScale;

  /// Fração da duração gasta girando; o resto é o pouso (cambaleada + squash).
  final double spinFraction;

  /// Espelha a face de trás (moeda), evitando o ícone "de costas".
  final bool mirrorBack;

  /// Fio de luz na aresta quando o item fica de perfil.
  final bool glint;

  @override
  State<Spin3D> createState() => _Spin3DState();
}

class _Spin3DState extends State<Spin3D> with SingleTickerProviderStateMixin {
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

  Matrix4 _matrix(double angle) {
    final m = Matrix4.identity()..setEntry(3, 2, widget.perspective);
    switch (widget.axis) {
      case SpinAxis.x:
        m.rotateX(angle);
      case SpinAxis.y:
        m.rotateY(angle);
      case SpinAxis.z:
        m.rotateZ(angle);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final loop = widget.params.loopForever;
    final intensity = widget.params.intensity.clamp(0.0, 2.0);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final v = _ctrl.value;
        double angle;
        double land = 0;
        if (loop) {
          angle = 2 * math.pi * widget.turns * v * widget.direction;
        } else {
          final spin = Interval(
            0.0,
            widget.spinFraction,
            curve: Curves.easeOutCubic,
          ).transform(v);
          angle = 2 * math.pi * widget.turns * spin * widget.direction;
          land = ((v - widget.spinFraction) / (1 - widget.spinFraction)).clamp(
            0.0,
            1.0,
          );
          if (land > 0) {
            // Cambaleada no eixo que amortece até alinhar de novo.
            angle +=
                math.sin(land * 3 * math.pi) *
                0.35 *
                (1 - land) *
                intensity *
                widget.direction;
          }
        }

        final scale = loop
            ? 1.0
            : widget.fromScale +
                  (1 - widget.fromScale) *
                      Curves.elasticOut.transform(
                        (v / (widget.spinFraction * 0.9)).clamp(0.0, 1.0),
                      );
        final op = loop
            ? 1.0
            : Interval(0.0, 0.14).transform(v).clamp(0.0, 1.0);
        // Squash alternado no pouso (achata e estica).
        final squash =
            math.sin(land * 2.5 * math.pi) * 0.10 * (1 - land) * intensity;

        Widget content = child!;
        if (widget.axis != SpinAxis.z &&
            widget.mirrorBack &&
            math.cos(angle) < 0) {
          content = Transform.scale(scaleX: -1, child: content);
        }

        Widget core = Transform(
          transform: _matrix(angle),
          alignment: Alignment.center,
          child: content,
        );

        if (widget.axis != SpinAxis.z && widget.glint) {
          final edge = math.pow(1 - math.cos(angle).abs(), 9).toDouble();
          if (edge > 0.01) {
            core = Stack(
              alignment: Alignment.center,
              children: [
                core,
                Positioned.fill(
                  child: IgnorePointer(
                    child: FractionallySizedBox(
                      widthFactor: 0.022,
                      heightFactor: 1,
                      child: Opacity(
                        opacity: (edge * 0.9).clamp(0.0, 1.0),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.white,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        }

        return Opacity(
          opacity: op,
          child: Transform.scale(
            scale: (scale * widget.params.scale).clamp(0.0, 4.0),
            child: Transform.scale(
              scaleX: (1 + squash).clamp(0.4, 1.6),
              scaleY: (1 - squash).clamp(0.4, 1.6),
              child: core,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
