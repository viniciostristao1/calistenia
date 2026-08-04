# Ideias & planos futuros

Fila pós-MVP. Melhorar aos poucos, guiado pelo uso real. Cada item com status.

## ⭐ Motivação / desempenho — A DISCUTIR (pedido do usuário 2026-08-04)
O usuário perguntou que ideias aumentariam a motivação/desempenho. Ele já tem os 2 pilares:
**assiduidade** (Check-in) e **evolução** (Progressão) + fundos motivacionais. Quer discutir
e ser lembrado destas. Ordem de recomendação do Claude:
1. **🔥 Sequência de dias ("streak")** — *recomendada p/ começar*: mais impacto, reusa os
   check-ins que já existem. Mostrar "N dias seguidos" grande no topo do Check-in. Medo de
   "quebrar a corrente" = motivador forte. `[A DISCUTIR — provável 1ª]`
2. **🏆 Recorde pessoal na Progressão** — ao registrar valor maior que todos, celebrar
   ("Novo recorde! 15 flexões"). Desafio de superação. `[A DISCUTIR]`
3. **🎯 Meta semanal** — "treinar N dias/semana" + barra de progresso da semana. `[A DISCUTIR]`
4. **📊 Estatísticas de conquista** — total de treinos, tempo total treinado, dias ativos.
   Senso de investimento acumulado. `[A DISCUTIR]`
5. **🎖️ Frase motivacional** — frase curta (estilo disciplina/quartel) na home ou fim do
   treino; combina com as fotos de soldados. `[A DISCUTIR]`
6. **🏅 Medalhas/conquistas** — badges (10 treinos, 30 dias seguidos, 100 reps num dia…).
   Gamificação leve. `[A DISCUTIR]`

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
