/// **Motor de partículas** — o único lugar da camada que desenha à mão
/// (`CustomPainter`), porque partículas/explosões/rastros não saem bem só com
/// widgets. Ainda assim: **zero dependências externas.**
///
/// Vazio na Fase 0. A Fase 2 adiciona e exporta aqui:
///
/// - `particle.dart`         uma partícula (posição, velocidade, vida, cor)
/// - `particle_system.dart`  física simples (gravidade, atrito, emissão)
/// - `particle_painter.dart` o CustomPainter
/// - `particle_burst.dart`   widget: explosão radial (usa `FxParams.particleCount`)
/// - `confetti.dart`         widget: chuva (evolução do `_ConfettiLayer` atual)
library;
