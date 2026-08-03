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

---

## 2026-07-31 — v0.5.0: rename "Calis Cronômetro" + logo na home + ícone menor

- **Nome de exibição** → "Calis Cronômetro" (`AndroidManifest android:label`; o `name:` do
  pacote Dart segue `calistenia`, mudar quebraria imports). Acento no label inline (UTF-8, OK).
- **Logo dentro do app:** novo asset `assets/icon/logo.png` (transparente, relógio
  preenchendo o quadro; gerado por `gerar_icone.py`), declarado em `flutter: assets:` e
  exibido na AppBar da home via `Image.asset(height:26)` + texto "Calis Cronômetro".
- **Ícone menor:** scale full 0.62→0.56, foreground 0.74→0.68 (o usuário pediu mais margem).
- **Marco:** esta é a 1ª versão a ser instalada POR CIMA (assinatura fixa da v0.4.0) — é o
  teste real do "sem perder treinos".

**Validação:** `flutter analyze` limpo, `flutter test` 6/6. Versão `0.5.0+5`.

---

## 2026-07-31 — v0.6.0: aba Progressão (gráfico de barras da evolução)

Feature nova (design alinhado com o usuário: métrica = **repetições que você fez**,
digitável; registro **no editor do exercício**).

- **Navegação:** `RootScreen` novo com `NavigationBar` (2 abas: Treinos / Progressão) e
  `body: IndexedStack([HomeScreen, ProgressaoScreen])` — preserva o estado de cada aba;
  cada tela mantém seu próprio Scaffold (Scaffold aninhado, ok). `main.dart` passou a abrir
  `RootScreen` (era `HomeScreen`).
- **Dados:** `RegistroProgressao { exercicio(nome), valor(reps), data }` +
  `progressaoProvider` (AsyncNotifier, chave `progressao_v1` no shared_preferences).
  **Liga por NOME** (a evolução da "Flexão" acumula entre treinos). `agruparPorExercicio()`
  agrupa e ordena por data; `GrupoProgressao` expõe primeiro/último/maior.
- **Registrar:** `_ExercicioEditor` virou `ConsumerStatefulWidget`; botão "Adicionar à
  progressão" pede o valor (sugere as reps atuais, mas edita = desempenho real) e grava
  com a data de hoje. SnackBar de confirmação.
- **Gráfico:** `_GraficoBarras` desenhado com widgets puros (sem pacote de chart) — Row
  scrollável de barras com altura proporcional ao máximo; última barra em destaque; toque
  na barra remove o registro; lixeira limpa o exercício. Delta "+N" colorido.

**Gotchas:** liga por nome (nomes iguais em treinos diferentes somam — proposital; nomes
divergentes viram grupos separados). SnackBar dentro da bottom sheet pode ficar parcialmente
sob a folha (aceitável). FAB da Home fica logo acima da NavigationBar (Scaffold aninhado).

**Validação:** `flutter analyze` limpo, `flutter test` **7/7** (+ agrupamento da
progressão). Versão `0.6.0+6`.

---

## 2026-07-31 — v0.7.0: dica de edição no card + ícone menor

- **`_TreinoCard` (home):** ícone `Icons.drag_indicator` ("6 pontinhos", cor dim2) à
  esquerda do nome do treino, dentro do InkWell que abre o editor — affordance de "toque
  aqui para editar" (o usuário reconheceu os 6 pontinhos do editor). Cabeçalho virou uma
  Row [ícone · Expanded(Column[nome, resumo])].
- **Ícone do app:** cronômetro menor — `clock_mask` scale full 0.56→0.50, foreground
  0.68→0.62 (o `logo.png` da home segue 0.82). Regenerado via `gerar_icone.py` +
  `flutter_launcher_icons`.

**Validação:** `flutter analyze` limpo, `flutter test` 7/7. Versão `0.7.0+7`.

---

## 2026-08-01 — v0.8.0: barra superior, tema azul/âmbar, compartilhar, peso, cores

Lote de 6 pedidos do usuário.

- **Barra superior (home AppBar `actions`):** ⚙️ configurações, compartilhar, sair. "Sair"
  = `SystemNavigator.pop()` com confirmação.
- **Tema azul/âmbar (dinâmico):** `AppColors.accent`/`onAccent` viraram **getters
  mutáveis** (`aplicarTema(TemaApp)`), evitando trocar os 31 usos por `Theme.of(context)`.
  `temaProvider` (AsyncNotifier, `tema_v1`) persiste; `CalisteniaApp` (ConsumerWidget)
  aplica o accent e reconstrói o `ThemeData` a cada mudança. **Gotcha:** getter não é
  const → tirei `const` de 4 sites (`ColorScheme`, `NavigationDestination` list, check de
  concluído, `BorderSide`); o compilador aponta (`invalid_constant`).
- **Compartilhar (item 3):** `treinoParaTexto`/`treinosParaTexto` (usa `resumoCurto`);
  dialog com `SelectableText` + **Copiar** via `Clipboard` (padrão do lista_app, sem
  pacote novo). A barra compartilha os treinos do **dia** selecionado.
- **Peso (item 4):** `Exercicio.pesoKg` (double, 0 = sem peso). `_PesoLinha` (±2,5kg,
  digitação decimal com vírgula) no editor; entra no `resumoCurto` (`fmtPeso`) e no texto.
- **Cores (item 6):** `Exercicio.corIndex` + `AppColors.paletaExercicio` (10 cores) +
  `corExercicio(i)`. Pontinho antes do nome na home e no editor; `_SeletorCor` (10
  bolinhas) na folha de edição.
- **Gráfico base alinhada (item 5):** `_Barra` agora usa **trilho de altura fixa** com
  `mainAxisAlignment.end` → todas as bases na mesma linha; só a altura muda.
- Migração: JSON antigo sem `pesoKg`/`corIndex` → 0 (teste cobre round-trip + migração).

**Validação:** `flutter analyze` limpo, `flutter test` **8/8**. Versão `0.8.0+8`.

---

## 2026-08-01 — v0.9.0: novo ícone (referência do usuário) + ajustes

- **Ícone:** o usuário subiu uma arte de referência via GitHub (commit "Add files via
  upload", um screenshot). Recriei o desenho no `gerar_icone.py` (mantém a pipeline
  vetorial/todas as variantes) em vez de recortar o print: cronômetro azul **sólido**
  (degradê sutil #5CB6EC→#308CDC), **botão lateral NE** (`_oriented_rect`, retângulo
  radial), **ponteiro afilado** (triângulo), **sem** os marcadores 12/3/6/9h, fundo navy
  mais uniforme. Screenshot de referência removido do repo depois de usado.
- **Progressão (item 2):** altura do gráfico pela metade — `_trilho` 140→70.
- **Home (item 4):** removido o `Divider` abaixo do seletor de dias.

**Validação:** `flutter analyze` limpo, `flutter test` 8/8. Versão `0.9.0+9`.

---

## 2026-08-01 — v0.10.0: aba Check-in (calendário de assiduidade)

Design escolhido pelo usuário: **check-in automático ao terminar cada exercício** +
edição manual no calendário.

- **Dados:** `CheckIn { data(normalizada ao dia), exercicio(nome), corIndex }` +
  `checkinProvider` (AsyncNotifier, `checkin_v1`). `registrar(Exercicio)` não duplica no
  mesmo dia+nome; `adicionarManual`/`remover`; `checkinsDoDia`.
- **Automático:** `PlayerScreen` virou `ConsumerStatefulWidget`. `_talvezMarcar(ei)`
  registra o exercício quando o cronômetro **passa da última fase dele** — detectado em
  `_avancar` (troca de `exercicioIndex`) e `_finalizar` (último). `Set _marcados` evita
  repetir na sessão; se o usuário para no meio, os exercícios já concluídos ficam.
- **Calendário:** `CheckinScreen` custom (GridView 7 col), navegação de mês (‹ ›), hoje
  destacado; cada dia mostra até 4 pontinhos das cores + "+N". Toque no dia → bottom sheet
  para remover check-ins e **marcar** um exercício (escolhido entre os exercícios dos
  treinos, `_exerciciosDisponiveis`). Semana começa na segunda (`nomesDiasCurtos`).
- **Navegação:** 3ª aba no `RootScreen` (Treinos · Check-in · Progressão).

**Validação:** `flutter analyze` limpo, `flutter test` **9/9** (+ modelo/filtro de
check-in). Versão `0.10.0+10`.

---

## 2026-08-02 — v0.11.0: ícone âmbar (estilo lista_app), tema padrão âmbar, limpezas

- **Ícone (item 2):** estilo lista_app — cronômetro **preto sólido** (`CLOCK_BLACK`
  #1A1A1A) sobre **âmbar degradê** (#F2BE54→#DB9838); desenho menor e mais p/ baixo (full
  scale 0.50→0.46/cy 0.55; fg 0.62→0.58). `compor()` ganhou `clock_color`. O `logo.png` da
  home passou a ser **âmbar** (`LOGO_AMBER`, transparente, visível sobre o navy).
- **Âmbar oficial (item 2):** `AppColors._accent` default → âmbar; `temaProvider` default →
  âmbar (só azul se o usuário escolher); `main` fallback → âmbar. Azul segue como opção.
- **Delay do tema (item 4):** era a animação padrão de `ThemeData` do MaterialApp
  (`themeAnimationDuration` ~200ms) — some com `themeAnimationDuration: Duration.zero`.
  (A maioria dos widgets usa `AppColors.accent` (getter, instantâneo); zerar a animação
  alinha tudo.)
- **Progressão (item 3):** removido o texto "de X → Y reps"; ficou nome + `_DeltaChip`.

**Validação:** `flutter analyze` limpo, `flutter test` 9/9. Versão `0.11.0+11`.

---

## 2026-08-02 — v0.12.0: tela de login preparada (sem Firebase ainda)

Decisão do usuário para o item 1 (login Google): **"deixar a tela pronta"** — UI agora,
integração real quando o Firebase for configurado.

- `ConfigScreen` ganhou a seção **"Conta"** + botão **"Entrar com Google"** (`_BotaoGoogle`,
  visual) que por ora mostra um SnackBar "em breve". **Sem** `firebase_auth`/`google_sign_in`
  (não adiciona plugin nem quebra o build sem o `google-services.json`).
- **SHA-1 da keystore de upload** (para registrar no Firebase quando for a hora):
  `6B:33:2E:7E:E7:2E:03:C3:D2:8F:72:CC:04:8B:29:E6:67:45:92:6A`.
- Para ativar de verdade: usuário cria projeto/app no Firebase e envia o
  `google-services.json`; então adiciono os pacotes, o gate de auth e o entrar/sair reais
  (ver IDEIAS). Login ≠ sync de dados (sync é etapa à parte).

**Validação:** `flutter analyze` limpo, `flutter test` 9/9. Versão `0.12.0+12`.

---

## 2026-08-02 — v0.13.0: correção do tema (raiz), som, layout, ícone

- **Bug do tema (item 6) — causa raiz:** `AppColors.accent` era **getter estático
  mutável** setado no build do MaterialApp. Os widgets que o liam **não eram dependentes
  do tema** (não usavam `Theme.of`), então só pegavam a cor nova quando algo os fazia
  rebuildar (ao clicar) → o "delay/atualiza conforme clico". **Fix definitivo:** removido
  o getter mutável; `buildAppTheme(TemaApp)` define `colorScheme.primary/onPrimary`;
  extension `context.accent`/`context.onAccent` (= `Theme.of(context).colorScheme.*`).
  Migrados os 31 usos em 7 telas (`AppColors.accent`→`context.accent`) via sed (os arquivos
  não usavam as constantes `accentAzul/Ambar`, então seguro). Agora o tema propaga na hora
  via InheritedWidget, sem recriar a árvore (mantém estado). **Lição:** cor de tema
  dinâmica tem de vir do `Theme`/InheritedWidget, não de estado global.
- **Dias (item 1):** `_SeletorDias` deixou de rolar — `Row` com cada dia em `Expanded`
  (largura flexível), `_DiaPill` sem `width` fixo.
- **Som (itens 4/7):** `somProvider` (bool, `som_v1`, padrão ligado) + `SwitchListTile` em
  Configurações. Player gate: `_tocarSom()` só toca `SystemSound` se ligado; som de fim
  adicionado no `_finalizar`. (Sem pacote de áudio; `SystemSound.alert`.)
- **Outros:** "Treino concluído"→"**Check-in concluído**" (item 3); fonte do contador
  76→**104** (item 8); gap título↔barras na Progressão reduzido + IconButton compacto (item
  2); meses **Capitalizados** (item 5); fundo do ícone âmbar mais escuro
  #DFAF4D→#C58932 (item 9).

**Validação:** `flutter analyze` limpo, `flutter test` **9/9**. Versão `0.13.0+13`.

---

## 2026-08-02 — v0.14.0: som real (audioplayers) + ajustes

- **Som (item 8) — causa:** `SystemSound.play(alert)` é best-effort no Android e
  normalmente **não toca**. Fix: pacote **`audioplayers ^6.8.1`** + bips WAV próprios
  gerados por Python (`wave` stdlib) em `assets/sounds/` (`beep.wav` transição, `fim.wav`
  dois tons). `PlayerScreen` tem um `AudioPlayer` (ReleaseMode.stop); `_tocarSom(asset)`
  toca gated pelo `somProvider`; disposto no dispose. **Risco:** plugin nativo novo — o
  build do CI valida (minSdk 21 OK p/ audioplayers 6).
- **Contador (item 1):** 104→**128**, dentro de `FittedBox(scaleDown)` (largura 210) p/ 3
  dígitos não estourarem o anel.
- **Add à progressão no fim (item 2):** `_AddProgressaoSheet` (folha com um campo por
  exercício, pré = reps) entre "Repetir treino" e "Voltar"; serve treino completo e avulso.
- **Reusar exercício (item 6):** `Exercicio.duplicar()` (cópia com id novo); botão
  "Adicionar de exercícios já salvos" no editor lista os distintos (por nome) de todos os
  treinos e adiciona a cópia.
- **Outros:** ícones nos títulos das abas Check-in/Progressão (item 3); `hintStyle` fraco
  (dim2) + "Novo treino" vira hint/placeholder neutro (nome default '' + card em cor dim)
  (item 4); value box dos steppers 84→52 (item 5); barras da progressão 28→14 de largura
  (item 7).

**Validação:** `flutter analyze` limpo, `flutter test` **9/9**. Versão `0.14.0+14`.

---

## 2026-08-03 — v0.15.0/v0.16.0: rename "Calis Timer" + login com Google (Firebase)

- **v0.15.0 — rename:** só nome de EXIBIÇÃO → "Calis Timer" (`android:label`, título da home,
  `MaterialApp.title`, texto do compartilhar). **`applicationId`/package
  `com.vinyapps.calistenia` INALTERADO** (Firebase/Play Store se registram por ele).
- **v0.16.0 — login Google (Firebase), projeto `calis-timer`:** seguiu o lista_app.
  - Deps: `firebase_core ^4.12.1`, `firebase_auth ^6.5.6`, `google_sign_in ^7.2.0`.
  - `firebase_options.dart` (Android; gitignored) + `google-services.json` em
    `app/android/app/` (gitignored). Secrets no GitHub: `GOOGLE_SERVICES_JSON`,
    `FIREBASE_OPTIONS_DART` (base64); workflow os restaura antes do build.
  - Gradle: `com.google.gms.google-services` (settings `version "4.5.0" apply false` + app
    aplica). **`minSdk` 21→23** (firebase_auth exige Android 6.0+).
  - `auth_service.dart`: `google_sign_in 7.x` — `GoogleSignIn.instance.initialize(
    serverClientId: <web client type 3>)` → `authenticate()` → `idToken` →
    `GoogleAuthProvider.credential` → `signInWithCredential`. `authStateProvider`
    (StreamProvider<User?>). `main` faz `Firebase.initializeApp`.
  - UI: `_SecaoConta` em Configurações (entrar / avatar+nome+email / sair).
  - **Gotcha do setup:** 1º `google-services.json` veio com `oauth_client: []` (faltava o
    SHA-1 no app + habilitar Google no Authentication). Só depois de ambos o arquivo trouxe
    o Android client (type 1, com o SHA-1) e o **Web client (type 3 = serverClientId)**.
  - **Login ≠ sync:** só autentica; sincronizar treinos (Firestore) é etapa futura.
  - **SHA-1 usado:** o da keystore de upload. Play App Signing exigirá o SHA-1 do Google também.

**Validação:** `flutter analyze` limpo, `flutter test` 9/9. **Risco:** Firebase nativo — o
build do CI é o teste real. Versão `0.16.0+16`.

---

## 2026-08-03 — v0.17.0: sincronização (Firestore)

- **Dep:** `cloud_firestore ^6.7.1`. Banco `calis-timer` (São Paulo, produção); regras em
  `firestore.rules` (cada uid só acessa `users/{uid}`), aplicadas no console pelo usuário.
- **Modelo na nuvem:** doc `users/{uid}` com campos `treinos`/`checkins`/`progressao` = o
  MESMO JSON do shared_preferences (reusa toJson) + `updatedAt`. Reusou as chaves dos repos,
  tornadas públicas (`chaveTreinos`/`chaveCheckin`/`chaveProgressao`).
- **`SyncController` + `syncProvider`** (`sync_service.dart`), ativado por
  `ref.watch(syncProvider)` no app:
  - Observa `authStateProvider`: `start(uid)`/`stop()`.
  - **Pull:** `snapshots()` do doc. **1º snapshot** = UNIÃO por id (nuvem vence conflito,
    itens só-locais preservados) → grava nos prefs + `invalidate` dos 3 providers + push do
    resultado. Snapshots seguintes = aplica remoto (LWW por doc).
  - **Push:** `ref.listen` nos 3 providers → `onLocalChange()` (debounce 800ms) → `set(...,
    merge:true)`.
  - **Anti-loop:** ignora snapshots com `metadata.hasPendingWrites` (eco das próprias
    escritas); flag `_aplicandoRemoto` bloqueia push durante a aplicação do remoto.
  - **Gotcha Riverpod:** `ref.listen` só no build do provider (não dentro de `start()`); o
    controller só guarda a subscription do Firestore.
- **Offline:** persistence nativa do cloud_firestore (cache) → funciona offline e reenvia.
- **Limitação (comunicada):** LWW por documento — edições simultâneas offline em 2 aparelhos:
  a última a sincronizar sobrescreve. Aceitável p/ uso pessoal.

**Validação:** `flutter analyze` limpo, `flutter test` 9/9. **Risco:** Firestore nativo +
regras — testar com o banco criado. Versão `0.17.0+17`.

---

## 2026-08-03 — v0.18.0: som corrigido + fim de série + desfazer + fonte

- **Bug do som (item 1) — causa:** `AudioPlayer.play(AssetSource(...))` **recarrega o asset
  a cada chamada** → em transições automáticas rápidas (reps de poucos segundos) a latência
  fazia o som falhar (funcionava só no skip manual, mais espaçado). **Fix:** **2 players
  pré-carregados** (`_beep`, `_fim`) com `setSource` + `PlayerMode.lowLatency`; tocar =
  `seek(0)+resume()` (instantâneo). Fallback `play()` enquanto o pré-load não terminou.
- **Som de fim de série (item 1):** no `_avancar`, se a fase que termina é execução com
  `rep == totalReps` (última rep da série) → toca `_fim` (som do fim do treino); senão
  `_beep`. Diferencia "executar" de "terminou".
- **Desfazer (item 2):** `SnackBarAction "Desfazer"` (3s) em `_excluirExercicio`
  (re-insere no índice original) e `_excluirTreino` (re-salva via notifier+messenger
  capturados antes do pop). Guard `if (ok != true || !mounted) return;` p/
  use_build_context_synchronously.
- **Fonte (item 3):** contador 128→150 (FittedBox width 210→224).

**Validação:** `flutter analyze` limpo, `flutter test` 9/9. **Áudio:** só testável no
aparelho (o CI/`flutter test` não valida som). Versão `0.18.0+18`.

---

## 2026-08-03 — v0.19.0: som via soundpool + Desfazer visível + fonte

- **Som (item 1) — a saga:** (a) v0.17 `play(AssetSource)` em **modo normal** (mediaPlayer)
  → latência de prepare mata bips rápidos. (b) v0.18 lowLatency + **`seek`+`resume`** → o
  `seek` não é suportado em lowLatency e quebrava; só o `_fim` (espaçado) tocava. (c) tentei
  **`soundpool`** → **NÃO compila**: `soundpool 2.4.1` está **descontinuado** e usa a API
  `Registrar` do plugin **embedding v1**, removida no Flutter atual (`Unresolved reference
  'Registrar'`). **Solução final:** voltar ao `audioplayers` em **`PlayerMode.lowLatency`
  (SoundPool no Android) + `play(AssetSource)` direto** (sem seek/resume) — combinação que
  não tinha sido testada. Dois players (`_beep`/`_fim`). Lógica fim-de-série vs bip
  (rep==totalReps) mantida. **Lição:** conferir se um plugin é mantido (embedding v2) antes
  de adotar; o CI é quem pega isso.
- **Desfazer visível (item 2):** o `SnackBarAction` ficava escuro (M3 usa `inversePrimary`
  no dark) → invisível, e o usuário não conseguia tocar (o exercício "ficava permanente").
  Fix: `snackBarTheme.actionTextColor = AppColors.accentDoTema(tema)`. Duração 3s já ok.
- **Fonte (item 3):** anel 260→292, contador 150→176 (FittedBox width 224→250).

**Validação:** `flutter analyze` limpo, `flutter test` 9/9. **Risco:** soundpool é plugin
nativo novo — o build do CI valida; áudio só no aparelho. Versão `0.19.0+19`.

---

## 2026-08-04 — v0.20.0: fundo motivacional + horário de término + som (pool) + progressão

- **Som (item 4) — POOL de players:** mesmo em lowLatency + play(), reusar UM player a cada
  rep curta ainda falhava (tocava nas transições espaçadas, não nas rápidas). Fix: **5
  players de beep em rodízio** (`_beeps[_beepIdx]`, round-robin) — cada bip usa um livre.
  `_fim` segue com 1 player (espaçado). Dispose de todos.
- **Fundo do treino (item 3):** o usuário subiu 5 PNGs (~2MB, 941×1672, stories) via GitHub;
  comprimi p/ JPEG 810px q80 (~130KB cada, 712KB total) em `assets/fundos/` (PNGs originais
  removidos do repo). `Treino.fundo` (String? nome do asset). `util/fundos.dart`
  (`fundosDisponiveis` + `fundoAsset`). Editor: `_MiniaturaFundo` (rodízio horizontal, 1ª =
  "nenhum"/`Icons.block`). Player: `Stack` [Image cover + overlay preto 0.55 + conteúdo];
  novo param `PlayerScreen.fundo` (passado da home e do editor). Sincroniza no Firestore
  (campo `fundo` no JSON; assets são embutidos, iguais em todo device).
- **Horário de término (item 1):** `fmtHora(DateTime)`; card mostra "termina ~HH:MM" =
  `now + duracaoTotalSeg` (só se dur>0).
- **Progressão (item 2):** card padding 12→6, separator 12→8, gráfico height +30→+20, gap
  barra-data 6→3.

**Validação:** `flutter analyze` limpo, `flutter test` 9/9. Versão `0.20.0+20`.
