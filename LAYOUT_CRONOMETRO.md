# Layout do Cronômetro (referência canônica)

Anatomia e **valores atuais** da tela do player (`app/lib/features/player/player_screen.dart`).
Quando o usuário pedir "aumenta/diminui/mais espaço/mais pra cima", **consultar e atualizar aqui**
— evita re-derivar. Atualizar esta tabela SEMPRE que mexer nos números.

> Fonte de verdade = o código. Este doc é o mapa rápido. Última sync: **2026-08-10 (v0.34.0)**.

## Ordem dos elementos (topo → base) na fase de EXECUÇÃO

| # | Elemento | Widget/local | Valor atual |
|---|----------|--------------|-------------|
| 1 | Barra topo (✕ + título) | `_barraTopo` | título fonte 15 |
| 2 | Barra de progresso geral + rótulo | `_progressoGeral` | barra `minHeight 6`; rótulo "Exercício X/Y · Série S/T" (dim, 12) |
| 3 | **Espaçador de cima** | `Spacer(flex: 2)` | flex 2 (ver #12) |
| 4 | **Nome do exercício** (pílula cinza) | inline `Container` | fundo `AppColors.surface2`, `radius 14`, padding h18/v8, texto UPPERCASE **fonte 20** w700 |
| 5 | Espaço nome → amarelo | `SizedBox` | **16** |
| 6 | **Contador de reps** (pílula amarela) | `_contadorReps` | só na execução c/ `totalReps>1`; **fonte 40** w800, **pílula `radius 999`**, padding h24/v6, cores `accentAmbar`/`onAccentAmbar`; **altura reservada 60** (não deixa o layout pular entre fases) |
| 7 | Espaço amarelo → anel | `SizedBox` | **22** (respiro pedido) |
| 8 | **Anel + miolo** | `_anel` | ver bloco abaixo |
| 9 | Espaço anel → legenda | `SizedBox` | 20 |
| 10 | Legenda "A seguir: …" | `_legendaProxima` | dim, 13 |
| 11 | **Espaçador de baixo** | `Spacer(flex: 3)` | flex 3 |
| 12 | Controles (‹ · ⏸/▶ · ›) | `_controles` | botão central = `accent` |

**#3 vs #11 (Spacer 2:3):** sobem/descem o bloco todo. Mais peso embaixo (3) = bloco um pouco
**mais pra cima**. Quer subir mais → aumenta o de baixo ou diminui o de cima.

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
**empurra o rótulo pra fora do círculo por cima** e o subtexto **por baixo**. Apertar pra 0.78 (+
gaps 3px) puxa os dois pra perto do número, **dentro** do anel. Se aumentar a fonte do número,
reavaliar esse 0.78.

## Contador de repetições — semântica (0-based)

Mostra **repetições CONCLUÍDAS**: `'${f.rep - 1}/${f.totalReps}'`. Começa em **0/N**, vai até
**(N-1)/N**; ao fechar a última, a série encerra (o "N cheio" **não** fica girando na tela). O
fim da série é sinalizado pelo som + carimbo "Série X/Y ✓". `f.rep` é 1-based no modelo
(`fase.dart`, laço `for r=1..reps`), por isso o `-1`.

## Cores das fases (semânticas, `AppColors`)

| Fase | Cor | Hex |
|------|-----|-----|
| Preparação | `prep` verde claro | `#5DE0A0` |
| Execução | `exec` laranja | `#FF9538` |
| Descanso | `rest` azul claro | `#5B9CFF` |
| Marca/ação (accent) | âmbar (padrão) | `#F5A524` |

## Cheat-sheet dos "botões de ajuste" mais pedidos

- **Número maior/menor** → fonte 244 (mexer junto no `height 0.78` e na largura 270 do FittedBox).
- **Amarelo maior/menor** → fonte 40 + altura reservada 60.
- **Amarelo mais/menos redondo** → `radius 999` (pílula) ↔ menor.
- **Mais/menos espaço amarelo↔anel** → `SizedBox 22` (#7).
- **Bloco mais pra cima/baixo** → Spacer `2:3` (#3/#11).
- **Nome maior/menor ou caixa diferente** → pílula `surface2`, radius 14, fonte 20.
