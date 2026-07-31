# Aprendizados (diário técnico + lições)

Diário técnico do projeto. Cada bloco de trabalho anexa aqui: o que foi feito, decisões
e **gotchas** (para não repetir). Ler antes de mexer em build/assinatura/plugins.

---

## 2026-07-30 — Bootstrap do projeto (v0.1.0)

**Contexto:** app novo de cronômetros de calistenia, espelhando as convenções do
`lista_app` (Flutter, docs `INICIO/ATUALIZACOES/APRENDIZADOS/IDEIAS`, build de APK na
nuvem). Pasta isolada `/root/calistenia_app/`, app em `app/`.

**Decisões de arquitetura:**
- **Sem Firebase/login.** É um cronômetro pessoal → dados **locais** com
  `shared_preferences` (JSON de `List<Treino>`). Zero fricção de login, build mais
  simples, e sem a saga de SHA-1/OAuth que o lista_app enfrentou. Migrar p/ nuvem só se
  o usuário pedir (fica em IDEIAS).
- **Modelo de dados:** `Treino { nome, dias:[0..6], exercicios:[Exercicio] }`;
  `Exercicio { nome, preparacaoSeg, execucaoSeg, descansoSeg, repeticoes }`. Tempo em
  **0 = etapa ausente** (é assim que "excluir uma etapa, como descanso" é representado).
- **Linha do tempo** (`models/fase.dart::montarLinhaDoTempo`): expande cada exercício em
  `preparação(1×) → [execução → descanso] × reps`, pula tempos 0, e remove o descanso do
  fim absoluto. É a lista de fases que o player conta. **Testada** em `test/`.
- **Player** = `StatefulWidget` puro (sem Riverpod) com `Timer.periodic(100ms)` +
  `Stopwatch` para medir o delta real (contagem precisa mesmo se o tick atrasar). O
  "estouro" negativo de ms é carregado para a próxima fase p/ não acumular drift.
- **Persistência ao vivo:** o editor de treino salva a cada mudança (`salvar(_t)`), então
  voltar nunca perde nada. Evita fluxo de "salvar/descartar".

**Estado (Riverpod 3):** `AsyncNotifierProvider<TreinosNotifier, List<Treino>>`.
`build()` carrega do `shared_preferences`; no 1º uso (chave ausente) **semeia** um
"Treino exemplo" p/ o app não abrir vazio.

**Gotchas / notas:**
- `ReorderableListView.builder`: no Flutter 3.44 o `onReorder` está **deprecado** →
  usar **`onReorderItem`** (o `newIndex` já vem ajustado; **não** subtrair 1). Com
  `buildDefaultDragHandles: false`, o arrasto sai de um `ReorderableDragStartListener`.
- Lint `unnecessary_underscores`: em callbacks com 2 params ignorados, usar `(_, _)`
  (wildcards), não `(_, __)`.
- **Assinatura Android:** o `build.gradle.kts` gerado já usa
  `signingConfig = signingConfigs.getByName("debug")` no buildType `release`. Ou seja,
  `flutter build apk --release` gera um APK **debug-signed que INSTALA direto** no
  celular — **não precisa de keystore** para teste pessoal. Keystore de upload só na
  Play Store.
- `flutter build apk` na VPS é pesado → **build sai na nuvem** (GitHub Actions). Localmente
  dá p/ validar com `flutter analyze`, `flutter test` e `flutter build web`.
- Áudio: por ora só `HapticFeedback` (vibração) + `SystemSound.play(alert)` (best-effort,
  pode ser mudo). Bip audível de verdade fica em IDEIAS (precisa de pacote de áudio).

**Validação:** `flutter analyze` → sem issues. `flutter test` → 3/3 (linha do tempo,
pulos de tempo-0, duração total). Compilação de ponta a ponta via `flutter build web`.

---

## 2026-07-30 — Publicação: repo GitHub + APK v0.1.0 na nuvem

**Contexto:** MVP validado localmente; faltava commit (nada estava commitado) e o APK
pra instalar no celular. Espelhado o `lista_app`.

**O que foi feito:**
- 1º commit do projeto e criação do repo **privado** `viniciostristao1/calistenia`
  (`gh repo create calistenia --private --source=. --push`). Privado como o `lista_app`.
- Push na `main` (paths `app/**`) disparou o workflow **Build APK** → **CI verde** em
  ~alguns min. Artefato `calistenia-apks` (~25 MB) com 3 APKs por arquitetura.
- Criado **release `v0.1.0`** (`gh release create`) anexando os 3 APKs, pra dar link
  direto de download (mais fácil no celular que navegar "Artifacts" do Actions).
  Instalar = `app-arm64-v8a-release.apk` (Android moderno), debug-signed → instala direto.

**Gotchas / notas:**
- **`gradle-wrapper.jar` NÃO vai no repo** (é ignorado pelo `.gitignore` padrão do
  Flutter, junto de `gradlew`/`gradlew.bat`). Mesmo assim o CI builda — a
  `subosito/flutter-action` + `flutter build apk` regeneram o wrapper. Confirmado que o
  `lista_app` builda idêntico. **Não** adicionar o jar ao repo "pra garantir".
- `gh run download` / `gh release ...` **fora do diretório do repo** (ex.: rodando do
  scratchpad) exigem **`-R viniciostristao1/calistenia`**, senão dá
  "not a git repository". Alguns comandos `gh`/`git` resetam o cwd do shell.
- Editar só os `.md` da raiz **não** dispara o CI (o gatilho é `app/**` +
  o próprio workflow) — bom pra atualizar docs sem gerar build à toa.

**Release:** https://github.com/viniciostristao1/calistenia/releases/tag/v0.1.0

---

## 2026-07-30 — v0.2.0: séries + ritmo por repetição, visual navy, exercício avulso

Três melhorias pedidas pelo usuário, num lote só (1 APK).

**1) Modelo "ritmo por repetição" (decisão do usuário, entre 2 opções):**
- Nova semântica do `Exercicio`: `execucaoSeg` = tempo de UMA repetição; `repeticoes` =
  reps por série; **`series`** (campo novo) = nº de séries; `descansoSeg` = descanso
  **entre séries**. Linha do tempo: `prep(1×) → [execução×reps → descanso] × séries`.
  Não há descanso entre reps (são seguidas) — o bip a cada rep sai naturalmente da
  transição execução→execução do player (nenhuma lógica de sub-contagem nova).
- **Isométrico** (prancha) = `repeticoes: 1`, `execucaoSeg` = tempo da série → o modelo A
  generaliza o "tempo por série" sem código extra.
- **Migração automática** em `Exercicio.fromJson`: JSON antigo (sem `series`) tinha
  `repeticoes` = nº de rodadas → vira `series = antigo`, `repeticoes = 1`. Preserva o
  comportamento v0.1.0 exatamente. Mantida a chave `treinos_v1` (migração no parse, sem
  perder dados). Teste dedicado cobre isso.
- **Ajuste fino:** `_TempoLinha` ganhou `passo` (default 5); a Execução usa `passo: 1`.

**2) Visual navy:** `AppColors` reescrito — base azul-escuro + **`accent` (azul)**
separado das cores de FASE (prep/exec/rest). Regra: `accent` = marca/ação (FAB, iniciar,
seleção, botões); `exec` (verde) fica SÓ para a fase execução e o ✓ de concluído. Troca
cirúrgica de `exec`→`accent` nos pontos de ação (home, editor, player). `onAccent` virou
quase-branco (era verde-escuro, pensado p/ cima de verde).

**3) Home + exercício avulso:** `_TreinoCard` agora lista os exercícios; cada linha roda
**só aquele exercício**. `PlayerScreen` deixou de receber `Treino` e passou a receber
`{ titulo, List<Exercicio> exercicios }` (usa `montarLinhaDoTempoDe(List)`), servindo
treino inteiro e exercício avulso com o mesmo widget.

**Gotchas / notas:**
- Muitas fases: flexão 10 reps × 3 séries = 33 fases. O "Etapa X de N" cru ficaria feio →
  troquei o texto de progresso por "Exercício i/N · Série s/S" (barra continua por fase).
- Toques aninhados no card da home: cabeçalho (InkWell→editor) e ▶ grande ficam lado a
  lado (Row), sem aninhar; nas linhas de exercício o ▶ pequeno é InkWell dentro do InkWell
  da linha, mas **ambos chamam a mesma ação** (rodar o exercício), então o aninhamento é
  inofensivo.
- `duracaoTotalSeg` (resumo do card) é aproximado (inclui descanso final); o player usa a
  soma real das fases (`_duracaoTotal`, sem o descanso final). Diferença só no resumo.

**Validação:** `flutter analyze` limpo. `flutter test` → 4/4 (linha do tempo por série,
isométrico, duração, **migração v0.1.0→v0.2.0**). Versão `0.2.0+2`.

---

## 2026-07-31 — v0.3.0: cores invertidas, etapas opcionais, descanso por série, ícone

Mais três melhorias do usuário, num lote (1 APK).

**1) Cores das fases:** invertidas em `AppColors` — `prep` = verde claro (#5DE0A0),
`exec` = laranja (#FF9538); `rest` segue azul. O ✓ da tela "concluído" passou de `exec`
(que agora é laranja) para `accent` (azul), p/ não virar laranja.

**2a) Execução opcional:** `_TempoLinha` da Execução virou `removivel: true, minimo: 0`
(era `false/1`). `_salvar` agora permite `execucaoSeg = 0`. A linha do tempo já pulava
tempos 0, então execução 0 = etapa ausente sem mudança de engine. `_defaultAdd` no
`_TempoLinha` dá o valor certo ao readicionar por tipo (execução→3, descanso→60, prep→10).

**2b) Descanso por série (variável):** `Exercicio` ganhou `List<int>? descansos`
(tamanho = séries; `null` = usa o `descansoSeg` padrão) + helper `descansoAposSerie(s)`.
`montarLinhaDoTempoDe` e `duracaoTotalSeg` usam o helper. UI: `_descansoSection()` alterna
entre descanso único e N campos "Após série s" (o botão "Descanso diferente por série"
inicializa a lista com o padrão; "Um só" volta a `null`). Ao mudar séries com a lista
ativa, `_ajustarDescansos()` redimensiona. Migração: JSON sem `descansos` → `null` (compat
total). Resumo de lista centralizado em `Exercicio.resumoCurto` (usado por home e editor),
com faixa "desc 1min–1min30" quando variável e "sem execução" quando exec 0.

**3) Ícone:** arte gerada por **`tools/gerar_icone.py`** (Pillow, num venv de projeto
`tools_venv/` — fora do git). Cronômetro minimalista, gradiente vertical azul claro
(#ADDDFF→#3B82F6) sobre fundo azul escuro (#0A0F1C→#17275A), supersampling 4×. Gera
`icon_full` (legacy), `icon_background` + `icon_foreground` (adaptive). `flutter_launcher_icons`
0.14.4 gera os mipmaps/adaptive. **Gotcha:** o launcher_icons aplica **inset de 16%** no
foreground → o relógio do foreground precisa ser MAIOR (scale 0.86, centralizado cy=0.5)
p/ não sair pequeno; conferido com uma prévia PIL (bg + fg@68% + máscara circular). O
`icon_full` usa scale 0.74/cy 0.545.

**Validação:** `flutter analyze` limpo. `flutter test` → 6/6 (+ descanso variável, +
execução 0). Versão `0.3.0+3`.

---

## 2026-07-31 — v0.4.0: assinatura FIXA (fim da perda de dados) + ícone ajustado

**Causa raiz do "app abre do zero / conflito ao instalar" (bug reportado):** os APKs
v0.1.0–v0.3.0 eram assinados com a chave **debug**, e no GitHub Actions o runner é
**efêmero** → cada build gerava um `debug.keystore` com chave DIFERENTE → assinaturas
diferentes entre releases → o Android recusa atualizar por cima
(`INSTALL_FAILED_UPDATE_INCOMPATIBLE`, "conflito") → o usuário desinstala → o
`shared_preferences` some. **Não era falta de Firebase** — dados locais são por design; o
problema era a assinatura instável.

**Correção (padrão do lista_app):**
- Keystore de upload própria (`keytool`, RSA 2048, validade 10000d, alias `upload`) em
  `app/android/app/upload-keystore.jks` + `app/android/key.properties` — ambos
  **gitignored** e presentes localmente na VPS. Secrets no GitHub: `KEYSTORE_BASE64`
  (base64 do .jks) e `KEYSTORE_PASSWORD` (via `gh secret set`).
- `build.gradle.kts`: `signingConfigs.release` lê o `key.properties`; `buildTypes.release`
  usa a chave de upload se o arquivo existe, senão cai no debug (p/ `flutter run` local).
  Imports `java.util.Properties` / `java.io.FileInputStream` no topo. Estrutura idêntica ao
  lista_app (comparada linha a linha antes do push).
- Workflow: step "Assinatura de release" decodifica a keystore do secret e escreve o
  `key.properties` **antes** do `flutter pub get`/build.
- `AndroidManifest`: `allowBackup="true"` + `fullBackupContent="true"` → Android Auto
  Backup (restaura treinos em reinstalação/troca de aparelho, sem Firebase).

**⚠️ Transição inevitável:** a v0.3.0 (debug) → v0.4.0 (upload key) MUDA a assinatura →
exige UMA última desinstalação. Da v0.4.0 em diante a chave é fixa → updates por cima OK.
**A keystore é crítica** (perdê-la = não conseguir mais atualizar o app / publicar na Play
Store) → guardar backup (Drive) além da VPS.

**Ícone (ajuste do pedido):** menor (scale 0.74→0.62 full; 0.86→0.74 foreground), **botão
estilo cronômetro** no topo (haste + tampa larga) e **marcadores 12/3/6/9h**; ponteiro
encurtado p/ não bater nos marcadores. Regenerado com `tools/gerar_icone.py` +
`flutter_launcher_icons`. Conferido com prévia PIL (full + adaptive-recorte-circular).

**Validação:** código Dart inalterado desde a v0.3.0 (6/6 testes seguem válidos); a
assinatura é validada pelo build do CI. Versão `0.4.0+4`.
