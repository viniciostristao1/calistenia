# Configurar o Firebase (login com Google)

Guia para habilitar o **login com Google** no Calis Cronômetro. O padrão segue o
`lista_app` (que já usa Firebase e funciona). Divide-se em: **o que você faz no
Firebase Console** (Parte A) e **o que o Claude faz no código** (Parte B).

> ⚠️ **Package name = `com.vinyapps.calistenia`** (NÃO mudar, mesmo que o nome de
> exibição vire "Calis Timer"). O Firebase se registra pelo package, não pelo nome.

---

## Parte A — Você faz no Firebase Console

1. Acesse **https://console.firebase.google.com** e entre com sua conta Google
   (viniciostristao@gmail.com).
2. **Adicionar projeto** (Create a project). Nome do projeto: livre (ex.: "Calis
   Timer"). O **Google Analytics pode ser desativado** (não precisamos). Criar.
3. Dentro do projeto, clique no ícone do **Android** (Adicionar app → Android):
   - **Nome do pacote Android:** `com.vinyapps.calistenia`  ← exatamente isto.
   - Apelido do app (opcional): `Calis Timer`.
   - **Certificado de assinatura SHA-1:**
     `6B:33:2E:7E:E7:2E:03:C3:D2:8F:72:CC:04:8B:29:E6:67:45:92:6A`
   - **Registrar app**.
4. **Baixe o `google-services.json`** (botão na tela). Guarde esse arquivo.
5. Os passos seguintes do assistente ("adicionar SDK ao Gradle") — **pule**, o Claude
   faz isso no código.
6. Menu lateral → **Authentication** → **Get started** → aba **Sign-in method** →
   habilite **Google** → informe um e-mail de suporte se pedir → **Salvar**.
7. **Envie o `google-services.json`** para o Claude (cole o conteúdo no chat, ou suba
   no repositório e avise).

---

## Parte B — O Claude faz no código (após receber o json)

- Adiciona `firebase_core`, `firebase_auth`, `google_sign_in` (mesmas versões do
  lista_app: `^4.x` / `^6.x` / `^7.x`).
- Configura o Gradle: plugin `com.google.gms.google-services` (settings.gradle +
  app/build.gradle), como no lista_app.
- Coloca o `google-services.json` em `app/android/app/` (gitignored) e cria o secret
  **`GOOGLE_SERVICES_JSON`** no GitHub para o build na nuvem.
- Gera o `firebase_options.dart` e chama `Firebase.initializeApp(...)` no `main`.
- Implementa o **login/logout real** (substitui o botão "em breve" em Configurações →
  Conta): entrar com Google, mostrar quem está logado, sair.
- Lança uma nova versão com o login funcionando.

---

## Sincronização (Firestore) — passos no console

Para os treinos/check-ins/progressão ficarem na conta e voltarem em qualquer aparelho:

1. Menu → **Criação/Build → Firestore Database → Criar banco de dados**.
2. Escolhas:
   - **Edição:** Standard.
   - **Local:** `southamerica-east1` (São Paulo). ⚠️ **permanente**, não muda depois.
   - **Modo:** **Produção** (não teste).
3. Aba **Regras** (Rules) → cole o conteúdo de [`firestore.rules`](firestore.rules) →
   **Publicar**. (Sem isso, o banco em modo produção bloqueia tudo e a sync não funciona.)

Estrutura na nuvem: um doc por usuário `users/{uid}` com os campos `treinos`, `checkins`,
`progressao` (o mesmo JSON do armazenamento local) + `updatedAt`. O código está em
`app/lib/services/sync_service.dart`.

## Notas importantes

- **Login ≠ sincronização.** Habilitar o login apenas **identifica** quem você é. Salvar
  os treinos na sua conta (recuperar ao trocar de celular) é uma **etapa seguinte, maior**
  (banco na nuvem / Firestore). Fazemos depois, se você quiser.
- **SHA-1 e Play Store:** o SHA-1 acima é o da **keystore de upload** (assina os APKs de
  teste). Se um dia publicarmos na Play Store com **Play App Signing**, o Google gera outra
  chave e será preciso adicionar **também** o SHA-1 dela no Firebase. Por ora, o de upload
  basta.
- **Nome "Calis Timer":** é só o nome de **exibição** (`android:label` + título da home).
  Muda quando você quiser, sem afetar o Firebase. O package segue `com.vinyapps.calistenia`.

## Crashlytics (relatório de crashes) — v0.36.0

Pacote `firebase_crashlytics`. Em `main.dart`, `FlutterError.onError` e
`platformDispatcher.onError` mandam todo erro (com **stack trace**) pro painel — assim um
"erro interno" reportado pelo usuário chega diagnosticável, sem depender de reprodução.

- **Onde ver:** Firebase Console → projeto `calis-timer` → **Crashlytics**. O produto
  costuma "ativar" sozinho ao chegar o **primeiro** relatório (pode levar alguns minutos após
  o crash, com o app reaberto).
- **Escopo atual:** só relatório **Dart** (exceções do app). **Não** adicionamos o *plugin
  Gradle* `com.google.firebase.crashlytics` — ele serve p/ símbolos **NDK** e p/
  de-ofuscar mapping do R8, que hoje não precisamos (não ofuscamos o Dart). Se um dia
  ofuscarmos ou quisermos crashes nativos legíveis, aí adicionamos o plugin.
- **Teste rápido:** `FirebaseCrashlytics.instance.crash()` força um crash de teste (remover
  depois). Sem isso, é só esperar um erro real.
