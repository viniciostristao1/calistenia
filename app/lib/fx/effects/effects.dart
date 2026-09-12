/// **Átomos reutilizáveis** — os blocos pequenos que as recompensas compõem.
///
/// Cada arquivo é um átomo. Implementados (ver `ANIMACOES.md`):
///
/// - `pop_in.dart`       escala + overshoot (elasticOut / easeOutBack)
/// - `bounce.dart`       quique
/// - `shake.dart`        tremida curta
/// - `fade_through.dart` surgir/sumir suave
/// - `glow.dart`         halo pulsante
/// - `shine_sweep.dart`  brilho passando por cima
/// - `fly_to_target.dart` voar até um ponto
/// - `screen_flash.dart` flash de tela
/// - `pulse.dart`        pulsar
/// - `spin3d.dart`       giro 3D no próprio eixo (moeda de pé, perspectiva)
/// - `rays.dart`         raios radiais girando ao fundo (holofote)
/// - `delayed.dart`      atrasa o nascimento do filho (sincroniza impacto)
///
/// Regra: cada átomo é um widget pequeno (< ~150 linhas) que recebe um
/// `FxParams` e não sabe nada de recompensas — só de movimento.
library;

export 'bounce.dart';
export 'delayed.dart';
export 'fade_through.dart';
export 'fly_to_target.dart';
export 'glow.dart';
export 'pop_in.dart';
export 'pulse.dart';
export 'rays.dart';
export 'screen_flash.dart';
export 'shake.dart';
export 'shine_sweep.dart';
export 'spin3d.dart';
