# AGENTS — Regras de entrega

Este repo segue o fluxo de `INICIO.md` (harness). Complemento:

## Entrega de APK — link direto do GitHub

**Sempre que concluir uma nova versão (após `commit + push` na `main` e CI verde):**

1. Aguardar o workflow **Build APK** terminar (`gh run watch` ou `gh run list`).
2. Pegar o **link direto do APK no GitHub Releases** — não link temporário (catbox/tmpfiles):
   - `https://github.com/viniciostristao1/calistenia/releases/latest` (sempre aponta pro último)
   - ou específico da tag: `https://github.com/viniciostristao1/calistenia/releases/download/vX.Y.Z/app-arm64-v8a-release.apk`
   - Listar assets: `gh release view vX.Y.Z --json assets --jq '.assets[].url'`
   - Link direto para celular moderno: `app-arm64-v8a-release.apk` (recomendado). Também existem `app-armeabi-v7a-release.apk` e `app-x86_64-release.apk`.
3. **Mandar esse link direto no chat** como entrega final. Nunca mandar só o caminho local (`build/app/outputs/...`) ou link temporário.
4. Esta regra vale para **toda** nova versão, sem exceção.

> CI: `.github/workflows/build-apk.yml` → `flutter build apk --release --split-per-abi --dart-define=LAB=true` → `gh release create/upload vX.Y.Z` (tag = `version:` do `pubspec.yaml` sem `+N`).

## ⚠️ 🧪 Laboratório de Animações = ferramenta de DEV (flag `LAB`)
O Lab (Config → "Laboratório de Animações", `features/lab/`) **NÃO pode aparecer para o usuário
final da Play Store**. Ele fica atrás de `kMostrarLab` (`app/lib/util/flags.dart` =
`bool.fromEnvironment('LAB')`):
- **`build-apk.yml` (canal de TESTE)** passa `--dart-define=LAB=true` → Lab **visível** no APK do
  GitHub (é onde você testa animações).
- **`build-aab.yml` (Play Store)** **não** passa o flag → Lab **oculto** no app publicado.
- **Regra:** ao mexer em `config_screen.dart`/`fx/`/`lab/`, mantenha o item do Lab dentro de
  `if (kMostrarLab)` e **não** remova o `--dart-define=LAB=true` do build-apk. Ver `ANIMACOES.md`.

## Lançamento na Play Store (AAB) — NÃO é o fluxo normal de melhoria
> **Melhoria/bugfix do dia a dia NÃO mexe no AAB.** O ciclo normal é: editar → `analyze`/`test`
> → subir versão (`pubspec` `+N` **e** `util/versao.dart`) → push → CI faz o APK → entregar o link.
> O AAB só entra quando se quer **publicar na Play Store**.

- **Pacote de loja pronto:** ver [`LANCAMENTO.md`](LANCAMENTO.md) (ficha, Data Safety, `store/`,
  política/termos no repo `viniciostristao1/calistenia-privacidade`).
- **Gerar/atualizar o AAB:** `gh workflow run build-aab.yml` (sob demanda). Compila
  `flutter build appbundle --release` (SEM o flag LAB → Lab oculto) assinado e anexa o AAB ao
  Release da versão (latest): `…/calistenia/releases/latest/download/app-release.aab` (repo
  público → sem login). **Cada upload novo na Play exige `versionCode` (`+N`) maior.**
- **Publicar de fato = passo manual do usuário** no Play Console. Uma IA **não** publica na loja;
  no máximo gera o AAB e avisa. Screenshots/descrição trocam direto no Console (sem AAB novo).
