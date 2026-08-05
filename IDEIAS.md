# Ideias & planos futuros

Fila pós-MVP. Melhorar aos poucos, guiado pelo uso real. Cada item com status.

## ⭐ Motivação / desempenho — A DISCUTIR (pedido do usuário 2026-08-04)
O usuário perguntou que ideias aumentariam a motivação/desempenho. Ele já tem os 2 pilares:
**assiduidade** (Check-in) e **evolução** (Progressão) + fundos motivacionais. Quer discutir
e ser lembrado destas. Ordem de recomendação do Claude:
1. **🔥 Sequência de dias ("streak")** — `[FEITO v0.22.0]` streak por dias agendados no topo
   do Check-in (teaser) e na galeria de Conquistas.
2. **🏆 Recorde pessoal na Progressão** — ao registrar valor maior que todos, celebrar
   ("Novo recorde! 15 flexões"). Desafio de superação. `[A DISCUTIR]` (o dado de recorde já é
   usado no Troféu de Ouro; falta a celebração dedicada.)
3. **🎯 Meta semanal** — "treinar N dias/semana" + barra de progresso da semana. `[A DISCUTIR]`
4. **📊 Estatísticas de conquista** — total de treinos, tempo total treinado, dias ativos.
   Senso de investimento acumulado. `[A DISCUTIR]` (total de dias concluídos já aparece na galeria.)
5. **🎖️ Frase motivacional** — `[FEITO v0.22.0]` 15 frases no fim de treino não concluído.
6. **🏅 Medalhas/conquistas** — `[FEITO v0.22.0]` 🥈/🥇 (sequência) + 🏆/👑 (marcos), galeria
   na aba Check-in.

## 🎮 Gamificação + conclusão de treino + modo unilateral — `[FEITO v0.22.0→v0.23.0]` (2026-08-04)
Implementado conforme o plano abaixo (mantido como registro do desenho). Detalhe técnico em
`APRENDIZADOS.md § v0.22.0` e `§ v0.23.0`. Decisões travadas: streak = **dias agendados**;
Ouro = **21 dias + recorde em ≥50% (ceil) dos exercícios distintos**, oculto/surpresa;
gamificação = toggle global em Config (ligado por padrão).
**Refino v0.24.0 (final do modelo):** TODAS as conquistas são por **sequência de dias
agendados** — 🥈4 · 🥇8 · 🏆Prata15 · 🏆Ouro21 seguidos; pular um dia agendado derruba todas.
O Ouro exige ainda progressão em ≥50% dos exercícios nos últimos 21 dias (cai por estagnação).
Sem coroa (dois troféus prata/ouro, ícone tintado) e sem "surpresa"/oculto. Galeria: "Sequência
atual" (dá prêmio) + "🏅 Recorde" (melhor sequência de todos os tempos, permanente) + regras
com "Sequência: X/N". `conquistas_v1` guarda a 1ª obtenção (calendário/celebração) + `perdidaEm`;
"atuais" recalcula ao vivo (`conquistasAtuais`). **v0.25.0:** barras de progresso nos cards;
sub-aba **Histórico** (perdidas por mês da perda, via `perdidaEm`+`reconciliar`); novo ícone do
app; botão voltar no editor. **Ouro = dinâmico confirmado** pelo usuário (reaparece ao voltar a
progredir; só aparece com todas as anteriores ativas + progressão nos 21 dias).
Evoluções possíveis: animação/confete ao desbloquear; recorde pessoal (PR) por exercício como
conquista própria; meta semanal; estatísticas de tempo total; lembrete "você está a 1 dia de
perder a sequência".

### A. Modo unilateral (um braço/perna por vez) — `[FEITO]`
Alguns exercícios são por LADO (flexão um braço, agachamento uma perna). Sequência por
**série**: **preparação → execução (lado 1) → preparação → execução (lado 2) → descanso**
(dois prep+exec seguidos; UM descanso só no fim da série).
- Modelo: `bool unilateral` no `Exercicio` (default `false`); toggle no editor do exercício
  ("Um lado por vez").
- `montarLinhaDoTempoDe` (`models/fase.dart`): quando `unilateral`, expande cada série em
  lado 1 e lado 2 (cada lado = prep + execução×reps); descanso só no fim. Reusa
  `preparacaoSeg` como "troca de lado" (sem campo novo).
- `Fase` ganha `lado` (0=n/a, 1, 2) → player mostra "Lado 1 de 2". Sem descanso entre lados.

### B. Conclusão de treino (portão da gamificação) — `[FEITO]`
No fim do player ("Treino concluído"), perguntar **"Você completou o treino?"** (todas as
reps). Separa DOIS conceitos que hoje são um só:
- **Check-in (assiduidade)** = continua automático por exercício → SEMPRE marca o dia
  (apareceu conta). Treino incompleto ainda é pontinho no calendário.
- **Conclusão (gamificação)** = só o "sim" avança streak/medalhas/troféus. Registro NOVO a
  nível de treino (distinto do check-in por exercício).
- "Não" → frase motivacional aleatória (lista C), sem punição.
- Toggle global "Gamificação on/off" em Config. (Gamificar por-exercício não mapeia nas
  medalhas; futuro: marcar exercício como "não conta p/ conclusão" — aquecimento.)

### C. Frases motivacionais (treino NÃO completo) — sortear aleatório
1. "Faz parte do processo. O importante é não parar!"
2. "Cada tentativa te deixa mais perto da meta. Siga firme!"
3. "Falhar hoje significa que você se desafiou de verdade."
4. "Não deu hoje, mas o progresso continua acumulando."
5. "Guerreiros também têm dias difíceis. Levante a cabeça!"
6. "Amanhã você estará mais forte do que hoje. Pode apostar!"
7. "A consistência é feita de dias bons e dias difíceis. Continue!"
8. "Hoje você construiu base. Amanhã você supera."
9. "Sem pressa, mas sem pausa. O resultado vem!"
10. "O único treino ruim é aquele que não acontece. Parabéns pela tentativa!"
11. "A queda de hoje é a base da sua evolução de amanhã."
12. "Orgulhe-se de ter tentado. Poucos têm essa coragem!"
13. "Dias cinzas também fazem parte da jornada. Foco no objetivo!"
14. "Seu corpo aprendeu algo novo hoje, mesmo sem você perceber."
15. "Ajuste o foco, até a próxima melhor sessão!"

### D. Medalhas & troféus — regras DEFINIDAS (2026-08-04)
Dois eixos: **medalhas = constância seguida (streak)**; **troféus = marcos permanentes**.
- **Streak = DIAS AGENDADOS completados** (decidido): a corrente conta os dias em que há
  treino marcado (`Treino.dias`); completar o treino agendado mantém a corrente, e um dia
  SEM treino agendado NÃO quebra. Vale p/ as medalhas 4/8 também.
- 🥈 Medalha de Prata — 4 dias agendados completados seguidos.
- 🥇 Medalha de Ouro — 8 dias agendados completados seguidos.
- 🏆 Troféu de Prata — 15 dias de treino (frequência ACUMULADA, não precisa ser seguida).
  Mostra progresso ("faltam X dias").
- 🏆 Troféu de Ouro — **difícil + SURPRESA**: **21 dias agendados completados (acumulado) +
  progressão (recorde pessoal) em ≥ 50% dos exercícios**. O peso da dificuldade está no 50%
  com recorde (não no 21, que herda do Prata). **Regra OCULTA na galeria** (card bloqueado
  "🏆 ???", SEM barra de progresso); revelada só ao conquistar.
  - Defaults a confirmar na implementação: "exercícios" = exercícios DISTINTOS que aparecem
    nos treinos; "progressão" = novo recorde de reps em `RegistroProgressao` (supera o melhor
    anterior daquele exercício, lifetime); **50% arredonda p/ CIMA (ceil)**.

### E. Onde colocar (sala de troféus) — recomendação: HÍBRIDO
Aba **Check-in** com segmented control no topo: **[Calendário] [Conquistas]**.
- Calendário: calendário atual + faixa compacta das últimas conquistas abaixo (teaser).
- Conquistas: galeria completa (medalhas + troféus do ano).
- Mantém a Progressão limpa (barras já são altas). Última opção = abaixo da Progressão.

## Curto prazo (prováveis próximas)
- ~~**Som/bip nas transições e no fim.**~~ `[FEITO v0.14→v0.20]` — `audioplayers` +
  WAV próprios (`assets/sounds/`); modo baixa latência + **pool de 5 players** (o reuso de 1
  player falhava nas repetições rápidas). Fim de série toca som diferente. On/off em Config.
  ⚠️ **áudio só validável no aparelho** — se ainda falhar, plano B = `flutter_soloud`.
- **Descanso entre exercícios** como etapa própria (hoje o descanso do exercício cobre o
  intervalo). Avaliar se vale separar. `[EM DISCUSSÃO]`
- **Duplicar treino / duplicar exercício** (montar variações rápido). `[A FAZER]`
- ~~**Ícone do app** (logo próprio via `flutter_launcher_icons`).~~ `[FEITO v0.3.0]` —
  cronômetro minimalista azul, arte em `tools/gerar_icone.py`.
- **Ajustes finos do player:** confirmar antes de sair no meio do treino; botão de
  "adicionar +10s" na fase atual; manter a tela na horizontal opcional. `[A FAZER]`

## Feito recentemente
- ~~**Login com Google + sincronização (Firestore).**~~ `[FEITO v0.16→v0.21]` — projeto
  `calis-timer`; `firebase_auth`/`google_sign_in`/`cloud_firestore`; `sync_service.dart`
  (união por id no 1º sync + LWW; guard `_ultimoSync` corrigiu um LOOP na v0.21). Ver
  `FIREBASE.md`. Possível evolução: indicador de "sincronizado"; conflito 2-devices-offline.
- ~~**Imagem de fundo motivacional** no cronômetro.~~ `[FEITO v0.20→v0.21]` — **por
  exercício**; 8 fotos em `assets/fundos/`; seletor no editor do exercício.
- ~~**Aba "Check-in"** (calendário de assiduidade).~~ `[FEITO v0.10.0]` — automático ao
  terminar cada exercício + edição manual no dia. Possíveis evoluções: sequência
  ("streak") de dias seguidos, metas semanais, ver a assiduidade na Progressão.
- ~~**Aba "Progressão"** com gráfico de barras da evolução por exercício.~~
  `[FEITO v0.6.0]` — métrica = repetições feitas (digitável), registro no editor do
  exercício. Possíveis evoluções: registrar ao concluir o treino; escolher métrica
  (tempo/séries); "sugestões" (ex.: "tente +1 na próxima").

## Médio prazo
- **Tempo total decorrido / estimado restante** do treino inteiro no player.
- **Histórico**: registrar treinos concluídos (data, duração). `[IDEIA]`
- **Reordenar treinos** na home e/ou agrupar por dia com "hoje" no topo.
- **Modelos prontos** (templates) de treinos de calistenia para começar rápido.
- **i18n (inglês)** para a Play Store internacional.

## Longo prazo / Play Store
- **Publicar na Play Store** (seguir o padrão do `lista_app`: conta de desenvolvedor,
  keystore de upload via secrets, AAB, ficha, política de privacidade, teste fechado).
- **Backup/sync opcional na nuvem** (só se o usuário pedir; hoje é local por design).
- **Nome/branding definitivo** ("Calistenia" é provisório).
- **Monetização:** decidir (provável: grátis, sem anúncios).
