/// Flags de compilação (dart-define).
///
/// `kMostrarLab` — mostra o 🧪 Laboratório de Animações (ferramenta de DEV) na
/// tela de Configurações. É ligado só no canal de TESTE (o build-apk do GitHub
/// passa `--dart-define=LAB=true`). O **build da Play Store** (build-aab) NÃO
/// define o flag → o Laboratório **não aparece** para o usuário final.
const bool kMostrarLab = bool.fromEnvironment('LAB');
