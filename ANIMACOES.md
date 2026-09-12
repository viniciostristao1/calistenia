# ANIMAÇÕES & RECOMPENSAS — camada `fx/` (doc canônico)

> Leia isto antes de mexer em qualquer animação de recompensa do Calis Timer.
> É a fonte de verdade da arquitetura da camada `app/lib/fx/`. Complementa o
> `INICIO.md` (fluxo de entrega) e o `APRENDIZADOS.md` (diário técnico).

## Objetivo

Uma **camada de animações/recompensas reutilizável**, com sensação de **impacto,
recompensa e polimento** — a linguagem visual de jogos mobile (referência de
*sensação*, tipo Brawl Stars; **não** copiamos arte nem animação específica).
Efeitos **2.5D** feitos em Flutter (escala, rotação, bounce, overshoot, shake,
fade, brilho, partículas, explosões, elementos surgindo do centro / voando até
um ponto, vibrações, trails, flashes e combinações). **Sem 3D real** por ora.

## Princípios (não violar)

1. **Recompensa ≠ animação.** A *identidade* de uma recompensa (`RewardType`) é
   separada da sua *apresentação* (o widget que anima). Dá pra trocar a animação
   sem tocar em nenhuma tela.
2. **A lógica de recompensa não é desta camada.** Regras de sequência/medalhas
   vivem em `util/gamificacao.dart`; sorteio de insígnias em `util/insignias.dart`;
   estado/persistência em `services/*_repository.dart`. `fx/` **só apresenta**.
3. **Átomo → molécula.** Efeitos grandes são composições de efeitos pequenos.
   Nada de animação monolítica.
4. **Flutter puro primeiro.** Sem dependências externas até que uma traga
   vantagem *clara* (ver "Dependências").
5. **Sem overengineering.** Cada átomo é um widget pequeno (< ~150 linhas).

## As 5 responsabilidades (e onde cada uma mora)

| # | Responsabilidade | Onde | Status |
|---|---|---|---|
| 1 | Lógica de recompensa (regras) | `util/gamificacao.dart`, `util/insignias.dart` | existe |
| 2 | Estado/progresso (persistência) | `services/*_repository.dart` | existe |
| 3 | Orquestração da animação | `fx/reward_overlay.dart`, `fx/reward_registry.dart` | Fase 0 |
| 4 | Efeitos visuais | `fx/effects/`, `fx/particles/`, `fx/rewards/` | Fase 1+ |
| 5 | Laboratório de testes | `features/lab/lab_screen.dart` | Fase 0 (shell) |

## Estrutura de pastas

```
app/lib/fx/
  fx.dart                 barrel + docstring (telas importam SÓ isto)
  reward_type.dart        enum RewardType + metadados (label/icon/cor) — o "QUÊ"
  fx_params.dart          FxParams (speed/intensity/scale/particles/duration/delay/repeat)
  reward_registry.dart    RewardType -> builder da animação (a PONTE)
  reward_overlay.dart     RewardFx.show(...) via Overlay — a API pública ("QUANDO/ONDE")
  effects/                ÁTOMOS reutilizáveis (Fase 1)
  particles/              motor de partículas em CustomPainter (Fase 2)
  rewards/                MOLÉCULAS: composições (Fase 4)  [+ placeholder_reward.dart hoje]

app/lib/features/lab/
  lab_screen.dart         o Laboratório (importa SÓ fx/ — jamais services/)
```

`fx/` fica no topo de `lib/` (irmã de `theme/`, `util/`) porque é **transversal**
(usada por player, check-in, home e pelo Lab), não pertence a uma feature.

## API pública (como as telas usam)

```dart
import '../../fx/fx.dart';

// Recomendado: flutua sobre a tela atual, zero acoplamento de layout.
RewardFx.show(context, RewardType.star, value: 50);
RewardFx.show(context, RewardType.chest, onDone: () { /* ... */ });

// Embutido numa caixa específica (ex.: tela "Treino concluído"):
RewardRegistry.build(context, RewardType.trophyGold, const FxParams());
```

A tela **só conhece `RewardType`**. Qual widget toca é decisão do
`RewardRegistry` — trocar `StarBurst` v1→v2 é mexer só no registry.

## Dependências — decisão

| Precisa? | Ferramenta | Veredito |
|---|---|---|
| escala/rotação/bounce/overshoot/shake/fade/fly/pulse | `AnimationController` + `Tween`/`CurvedAnimation` + `Transform` | Flutter puro |
| partículas/explosão/glow/trail | `CustomPainter` + 1 `AnimationController` | Flutter puro (única pintura à mão) |
| som na recompensa | `audioplayers` (**já no projeto**) + `services/som_repository.dart` | reusar |
| Rive | arte vetorial de designer | **adiar** — só se um efeito específico pedir arte feita à mão |
| Flame | — | **não** — game-engine, exagero para pop-ups |

## Como adicionar um efeito novo (3 passos)

1. **Átomo?** Crie em `fx/effects/<nome>.dart` um widget pequeno que recebe
   `FxParams` e só cuida de movimento (não sabe de recompensa). Exporte em
   `effects/effects.dart`.
2. **Molécula (recompensa)?** Crie em `fx/rewards/<nome>.dart` compondo átomos.
   Ex.: `ChestOpen = Shake → LidOpen → Glow + ParticleBurst → RewardReveal`.
3. **Ligue** o `RewardType` à molécula no `RewardRegistry` (via `register(...)`)
   e teste no Laboratório. Nenhuma tela muda.

## Regra de ouro do Laboratório

`features/lab/` importa **apenas `fx/`**. Nunca `services/`, `*_repository`,
`shared_preferences` nem Firestore. Assim é **impossível**, por construção, o Lab
alterar XP, sequência, medalhas, insígnias ou estado persistente. Ele fabrica
dados fake e só dispara a apresentação.

## Nota técnica: cores são runtime

`AppColors` tem 4 temas trocáveis em runtime (getters lêem a paleta atual).
**Nunca** use `const` com `AppColors` num efeito — leia a cor no `build`
(`type.color(context)`, `context.accent`, `AppColors.estrela`). A estrela das
insígnias é sempre amarela (`AppColors.estrela`), independente do tema.

## O que reaproveitar do que já existe

- `util/conquista_badge.dart` — troféu/medalha com **brilho 2.5D** já desenhado;
  serve de "conteúdo" dentro dos reveals de troféu/medalha.
- `player_screen.dart` tem hoje, como widgets privados, as sementes a **extrair**
  para `fx/` na Fase 1: `_IconeComemora` (pop elasticOut), `_ConfettiLayer`
  (confete), `_FadeSlide`, `_NovosRecordes`, `_CarimboPill`.
- `services/som_repository.dart` — hook opcional de som na recompensa.

## Roteiro de implementação (fases)

| Fase | Entrega | Estado |
|---|---|---|
| **0** | scaffold `fx/` + este doc + `RewardType`/`FxParams`/registry/overlay + Lab shell (placeholder) + tile no Config | **feita** |
| 1 | átomos (pop/bounce/shake/fade/glow/shine/flash/pulse) + extrair confete/ícone do player | — |
| 2 | motor de partículas + `ParticleBurst` + confete melhorado | — |
| 3 | Lab com átomos reais + preview por efeito | — |
| 4 | moléculas: StarBurst/XpGain/RewardReveal → Trophy/Medal → ChestOpen | — |
| 5 | plugar o overlay nos momentos reais (fim de treino, desbloqueio, insígnia) | — |
| 6 | polish / avaliar Rive só se um efeito pedir arte de designer | — |

Cada fase fecha com o ritual do `INICIO.md` (analyze → subir versão → APRENDIZADOS/
ATUALIZACOES → push → CI na nuvem → link `latest`).
