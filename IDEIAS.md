# Ideias & planos futuros

Fila pós-MVP. Melhorar aos poucos, guiado pelo uso real. Cada item com status.

## Curto prazo (prováveis próximas)
- **[TOP] Som/bip nas transições e na contagem 3-2-1.** Hoje só vibração +
  `SystemSound.alert` (pode ser mudo em alguns aparelhos). Bip real audível ajuda a não
  olhar a tela. Precisa de um pacote de áudio (`audioplayers`/`soundpool`) + assets de
  bip; pesa um pouco no build. `[A FAZER]`
- **Descanso entre exercícios** como etapa própria (hoje o descanso do exercício cobre o
  intervalo). Avaliar se vale separar. `[EM DISCUSSÃO]`
- **Duplicar treino / duplicar exercício** (montar variações rápido). `[A FAZER]`
- ~~**Ícone do app** (logo próprio via `flutter_launcher_icons`).~~ `[FEITO v0.3.0]` —
  cronômetro minimalista azul, arte em `tools/gerar_icone.py`.
- **Ajustes finos do player:** confirmar antes de sair no meio do treino; botão de
  "adicionar +10s" na fase atual; manter a tela na horizontal opcional. `[A FAZER]`

## Feito recentemente
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
