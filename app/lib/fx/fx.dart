/// **Camada de efeitos/recompensas (`fx/`) — ponto único de importação.**
///
/// Telas devem importar só isto:
/// ```dart
/// import '../../fx/fx.dart';
/// ```
///
/// Estrutura da camada (ver `ANIMACOES.md` na raiz do repo para o desenho
/// completo, a inspiração e o guia de "como adicionar um efeito novo"):
///
/// - [RewardType]      — a identidade da recompensa (o "quê").
/// - [FxParams]        — parâmetros ajustáveis (o Laboratório controla).
/// - [RewardRegistry]  — a ponte tipo → animação (trocar sem mexer nas telas).
/// - [RewardFx]        — a API pública: dispara via Overlay (o "quando/onde").
/// - `effects/`        — ÁTOMOS reutilizáveis (pop, bounce, shake, glow…) — Fase 1+.
/// - `particles/`      — motor de partículas (CustomPainter) — Fase 2.
/// - `rewards/`        — MOLÉCULAS: composições de átomos — Fase 4.
library;

export 'fx_params.dart';
export 'register_rewards.dart';
export 'reward_overlay.dart';
export 'reward_registry.dart';
export 'reward_type.dart';
