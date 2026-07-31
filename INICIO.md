# Calistenia — INÍCIO (ler primeiro em toda tarefa)

App **Flutter** de **cronômetros de treino de calistenia**. O usuário monta treinos
(por dia da semana, com nomes de exercícios que ele mesmo escreve) e, ao iniciar, o
app roda uma sequência de cronômetros: **preparação → execução → descanso**, repetida
pelo número de repetições. Design escuro, simples. Meta futura: **Play Store**.

> ⚠️ Projeto isolado. Vive **só** em `/root/calistenia_app/`.
> NUNCA tocar em `/root/trading/`, `/root/trading_acoes/`, `/root/trading_opcoes/`,
> `/root/lista_app/`.

> 📓 **Fluxo fixo:** ao fim de cada bloco significativo, atualizar
> [`APRENDIZADOS.md`](APRENDIZADOS.md) (diário técnico + lições) e dar **commit/push**.
> **Toda melhoria visível ao usuário / release novo → UMA LINHA (resumo + data) em
> [`ATUALIZACOES.md`](ATUALIZACOES.md)** (topo = mais recente). Planos futuros →
> [`IDEIAS.md`](IDEIAS.md). Os três têm papéis distintos: técnico (`APRENDIZADOS`) ·
> changelog do usuário (`ATUALIZACOES`) · futuro (`IDEIAS`).

## ⭐ ESTADO ATUAL (2026-07-30) — ler primeiro pós-/clear

**Publicado no GitHub** (repo privado `viniciostristao1/calistenia`, CI verde). Versão
atual = **v0.5.0** (release com APKs por arquitetura). **Nome de exibição = "Calis
Cronômetro"** (pacote Dart segue `calistenia`). Fase = **usuário instalar e usar** →
iterar pelo feedback real ([`IDEIAS.md`](IDEIAS.md)).

**Novidades da v0.5.0:** rename → **Calis Cronômetro**; **logo na home** (`assets/icon/
logo.png`, `Image.asset` na AppBar); ícone menor. 1ª versão instalada **por cima** (teste
da assinatura fixa). **Em discussão:** aba **Progressão** (gráfico de barras) — ver IDEIAS.

**Base (v0.4.0):** **assinatura FIXA** (keystore de upload via secrets — `build.gradle.kts`
+ workflow, padrão do lista_app) → fim do "conflito ao instalar" e da perda de treinos;
**Auto Backup** do Android (manifest). **A keystore (`app/android/app/upload-keystore.jks`,
gitignored) é crítica — não perder.**

**Base (v0.3.0):** cores de fase invertidas (prep=verde claro, exec=laranja); **execução
opcional** (pode remover, como prep/descanso); **descanso variável por série**
(`Exercicio.descansos`); **ícone do app** (cronômetro azul, `tools/gerar_icone.py`).

**Base (v0.2.0):** **séries + ritmo por repetição** (execução = tempo de UMA rep, ajuste
fino 1s, descanso entre séries; isométrico = `repeticoes: 1`; dados v0.1.0 migram
sozinhos); **visual navy** com `accent` azul separado das cores de fase; **home lista os
exercícios** e cada um roda avulso (`PlayerScreen` recebe `titulo` + `List<Exercicio>`).
Detalhes no [`APRENDIZADOS.md`](APRENDIZADOS.md).

> Releases: https://github.com/viniciostristao1/calistenia/releases

**O que existe e funciona (v0.1.0):**
- **Home** com seletor de **dias da semana** (Seg–Dom, hoje destacado; ponto verde nos
  dias que têm treino) e a lista de treinos do dia. FAB "Novo treino".
- **Editor de treino:** nome, dias em que aparece (multi-seleção), lista de exercícios
  **reordenável** (arrastar), adicionar/excluir exercício, excluir o treino. Salva ao
  vivo (nada se perde ao voltar). Botão "Iniciar treino".
- **Editor de exercício** (folha): nome + **repetições** + tempos de **preparação /
  execução / descanso** em segundos (± de 5 em 5 ou toque p/ digitar). Preparação e
  descanso são **removíveis** ("excluir alguma etapa"); execução é o núcleo.
- **Player (cronômetro):** roda a sequência com anel de progresso colorido por fase
  (preparação=âmbar, execução=verde, descanso=azul), número grande em contagem
  regressiva, contador de repetição, **pausar/retomar**, **pular** e **voltar** etapa,
  progresso geral ("Etapa X de N"), "A seguir: …", vibração nas transições e nos
  últimos 3s, e **mantém a tela ligada** (wakelock). Tela de "Treino concluído".
- **Dados 100% locais** (`shared_preferences`) — **sem login, sem nuvem**. No 1º uso
  semeia um "Treino exemplo" (editável/excluível).

**O que falta (próximo passo):**
1. ✅ ~~Gerar o APK na nuvem e publicar~~ — **feito** (release `v0.1.0`, CI verde).
2. **Usuário instalar o `app-arm64-v8a-release.apk` no celular** e usar de verdade.
3. Iterar pelo feedback do uso real (ver [`IDEIAS.md`](IDEIAS.md)). Próximos candidatos:
   bip de áudio nas transições (item [TOP]) e ícone próprio.

## O que o app faz (MVP)
1. Usuário cria um **treino**, dá um nome e marca os **dias da semana**.
2. Adiciona **exercícios** (escreve o nome) e ajusta, para cada um:
   **preparação** (segundos p/ se posicionar), **execução** (segundos fazendo o
   movimento), **descanso** (segundos) e **repetições**.
3. Na home, seleciona o dia, toca ▶ no treino → os **cronômetros começam** e avançam
   sozinhos pela sequência, com opção de pausar/pular/voltar.

### Modelo mental dos cronômetros (v0.2.0 — "ritmo por repetição")
Para cada exercício: `preparação (1×) → [ execução×repetições → descanso ] × séries`.
- **execução** = tempo de UMA repetição (ex.: uma flexão de 3s; ajuste fino de 1s);
- **repetições** = quantas por série (ex.: 10 flexões);
- **séries** = quantas rodadas (ex.: 3);
- **descanso** = entre séries (não há descanso entre repetições).

Um tempo em **0 = etapa ausente** (ex.: descanso 0 = sem descanso). O descanso no fim
absoluto do treino é omitido. **Isométrico** (prancha) = `repetições 1`, execução = tempo
da série. Migração v0.1.0→v0.2.0: o antigo "repetições" (rodadas) vira **séries**.

## Princípios (não violar)
1. **Sem conta / sem nuvem** (por ora) — é um cronômetro pessoal; dados locais.
2. **Tudo editável** — todos os tempos e repetições, e excluir qualquer etapa.
3. **Simples** — abrir e treinar em poucos toques.

## Técnico
- Flutter **3.44.7** / Dart **3.12.2** em `/root/flutter`.
- Estado: **Riverpod** (`flutter_riverpod`), persistência: **shared_preferences**,
  tela ligada no treino: **wakelock_plus**.
- Arquitetura feature-based: `app/lib/features/<feature>/`.
- Pacote Android: **com.vinyapps.calistenia**. Nome de exibição: **Calistenia**.
- **Build de release: na nuvem (GitHub Actions)** — a VPS é fraca p/ compilar Android.

## Estrutura do código (`app/lib/`)
- `models/` — `exercicio.dart`, `treino.dart`, `fase.dart` (+ `montarLinhaDoTempo`).
- `services/treinos_repository.dart` — carrega/salva treinos (Riverpod AsyncNotifier).
- `features/home/` — tela inicial (dias + treinos).
- `features/treino/` — editor de treino + folha de edição de exercício.
- `features/player/` — o cronômetro em execução.
- `theme/` — cores e tema escuro. `util/` — dias, formatação de tempo, ids.

## Como gerar o APK (instalar no celular)
A VPS não compila Android bem → o build sai na **nuvem** (GitHub Actions,
`.github/workflows/build-apk.yml`). Fluxo:
1. Repositório no GitHub (branch `main`) com este projeto.
2. Push em `app/**` dispara o workflow → o step de assinatura escreve `key.properties`
   a partir dos secrets e gera **APKs release por arquitetura** assinados com a **keystore
   de upload FIXA** (desde a v0.4.0). Chave estável ⇒ atualiza por cima sem "conflito".
3. Baixar o artefato `calistenia-apks`, pegar o **`app-arm64-v8a-release.apk`**
   (celulares Android modernos) e instalar no telefone (permitir "fontes desconhecidas").
   Alternativa: `gh run download` / criar um release com `gh release create`.

> **Assinatura (v0.4.0+):** keystore própria em `app/android/app/upload-keystore.jks` +
> `app/android/key.properties` (**gitignored**, presentes na VPS); secrets no GitHub
> `KEYSTORE_BASE64` (base64 do .jks) e `KEYSTORE_PASSWORD`, alias `upload`. **Guardar
> backup da keystore** (perdê-la trava updates e a Play Store). Mesmo padrão do `lista_app`.

## Ambiente
VPS: ~1 vCPU, pouca RAM. OK para codar/`flutter analyze`/`flutter test`/`build web`;
build de APK sai na nuvem.
