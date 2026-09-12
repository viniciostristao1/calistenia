/// **Átomos reutilizáveis** — os blocos pequenos que as recompensas compõem.
///
/// Vazio na Fase 0 (propositalmente). A Fase 1 adiciona um arquivo por átomo e
/// o exporta aqui. Planejados (ver `ANIMACOES.md`):
///
/// - `pop_in.dart`      escala + overshoot (elasticOut / easeOutBack)
/// - `bounce.dart`      quique
/// - `shake.dart`       tremida curta
/// - `fade_in.dart`     surgir/sumir suave
/// - `glow.dart`        halo pulsante
/// - `shine_sweep.dart` brilho passando por cima
/// - `fly_to_target.dart` voar até um ponto
/// - `screen_flash.dart`  flash de tela
/// - `pulse.dart`       pulsar
/// - `trail.dart`       rastro
///
/// Regra: cada átomo é um widget pequeno (< ~150 linhas) que recebe um
/// `FxParams` e não sabe nada de recompensas — só de movimento.
library;

export 'bounce.dart';
export 'fade_through.dart';
export 'fly_to_target.dart';
export 'glow.dart';
export 'pop_in.dart';
export 'pulse.dart';
export 'screen_flash.dart';
export 'shake.dart';
export 'shine_sweep.dart';
