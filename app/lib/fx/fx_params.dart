import 'package:flutter/foundation.dart';

/// **Parâmetros ajustáveis de um efeito** — o que o Laboratório controla com
/// sliders. Toda animação recebe um [FxParams] e deve respeitá-lo (ou ignorar
/// com naturalidade o que não fizer sentido pra ela).
///
/// Imutável: o Lab guarda uma instância no estado e cria variações com
/// [copyWith] a cada movimento de slider.
@immutable
class FxParams {
  /// Multiplicador de velocidade (0.25× lento … 3× rápido). Encurta/estica a
  /// duração via [effectiveDuration].
  final double speed;

  /// Força do efeito (0 sutil … 2 exagerado): amplitude de shake, overshoot,
  /// alcance do glow, distância das partículas.
  final double intensity;

  /// Escala final do elemento (0.5 … 2).
  final double scale;

  /// Quantidade de partículas (para efeitos que emitem partículas).
  final int particleCount;

  /// Duração-base do efeito (antes de aplicar [speed]).
  final Duration duration;

  /// Atraso antes de começar.
  final Duration delay;

  /// Quantas vezes repetir (1 = uma vez). 0 = loop infinito (útil no Lab).
  final int repeat;

  const FxParams({
    this.speed = 1.0,
    this.intensity = 1.0,
    this.scale = 1.0,
    this.particleCount = 24,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
    this.repeat = 1,
  });

  /// Duração já corrigida pela velocidade (o que os efeitos devem usar).
  Duration get effectiveDuration => Duration(
      milliseconds: (duration.inMilliseconds / speed).round().clamp(1, 60000));

  bool get loopForever => repeat <= 0;

  FxParams copyWith({
    double? speed,
    double? intensity,
    double? scale,
    int? particleCount,
    Duration? duration,
    Duration? delay,
    int? repeat,
  }) =>
      FxParams(
        speed: speed ?? this.speed,
        intensity: intensity ?? this.intensity,
        scale: scale ?? this.scale,
        particleCount: particleCount ?? this.particleCount,
        duration: duration ?? this.duration,
        delay: delay ?? this.delay,
        repeat: repeat ?? this.repeat,
      );
}
