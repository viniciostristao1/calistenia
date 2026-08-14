# Atualizações (para o usuário)

Uma linha por melhoria visível / release. Topo = mais recente. É o "o que mudou / o que
re-testar".

- **2026-08-14 — v0.44.0 (crédito parcial pra quem tenta):**
  - Marcar **"Não consegui hoje"** agora **conta**: vale **metade da consistência** e **mantém a
    sua sequência** (antes zerava e ainda podia quebrar a corrente). Recompensa quem apareceu e
    tentou — ex.: foi atrás de um recorde e não fechou. **Completar continua valendo mais**
    (consistência cheia + chance de recorde). Se você repetir e completar no mesmo dia, vira completo.
- **2026-08-14 — v0.43.0 (removido o tema Grafite):**
  - Tirei o tema **Grafite** (a seu pedido). Ficam **4 temas**: Âmbar, Azul, Espresso e Madeira.
    (Se você estava usando o Grafite, o app volta pro Âmbar.)
- **2026-08-13 — v0.42.0 (3 temas novos: Grafite, Espresso e Madeira — neumorphism):**
  - **3 temas novos** em Config (além de Azul e Âmbar): **Grafite** (escuro grafite), **Espresso**
    (escuro amadeirado) e **Madeira** (bege claro amadeirado) — no estilo **neumorphism** (relevo
    por luz e sombra). O seletor mostra um mini-preview de cada.
  - O **cronômetro** ganhou o **relevo neumórfico**: o anel, o placar (nome + contagem) e os botões
    parecem esculpidos/elevados. O contador agora segue a **cor do tema**.
  - O tema muda as **cores do app inteiro** (fundo, texto, cards). **Madeira é um tema claro.**
  - Azul e Âmbar continuam como estavam. As **outras telas** ainda vão ganhar o relevo completo nas
    próximas versões (por ora já adotam as cores novas).
- **2026-08-13 — v0.41.0 (compartilhar a semana toda):**
  - O botão de compartilhar (topo da home) agora tem **duas opções**: **"Compartilhar o dia"** e
    **"Compartilhar a semana toda"**. A semana sai **separada por dia** (Segunda→Domingo, com
    "(descanso)" nos dias livres), no mesmo formato detalhado.
- **2026-08-12 — v0.40.0 (nome do exercício em 1 linha + placar colado):**
  - **Nome do exercício sempre em UMA linha** no cronômetro: nomes longos **encolhem a fonte
    automaticamente** em vez de quebrar em duas linhas.
  - A **tarja amarela da contagem** agora vem **colada** logo abaixo do nome (sem espaço) — um
    placar só.
- **2026-08-12 — v0.39.0 (copiar nome do exercício + editor uniforme + compartilhar detalhado):**
  - **Editar exercício:** botão de **copiar o nome** no canto superior direito — pra mandar rápido
    pra alguém.
  - **Editor mais uniforme:** todos os rótulos (séries, repetições, um lado por vez, preparação…)
    ficaram com a **mesma fonte**; tirei o "(por série)" de Repetições.
  - **Compartilhar treino** ficou **detalhado**: por exercício mostra séries×reps, execução/rep,
    descanso/série e (preparação), além da duração total.
- **2026-08-12 — v0.38.0 (progressão automática + placar no cronômetro + novos fundos):**
  - **Progressão sem fricção:** ao responder **"Sim, completei"**, se você fez mais reps que o seu
    recorde (porque subiu o plano), o app **registra o novo recorde sozinho** — com uma comemoração
    "🎉 Novo recorde". Acabou o botão manual "Adicionar à progressão".
  - **Comemoração no fim do treino:** o ícone de concluído **salta** (com ou sem recorde) e aparece
    uma **frase de incentivo aleatória** — como já existia no "não consegui hoje".
  - **Cronômetro:** o nome do exercício e a contagem **"5/12"** viraram **duas tarjas empilhadas**
    (um placar), com a **mesma largura e a mesma fonte**.
  - **Novos fundos:** troquei todas as imagens motivacionais pelas **12 novas** (soldados em treino)
    que você subiu.
- **2026-08-11 — v0.37.0 (anel do cronômetro fluido de novo):**
  - O anel voltou a **drenar suave** durante a contagem (na v0.35 ele tinha passado a "saltar" a
    cada segundo). O travamento que a gente corrigiu era do **áudio**, não do anel — então dá pra
    manter a fluidez sem risco.
- **2026-08-11 — v0.36.0 (interno: relatório de crashes + testes do cronômetro):**
  - **Sem mudança visível.** Internamente, o app agora **reporta erros automaticamente** (com
    detalhes técnicos) — se algo travar/fechar, a correção fica muito mais rápida, sem depender de
    você lembrar o que aconteceu. E adicionei **testes automáticos do cronômetro** (inclusive o
    caso de 22×4 que travava) pra pegar regressões antes de chegar no seu celular.
- **2026-08-11 — v0.35.0 (correção do travamento + "A seguir" por etapa + nome em tarja):**
  - **Correção importante do travamento:** o cronômetro travava/fechava em exercícios de **muitas
    repetições** (ex.: 22 reps × 4 séries) — o som era **recarregado a cada repetição**, vazando até
    o app fechar. Agora o som é pré-carregado uma vez, e a tela reconstrói ~10× menos por segundo.
  - **"A seguir" agora mostra a próxima ETAPA**, não a próxima repetição: durante a série diz
    **"A seguir: Descanso · 1min 30s"**; no descanso diz **"A seguir: Flexão declinada · 12 reps"**.
  - **Nome do exercício** virou uma **tarja larga** no topo (logo abaixo de "Exercício X · Série Y"),
    **fonte maior**, branco, centralizado, em MAIÚSCULAS.
  - **Contador de reps "5/12" maior** (fonte 46).
  - **Home:** a linha entre o título do treino e a lista de exercícios ficou **mais neutra/fraca**
    (igual à cor dos "6 pontinhos").
- **2026-08-10 — v0.34.0 (cronômetro repaginado — nome em caixa + amarelo maior):**
  - **Nome do exercício** agora dentro de uma **caixa cinza-escuro arredondada**; removido o
    texto "X repetições" abaixo do nome (redundante).
  - **Contador de reps maior** e em formato **pílula** (bordas bem arredondadas), com o número
    centralizado e sem sobra de espaço em cima/baixo.
- **2026-08-10 — v0.33.0 (contagem começa em 0 + mais respiro):**
  - O **contador de reps conta as concluídas**: começa em **0** e vai até 11 (numa série de 12).
    Ao fechar a última a série encerra — o "12" não fica girando na tela.
  - **Mais espaço** entre o contador amarelo e o círculo do cronômetro.
- **2026-08-10 — v0.32.0 (ajuste fino do cronômetro):**
  - **"EXECUÇÃO/DESCANSO" e "Série X/Y" recolhidos para DENTRO** do círculo (não vazam mais por
    cima/baixo); contador amarelo um pouco maior; nome e contador um pouco mais pra cima.
- **2026-08-09 — v0.31.0 (ajustes do cronômetro + correção do "travado"):**
  - **Card do treino:** ponto antes do relógio ("3 exercícios · 14 min · 🕐 ~14:35").
  - **Cronômetro:** nome do exercício em **MAIÚSCULAS**; abaixo, **"X repetições"** em negrito;
    novo **contador "5/22" numa caixa amarela** acima do número (sobe a cada repetição); e o
    **número do cronômetro ficou maior**.
  - **Correção do bug:** pausar → minimizar → voltar **não trava mais** (o app auto-pausa ao ir
    para segundo plano e volta respondendo).
- **2026-08-08 — v0.30.0 (Rating repensado + feedback no cronômetro):**
  - **Rating vira nota 0–100** ("nota de desempenho", estilo Elo): **Consistência (0–40)** +
    **Frequência (0–20)** + **Progressão (0–40)**. A Consistência agora tem **"hoje neutro"**
    (não cai de manhã antes de você treinar). A **Progressão mede a melhora REAL dos recordes**
    (quanto você subiu), não só "bateu ou não". A Frequência premia volume sem punir quem treina
    menos.
  - **No cronômetro:** aparece **"última vez: X reps"** no exercício (a referência a bater) e um
    **carimbo "Série 2/3 ✓"** a cada série concluída.
  - *(Inclui também as novidades da v0.29.0 — pontinhos de repetição e progressão automática —
    que não chegaram a virar APK por causa de um apagão do GitHub Actions.)*
- **2026-08-06 — v0.29.0 (cronômetro com pontos de rep + progressão automática):**
  - **Cronômetro:** na execução, o anel agora mostra **pontinhos das repetições** (as feitas
    acesas) — você vê o tempo E quantas reps faltam de uma vez.
  - **Progressão automática:** todo exercício **já entra na Progressão** ao salvar (linha de
    base = repetições), como um **alvo a bater**. Exercícios antigos também entram. Removido o
    botão "Adicionar à progressão" do editor (fim da edição sem treinar). O registro do
    desempenho segue no **fim do treino**.
- **2026-08-06 — v0.28.0 (fix do cronômetro + Rating na Progressão com gráfico):**
  - **Correção do cronômetro:** se o app era suspenso (tela apagada / economia de bateria)
    numa série longa, ele "pulava" as fases e podia fechar sozinho. Agora o avanço por tick é
    limitado — não pula mais.
  - **"Nível de forma" → "Rating"** e **movido para a aba Progressão**.
  - A **Progressão** ganhou duas sub-abas: **Desenvolvimento** (as barras de sempre) e
    **Rating** (o valor + um **gráfico de linha** com a tendência das últimas semanas).
- **2026-08-06 — v0.27.0 (perda escalonada + barra "Nível de forma"):**
  - **Perda escalonada:** pular um dia agendado tira **só o último prêmio** (cai um degrau),
    não zera tudo. Ex.: perde o 🥇 e volta para 🥈; perde o 🏆 Ouro e fica com o de Prata. Cada
    dia agendado pulado desce um degrau.
  - A **"Sequência atual"** passou a ser esse **nível** (com a aterrissagem suave); **Recorde**
    = melhor nível de todos os tempos.
  - Nova barra **"Nível de forma"** no topo da Galeria: **Assiduidade** recente (0–100) +
    **Evolução** por recordes (0–40). Decai se você parar e **só passa do platô com progressão**
    — assim você não fica preso ao Troféu de Ouro.
- **2026-08-06 — v0.26.0 (ícone sem moldura + selo de recorde + editar exercício):**
  - **Ícone sem o quadrado preto** em volta — agora é âmbar full-bleed com a arte.
  - **Selo de recorde** (🏅) na barra do maior valor de cada exercício na Progressão (sem
    aumentar a altura dos cards).
  - **Editar exercício** não encosta mais no topo (relógio/bateria): abre com folga.
- **2026-08-05 — v0.25.0 (novo ícone + histórico + barras + botão voltar):**
  - **Novo ícone do app** (o cronômetro âmbar com a flexão).
  - **Barrinha de progresso** em cada medalha/troféu na Galeria: cinza enquanto não bate,
    colorida (prata/ouro) quando conquista.
  - Nova sub-aba **Histórico**: as conquistas **perdidas** ficam guardadas por **mês** (mais
    recente em cima), em miniatura. Uma conquista ativa não aparece no histórico (não duplica).
  - **Botão de voltar** dentro de "Editar exercício".
  - **Troféu de Ouro:** confirmado — só aparece com **todas as anteriores ativas** (21 dias
    seguidos) **e** progressão em ≥50% nesses 21 dias; some se pular um dia agendado ou ficar
    21 dias sem progredir.
- **2026-08-05 — v0.24.0 (conquistas por sequência + recorde + número maior):**
  - **Regra unificada:** TODAS as conquistas são por **sequência** de dias agendados —
    🥈 4 · 🥇 8 · 🏆 Prata 15 · 🏆 Ouro 21 seguidos (o Ouro pede também **progressão em
    ≥50%** dos exercícios nesses 21 dias). **Pulou um dia agendado → todas caem.** O Ouro
    cai também se ficar 21 dias sem recorde novo.
  - **Adeus coroa:** o Ouro agora é um **troféu dourado** (e o de Prata, prateado), com as
    cores certas.
  - **Recorde:** no lugar de "Melhor sequência", a Galeria mostra **"Sequência atual"** (a que
    dá prêmio) + **"🏅 Recorde"** (sua melhor sequência de todos os tempos, que fica mesmo
    zerando — um alvo a bater).
  - **Cada regra** mostra o progresso da sua sequência ("Sequência: X/N").
  - **Número do cronômetro** um pouco **maior**.
- **2026-08-04 — v0.23.0 (ajustes da gamificação: galeria, conquistas no calendário):**
  - **Cor do tema** no seletor Calendário/Galeria (era azul fixo; agora segue âmbar/azul).
  - **Conquistas no calendário:** no dia em que você ganhou uma medalha/troféu, o calendário
    mostra a **medalha/troféu no lugar das bolinhas** dos exercícios (sem mudar o tamanho).
  - Sub-aba renomeada para **Galeria**. No topo, caixa **"Conquistas atuais"** (o que você
    sustenta agora): as **medalhas caem** se a sequência quebrar, o **Troféu de Prata**
    (acúmulo de 15 dias) **permanece**, e a **Coroa** cai se você ficar >21 dias sem recorde
    novo. Abaixo, as regras com "quanto falta".
  - **Troféu de Prata** agora aparece **prateado** (ícone), combinando com o nome.
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
