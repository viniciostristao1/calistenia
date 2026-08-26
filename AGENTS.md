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

> CI: `.github/workflows/build-apk.yml` → `flutter build apk --release --split-per-abi` → `gh release create/upload vX.Y.Z` (tag = `version:` do `pubspec.yaml` sem `+N`).
