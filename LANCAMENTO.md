# Pacote de lançamento — Play Store (Calis Timer)

Tudo pronto pra preencher o Google Play Console. **Copie e cole daqui.** Criado em 2026-09-17
(v0.84.0). Mesmo padrão do Save List / CarLog.

> **Como ler:** em cima = **material** pra colar; embaixo (**"② No Play Console"**) = roteiro
> do que **só você faz** logado. Eu (Claude) preparo os arquivos; você faz os cliques.

---

## ⭐ Build a subir (o AAB)

A Play Store recebe um **AAB**, não o APK. O CI do Calis Timer fazia só APKs; criei um
workflow **`build-aab.yml`** (sob demanda) que gera o **AAB assinado** e o anexa ao Release da
versão atual (o "latest").

- **Arquivo:** `app-release.aab` (te entrego renomeado como `CalisTimer-v0.84.0.aab`).
- **Versão embutida:** `versionName 0.84.0`, `versionCode 118`. (Cada nova subida à Play precisa
  de versionCode maior.)
- **Assinatura:** chave de upload oficial (SHA-1
  `6B:33:2E:7E:E7:2E:03:C3:D2:8F:72:CC:04:8B:29:E6:67:45:92:6A`) — a mesma registrada no
  Firebase, login Google segue funcionando.
- **De onde sai (repo é PÚBLICO → baixa SEM login):**
  `https://github.com/viniciostristao1/calistenia/releases/latest/download/app-release.aab`
  (gerado por `gh workflow run build-aab.yml`).

> ⚠️ **O 🧪 Laboratório de Animações NÃO vai no AAB da Play** — é ferramenta de dev, escondida
> atrás do flag `LAB` (só o APK de teste do GitHub o mostra). Ver `ANIMACOES.md`.

---

## Identidade da ficha

| Campo | Valor |
|---|---|
| **Nome do app (≤30):** | `Calis Timer: treino calistenia` *(alt. curta: `Calis Timer: calistenia`)* |
| **Nome no ícone (launcher):** | `Calis Timer` |
| **Package (permanente):** | `com.vinyapps.calistenia` |
| **Categoria:** | Saúde e fitness (Health & Fitness) |
| **Tags/keywords:** | calistenia, treino em casa, cronômetro de treino, intervalado, HIIT, timer |
| **Monetização:** | Grátis · sem anúncios · sem compras no app |
| **E-mail de contato:** | viniciostristao@gmail.com |
| **Idiomas:** | App em **PT/EN/ES** e **segue o idioma do aparelho** (desde v0.84.0). Ficha da loja começa em PT; fichas EN/ES depois (opcional). |

## Descrição curta (≤80 caracteres)
```
Cronômetros para seus treinos de calistenia: monte, treine e acompanhe a evolução.
```

## Descrição completa (≤4000 caracteres)
```
Calis Timer é o cronômetro dos seus treinos de calistenia. Monte seus treinos, toque em iniciar e o app conduz cada série no tempo certo — você só treina.

Como funciona:
• Monte treinos por dia da semana, com os exercícios e nomes que você quiser.
• Para cada exercício, defina séries, repetições, ritmo por repetição, preparação e descanso.
• Ao iniciar, o app roda a sequência: preparação → execução → descanso, com anel colorido, contagem regressiva, vibração nas transições e a tela sempre ligada.
• Pause, pule ou volte etapas a qualquer momento.

Acompanhe sua evolução:
• Check-in: um calendário mostra os dias treinados e insígnias do mês.
• Progressão: gráficos da evolução das suas repetições por exercício.
• Sons e vibração configuráveis; temas escuros (âmbar/azul).

Funciona 100% offline. Se quiser, entre com o Google para sincronizar seus treinos entre aparelhos. Disponível em Português, Inglês e Espanhol (segue o idioma do seu celular). Sem anúncios.
```

---

## Materiais gráficos (em `store/`)

| Item | Especificação | Status |
|---|---|---|
| **Ícone** | 512×512 PNG | ✅ `store/icon_512.png` |
| **Feature graphic** | 1024×500 PNG | ✅ `store/feature_graphic.png` |
| **Screenshots (telefone)** | 2–8 (a Play aceita **até 8**), PNG s/ alpha, ≤2:1 | ✅ 6, formatados |

**Screenshots** em `store/screenshots/` (app atual, ≈1,98:1 RGB) — ordem sugerida:
1. `01-treinos.png` — home: treino do dia + iniciar
2. `02-cronometro.png` — **o cronômetro rodando** (anel de execução, série, "a seguir") — a tela principal
3. `03-editar-treino.png` — montar treino (dias + exercícios)
4. `04-editar-exercicio.png` — séries/reps/ritmo/preparação/descanso
5. `05-progressao.png` — gráficos de evolução das repetições
6. `06-checkin.png` — calendário de assiduidade + insígnias do mês

> Crus em `store/screenshots/originais/`. Trocar/reordenar screenshots é edição de ficha (não
> exige novo AAB nem reinicia o teste de 14 dias).

---

## Data Safety (Segurança dos dados) — respostas prontas

**O app coleta ou compartilha dados?** Coleta (só se você usar o login); não compartilha.

| Dado | Coletado? | Obrigatório? | Finalidade | Origem |
|---|---|---|---|---|
| **E-mail** | Sim (se logar) | Opcional | Login / conta | Login Google |
| **Nome** | Sim (se logar) | Opcional | Conta | Login Google |
| **Conteúdo do app** (treinos, check-ins, progressão) | Sim (se logar/sync) | Opcional | Funcionalidade | Criado pelo usuário |

- **Localização, câmera, contatos, fotos:** não coleta.
- Dados **criptografados em trânsito**? **Sim** (HTTPS/Firebase).
- Usuário pode **pedir exclusão**? **Sim** (apaga no app + por e-mail).
- **Compartilhados com terceiros**? **Não.** Coleta p/ **publicidade**? **Não.** App p/ **crianças**? **Não.**

## Classificação de conteúdo (IARC) — respostas prontas
Categoria: **Saúde e fitness / utilitário** (não é jogo). Responder **NÃO** a violência, sexo,
linguagem, drogas, jogos de azar, medo. Sem conteúdo de usuários exibido publicamente. →
Resultado esperado: **Livre / Classificação L**.

## ⚠️ Permissão sensível: alarmes exatos (lembretes)
O app usa **USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM** para lembretes de treino no horário certo.
No Console pode aparecer a **declaração de "alarmes exatos"** — justifique que é app de
**lembretes/agenda de treinos**. Caso de uso permitido; só declarar.

## Política de privacidade e Termos
- **Política (obrigatória):** https://viniciostristao1.github.io/calistenia-privacidade/
- **Termos de uso (opcional, já criados):** https://viniciostristao1.github.io/calistenia-privacidade/termos.html
- Repo público `viniciostristao1/calistenia-privacidade` (GitHub Pages).

---

## ② No Play Console — passo a passo (o que só VOCÊ faz)

Pré-requisito ✅: conta de desenvolvedor paga **e aprovada** (a mesma dos outros apps).

1. **Criar o app** — nome `Calis Timer: treino calistenia`, idioma Português (Brasil), **App**, **Grátis**.
2. **Ficha da Store** — colar nome, descrições; subir **ícone 512**, **feature graphic** e os **5 screenshots**.
3. **App content** — política de privacidade (URL); **sem anúncios**; acesso ao app (funciona
   offline, login opcional); classificação (respostas acima → Livre); público-alvo 13+/adultos;
   **Data safety** (tabela acima); **permissões sensíveis (alarmes exatos)**; governo/finanças/saúde: Não.
4. **Teste fechado** — criar faixa, subir o **AAB**, ≥12 testadores por 14 dias seguidos → então "Solicitar acesso à produção".
5. **Produção** — criar release → subir o AAB → notas → enviar para revisão.

> 💡 Aceite o **Play App Signing** ao subir o 1º AAB.

---

## Backup da chave
- **Keystore de upload** entregue ao usuário (`CalisTimer-upload-keystore.jks`) **com a senha**
  (está no `key.properties` local). Guarde em lugar seguro — é o que assina as atualizações.

## Monetização — DECIDIDO (2026-09-17)
- Lança **grátis, sem anúncios**. **Premium = desbloqueio ÚNICO vitalício ~R$ 19,90** (não
  assinatura), igual ao Save List. Features Premium: **temas extras**, **estatísticas avançadas
  de progressão**, **treinos/pastas ilimitados**, **backup automático**. Entra em **atualização**,
  sem refazer o teste de 14 dias (Play Billing só testa após o app numa trilha). Plano em `IDEIAS.md`.

## Futuro — App Store (iOS)
- Conta Apple Developer (US$99/ano) + Mac (ou build em nuvem) + ícones/prints padrão Apple +
  Firebase iOS. Fase depois do Android.
