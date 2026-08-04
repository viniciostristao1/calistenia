# Atualizações (para o usuário)

Uma linha por melhoria visível / release. Topo = mais recente. É o "o que mudou / o que
re-testar".

- **2026-08-04 — v0.22.0 (gamificação + "um lado por vez" + "treino completo?"):**
  - **Exercício "um lado por vez"** (unilateral): no editor do exercício, ligue "Um lado por
    vez" (ex.: flexão de um braço). Cada série roda **prep → lado 1 → prep → lado 2 →
    descanso**, e o cronômetro mostra "Lado 1/2".
  - **Pergunta no fim do treino:** "Você completou o treino?". **Sim** conta para a
    gamificação; **Não** mostra uma frase de incentivo (o dia ainda entra no check-in). Só
    aparece ao rodar um treino inteiro (não em exercício avulso).
  - **Medalhas e troféus:** 🥈 4 dias seguidos · 🥇 8 dias seguidos · 🏆 15 dias concluídos ·
    👑 troféu-surpresa (oculto até desbloquear). Sequência conta **dias agendados** —
    descanso não quebra a corrente.
  - **Galeria de Conquistas:** na aba **Check-in**, alterne no topo entre **Calendário** e
    **Conquistas**; abaixo do calendário, uma faixa mostra sua sequência atual.
  - **Ligar/desligar** tudo isso em **Config → Gamificação**.
  - Conclusões e conquistas **sincronizam** na conta (como treinos/check-ins).
- **2026-08-04 — v0.21.0 (fundo por exercício + relógio + correção de sync/undo):**
  - **Imagem de fundo agora é POR EXERCÍCIO** (não por treino): a escolha está no editor do
    exercício, antes de "Salvar exercício". No cronômetro, o fundo muda conforme o exercício.
    **3 novas imagens** (8 no total).
  - **Card do treino:** no lugar de "termina", um **ícone de relógio** + "~HH:MM".
  - **Correção de bug (sync):** a sincronização entrava num **loop** (cada mudança gerava
    outra), gastando bateria/rede e podendo prender notificações. Corrigido.
  - **Desfazer exclusão:** notificação agora com messenger estável (aparece e some em 3s).
- **2026-08-04 — v0.20.0 (imagem de fundo + horário de término + som + progressão):**
  - **Imagem de fundo motivacional** no cronômetro: no editor do treino, escolha uma das
    fotos (miniaturas) — ela aparece atrás do contador daquele treino. "Nenhuma" também é
    opção.
  - **Horário de término** no card do treino (aba Treinos): a que horas termina se começar
    agora (ex.: "termina ~14:35").
  - **Som (4ª abordagem):** um **pool de players** — cada bip usa um player livre, pra tocar
    **em cada repetição** (o reuso do mesmo player falhava nas trocas rápidas).
  - **Progressão** mais compacta (menos espaço vazio nas caixinhas).
- **2026-08-03 — v0.19.0 (som de novo + Desfazer visível + fonte):**
  - **Som (2ª tentativa):** troquei o motor de áudio por um feito para efeitos rápidos, pra
    o bip tocar **em cada repetição** (na versão anterior só o som de fim de série tocava).
  - **"Desfazer"** agora aparece na **cor de destaque** (antes ficava escuro e quase
    invisível) — dá pra ver e tocar para reverter a exclusão.
  - **Números do cronômetro** ainda maiores.
- **2026-08-03 — v0.18.0 (som corrigido + fim de série + desfazer):**
  - **Som corrigido:** o bip agora toca **em cada repetição** durante o treino (antes falhava
    nas trocas automáticas). E o **fim de cada série** toca um **som diferente** (o mesmo do
    fim do treino) — pra diferenciar "vai executar" de "terminou".
  - **Desfazer exclusão:** ao excluir um treino ou exercício, aparece **"Desfazer"** por
    3 segundos.
  - **Números do cronômetro** um pouco maiores.
- **2026-08-03 — v0.17.0 (sincronização na conta):**
  - Com você **logado**, seus **treinos, check-ins e progressão** ficam salvos na sua
    conta Google e **voltam ao reinstalar ou trocar de celular**. Funciona offline (envia
    quando reconecta).
  - No 1º login, o app **une** o que está no aparelho com o que já está na conta (não perde
    nada). Depois, o que você edita se reflete nos outros aparelhos.
  - Requer o banco Firestore criado no console (ver `FIREBASE.md`).
- **2026-08-03 — v0.16.0 (login com Google):**
  - Em **Configurações → Conta**, o **"Entrar com Google"** agora **funciona** de verdade:
    entra com sua conta, mostra seu nome/e-mail e permite **Sair**.
  - Por ora o login apenas **identifica** você (prepara o terreno). A **sincronização** dos
    treinos na conta chega numa próxima versão.
  - Requer Android 6.0+ (a biblioteca do Google exige).
- **2026-08-03 — v0.15.0 (novo nome: Calis Timer):**
  - O app agora se chama **Calis Timer** (nome de exibição, na tela inicial e sob o ícone).
    O identificador interno (`com.vinyapps.calistenia`) segue igual — nada de dados/instalação
    muda, e o Firebase continua compatível.
- **2026-08-02 — v0.14.0 (som de verdade + vários ajustes):**
  - **Som agora funciona:** bip próprio (não mais o som do sistema, que não tocava) nas
    transições e um som no fim do treino. Liga/desliga em Configurações → Som.
  - **Números do cronômetro** ainda maiores.
  - **"Adicionar à progressão"** também no **fim do treino** (entre "Repetir treino" e
    "Voltar"), pedindo quantas repetições você fez de cada exercício.
  - **Reusar exercícios:** no editor de treino, "Adicionar de exercícios já salvos" —
    toque num exercício de outro treino para adicioná-lo aqui.
  - **Ícones** ao lado dos títulos das abas **Check-in** e **Progressão**.
  - Placeholders (**"Ex.:…"** e **"Novo treino"**) agora em cor **neutra/fraca**.
  - Botões **−/+** mais **próximos** dos números.
  - **Barras da progressão** com **metade da largura** (cabem mais).
- **2026-08-02 — v0.13.0 (ajustes de layout, som, tema e ícone):**
  - **Dias da semana** cabem todos no topo da aba Treinos (sem precisar arrastar).
  - **Troca de tema corrigida:** agora muda **na hora**, sem o delay/atualização parcial.
  - **Som:** liga/desliga em **Configurações → Som**; e um som leve marca o **fim** do treino.
  - **"Check-in concluído"** na tela final (era "Treino concluído").
  - **Números do cronômetro maiores** (mais fáceis de ler de longe).
  - **Progressão:** barras mais perto do título do exercício.
  - **Check-in:** meses com a **primeira letra maiúscula**.
  - **Ícone** do app com o âmbar um pouco mais escuro (mais perto do lista_app).
- **2026-08-02 — v0.12.0 (tela de login preparada):**
  - Em **Configurações → Conta**, o botão **"Entrar com Google"** já aparece (visual). A
    conexão real é ativada quando configurarmos o Firebase — por ora ele avisa "em breve".
- **2026-08-02 — v0.11.0 (ícone âmbar + tema padrão âmbar + limpezas):**
  - **Novo ícone** no estilo do lista_app: cronômetro **preto** sobre **fundo âmbar**;
    desenho um pouco menor e mais para baixo.
  - **Âmbar** virou a **cor oficial** do app (tema padrão). Dá pra trocar para **azul** em
    Configurações.
  - **Troca de tema instantânea** (sumiu o "delay" ao alternar azul/âmbar).
  - **Progressão** mais limpa: removido o texto "de X → Y reps" (fica o nome + a variação).
- **2026-08-01 — v0.10.0 (aba Check-in / calendário de assiduidade):**
  - Nova aba **Check-in** 📅 com um **calendário mensal**. Cada dia mostra **pontinhos com
    as cores dos exercícios** que você fez — dá pra ver a constância do mês de relance.
  - **Automático:** ao terminar o cronômetro de um exercício, ele já é **marcado no dia de
    hoje** (mesmo que você pare o treino no meio, os exercícios feitos contam).
  - **Manual:** toque num dia do calendário para **marcar/desmarcar** exercícios (corrigir
    ou registrar dias sem cronômetro).
- **2026-08-01 — v0.9.0 (novo ícone + ajustes):**
  - **Novo ícone** do app: cronômetro azul com o botão lateral, ponteiro afilado (segue a
    arte que você enviou).
  - **Progressão:** altura dos gráficos de barras **reduzida pela metade**.
  - **Aba Treinos:** removida a **linha** abaixo dos dias da semana.
- **2026-08-01 — v0.8.0 (barra superior, tema, compartilhar, peso, cores):**
  - **Barra de cima** com **⚙️ configurações**, **compartilhar** e **sair**.
  - **Configurações → tema:** escolha entre **azul** (atual) e **âmbar** para os destaques.
  - **Compartilhar:** gera o treino do dia em **texto** (exercícios, séries, tempos, peso…)
    para **copiar** e colar onde quiser (WhatsApp etc.).
  - **Peso por exercício:** novo campo no editor (ex.: 10kg, 2,5kg) — aparece no resumo e
    no texto compartilhado.
  - **Cor por exercício:** um **pontinho colorido** antes do nome; escolha entre **10
    cores** no editor do exercício.
  - **Progressão:** as barras agora ficam **alinhadas embaixo** (só a altura muda).
- **2026-07-31 — v0.7.0 (dica de edição no card + ícone menor):**
  - No card do treino, um **ícone de 6 pontinhos** ao lado do nome (ex.: "Peitoral")
    indica que ali se **toca para editar** os exercícios.
  - **Ícone do app** com o cronômetro um pouco menor (mais margem).
- **2026-07-31 — v0.6.0 (aba Progressão com gráfico de barras):**
  - Nova aba embaixo, **Progressão** 📈. Para cada exercício, um **gráfico de barras** com
    a evolução das repetições ao longo das datas (mostra "de X → Y reps" e a variação).
  - No editor de um exercício, botão **"Adicionar à progressão"**: digite quantas
    repetições você fez hoje (já vem sugerido o valor do exercício) e vira uma barra.
  - Toque numa barra para remover aquele registro; a lixeira limpa a progressão do
    exercício. Tudo salvo no aparelho (sem login).
- **2026-07-31 — v0.5.0 (novo nome + logo na tela + ícone menor):**
  - O app agora se chama **Calis Cronômetro** (nome sob o ícone no celular).
  - Na tela inicial, o **logo do cronômetro** aparece ao lado do nome (no lugar do texto
    antigo "Calistenia").
  - **Ícone do app um pouco menor** (mais margem).
  - **1ª atualização instalada POR CIMA** (sobre a v0.4.0) — se seus treinos continuarem lá,
    a correção de assinatura funcionou. 🎯
- **2026-07-31 — v0.4.0 (atualização por cima sem perder treinos + ícone ajustado):**
  - **⚠️ Instale esta versão UMA vez desinstalando a anterior** (a assinatura do app
    mudou). **A partir desta**, as próximas você instala **por cima**, sem "conflito" e
    **sem perder os treinos** — era isso que apagava seus dados.
  - **Backup automático do Google** ligado: ao trocar de aparelho ou reinstalar, o Android
    pode restaurar seus treinos (sem login, sem Firebase).
  - **Ícone menor**, com **botão de cronômetro** no topo e **marcadores 12/3/6/9h**.
- **2026-07-31 — v0.3.0 (cores, etapas opcionais, descanso por série e ícone):**
  - **Cores das fases trocadas:** preparação agora é **verde claro** e execução é
    **laranja** (o descanso segue azul).
  - **Execução opcional:** dá pra **remover o tempo de execução** (fica só "+ adicionar
    execução"), igual já era com preparação e descanso.
  - **Descanso diferente por série:** no editor, toque em **"Descanso diferente por
    série"** e defina um tempo para cada série (ex.: 1min na 1ª, 1min30 na 2ª…). O botão
    "Um só" volta ao descanso único.
  - **Ícone do app:** cronômetro minimalista, azul claro degradê sobre fundo azul escuro.
- **2026-07-30 — v0.2.0 (séries, novo visual e exercício avulso):**
  - **Séries + ritmo por repetição:** agora cada exercício tem **séries** (quantas
    rodadas) e **repetições** (quantas por série), e a **execução é o tempo de UMA
    repetição** com ajuste fino de 1 em 1 segundo (2s, 3s, 4s por flexão…). O
    cronômetro conta rep a rep e descansa **entre séries**. Isométrico (prancha) =
    repetições 1. Seus treinos antigos são convertidos automaticamente (o antigo
    "repetições" vira "séries").
  - **Visual novo:** paleta **azul-escura (navy)** com destaque azul, cards e botões
    repaginados — cara própria, menos genérica.
  - **Home mostra os exercícios:** o card do treino lista os exercícios; **toque em um
    para executá-lo sozinho** (ex.: só o agachamento). O ▶ grande roda o treino todo.
- **2026-07-30 — v0.1.0 (primeira versão):** app de cronômetros de calistenia. Crie
  treinos por dia da semana, escreva os exercícios, ajuste preparação/execução/descanso
  e repetições, exclua qualquer etapa. Toque ▶ e os cronômetros rodam sozinhos com
  pausar/pular/voltar, vibração nas trocas e tela sempre ligada. Dados salvos no
  aparelho (sem login). Abre com um "Treino exemplo" que você pode editar ou excluir.
