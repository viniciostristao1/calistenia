# Layout do Cronômetro (referência canônica)

Anatomia e **valores atuais** da tela do player (`app/lib/features/player/player_screen.dart`).
Quando o usuário pedir "aumenta/diminui/mais espaço/mais pra cima", **consultar e atualizar aqui**
— evita re-derivar. Atualizar esta tabela SEMPRE que mexer nos números.

> Fonte de verdade = o código. Este doc é o mapa rápido. Última sync: **2026-08-11 (v0.35.0)**.

## Ordem dos elementos (topo → base) na fase de EXECUÇÃO

| # | Elemento | Widget/local | Valor atual |
|---|----------|--------------|-------------|
| 1 | Barra topo (✕ + título) | `_barraTopo` | título fonte 15 |
| 2 | Barra de progresso geral + rótulo | `_progressoGeral` | barra `minHeight 6`; rótulo "Exercício X/Y · Série S/T" (dim, 12) |
| 3 | gap | `SizedBox` | 12 |
| 4 | **Nome do exercício = TARJA** (faixa larga) | inline `Container` | logo abaixo do progresso; **largura total** (inset h12), fundo `AppColors.surface2`, `radius 12`, padding h14/v10, texto **branco** (`AppColors.text`), **fonte 24** w800, MAIÚSCULO, centralizado |
| 5 | **Espaçador de cima** | `Spacer(flex: 2)` | empurra o bloco do timer p/ baixo (ver #12) |
| 6 | **Contador de reps** (pílula amarela) | `_contadorReps` | só na execução c/ `totalReps>1`; **fonte 46** w800, pílula `radius 999`, padding h24/v6, cores `accentAmbar`/`onAccentAmbar`; **altura reservada 68**; mostra reps CONCLUÍDAS (`f.rep-1`, ver abaixo) |
| 7 | Espaço contador → anel | `SizedBox` | 22 |
| 8 | **Anel + miolo** | `_anel` | ver bloco abaixo |
| 9 | Espaço anel → "A seguir" | `SizedBox` | 20 |
| 10 | **"A seguir"** (próxima ETAPA) | `_legendaProxima` | dim, 13 (lógica abaixo) |
| 11 | **Espaçador de baixo** | `Spacer(flex: 3)` | flex 3 |
| 12 | Controles (‹ · ⏸/▶ · ›) | `_controles` | botão central = `accent` |

**#5 vs #11 (Spacer 2:3):** centralizam o bloco contador+anel+"A seguir" entre a tarja do nome e
os controles, com viés pra cima. O **nome (tarja) fica fixo no topo**, logo abaixo do progresso.

## Miolo do anel (`_anel`) — Column centralizada

| Elemento | Valor atual |
|----------|-------------|
| Diâmetro do anel | **292×292**, stroke **14**, `strokeCap.round`, cor = cor da fase |
| Rótulo da fase (EXECUÇÃO/DESCANSO/PREPARAÇÃO) | cor da fase, **fonte 14** w800, letter-spacing 1.5 |
| gap rótulo → número | `SizedBox 3` |
| **Número gigante** (contagem regressiva) | **fonte 244** w800, **`height: 0.78`**, dentro de `FittedBox(scaleDown)` de largura **270** |
| gap número → subtexto | `SizedBox 3` |
| Subtexto (`_subtextoAnel`) | dim, **fonte 14**: "Série S/T" / "Lado L/2" / "Recupere" / "Prepare-se" / "Vai!" |

⚠️ **Por que `height: 0.78` no número:** com `height 1.0` o "leading" da fonte 244 é enorme e
empurra o rótulo pra fora do círculo por cima e o subtexto por baixo. 0.78 + gaps 3px = os dois
ficam dentro do anel. Se mudar a fonte do número, reavaliar o 0.78.

## Contador de repetições — semântica (0-based)

Mostra **repetições CONCLUÍDAS**: `'${f.rep - 1}/${f.totalReps}'`. Começa em **0/N**, vai até
**(N-1)/N**; ao fechar a última, a série encerra (o "N cheio" **não** fica girando). Fim da série
= som + carimbo "Série X/Y ✓". `f.rep` é 1-based no modelo (`fase.dart`, `for r=1..reps`), daí o `-1`.

## "A seguir" — próxima ETAPA (não o próximo movimento)

`_proximaEtapaIdx` + `_descricaoEtapa`. Regra: durante a execução, PULA as repetições restantes da
série atual (são a mesma etapa/movimento) e aponta a próxima etapa DIFERENTE. Resultado:

- Em **preparação** → "A seguir: `<Nome> · N reps`" (a execução que vem).
- Em **execução** (qualquer rep) → "A seguir: `Descanso · 1min 30s`" (o descanso após a série).
- Em **descanso** → "A seguir: `<Nome> · N reps`" (a próxima série/lado).
- Última série (sem descanso após) → próximo exercício, ou "A seguir: fim do treino".
- Execução isométrica (reps=1) mostra tempo em vez de "N reps"; unilateral inclui "(lado L)".

## Cores das fases (semânticas, `AppColors`)

| Fase | Cor | Hex |
|------|-----|-----|
| Preparação | `prep` verde claro | `#5DE0A0` |
| Execução | `exec` laranja | `#FF9538` |
| Descanso | `rest` azul claro | `#5B9CFF` |
| Marca/ação (accent) | âmbar (padrão) | `#F5A524` |

## Performance / estabilidade do cronômetro

- **Rebuild throttle:** o `Timer` roda a 100ms (p/ bip/háptico), mas `setState` só dispara quando o
  **segundo exibido muda** (`_ultimoSegExibido`) — ~10× menos rebuilds do número/anel.
- **Áudio (lowLatency/SoundPool):** os players de bip/fim são **pré-carregados 1×** (`setSource` no
  `_prepararSom`); cada disparo é `stop()+resume()` (`_replay`), NUNCA `play(AssetSource)` (que
  re-prepara e trava com muitas reps). Erros de áudio são engolidos (não derrubam o timer).

## Cheat-sheet dos "botões de ajuste" mais pedidos

- **Número maior/menor** → fonte 244 (mexer junto no `height 0.78` e na largura 270 do FittedBox).
- **Amarelo maior/menor** → fonte 46 + altura reservada 68.
- **Amarelo mais/menos redondo** → `radius 999` (pílula).
- **Nome (tarja) maior/menor** → fonte 24; largura/inset via `Padding(horizontal:12)`.
- **Mais/menos espaço contador↔anel** → `SizedBox 22` (#7).
- **Bloco do timer mais pra cima/baixo** → Spacer `2:3` (#5/#11).
- **Divisória do card na home** (título↔exercícios) → `Divider(color: AppColors.dim2)` em `home_screen.dart`.
