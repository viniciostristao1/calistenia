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
