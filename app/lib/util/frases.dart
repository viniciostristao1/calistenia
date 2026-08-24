import 'dart:math';

/// Frases mostradas quando a pessoa indica que NÃO completou o treino.
/// Reconhecem a tentativa sem punir — o dia ainda entra no check-in. Uma é
/// sorteada aleatoriamente ao fim do treino.
const frasesTreinoIncompleto = <String>[
  'Faz parte do processo. O importante é não parar!',
  'Cada tentativa te deixa mais perto da meta. Siga firme!',
  'Falhar hoje significa que você se desafiou de verdade.',
  'Não deu hoje, mas o progresso continua acumulando.',
  'Guerreiros também têm dias difíceis. Levante a cabeça!',
  'Amanhã você estará mais forte do que hoje. Pode apostar!',
  'A consistência é feita de dias bons e dias difíceis. Continue!',
  'Hoje você construiu base. Amanhã você supera.',
  'Sem pressa, mas sem pausa. O resultado vem!',
  'O único treino ruim é aquele que não acontece. Parabéns pela tentativa!',
  'A queda de hoje é a base da sua evolução de amanhã.',
  'Orgulhe-se de ter tentado. Poucos têm essa coragem!',
  'Dias cinzas também fazem parte da jornada. Foco no objetivo!',
  'Seu corpo aprendeu algo novo hoje, mesmo sem você perceber.',
  'Ajuste o foco, até a próxima melhor sessão!',
];

/// Uma frase aleatória para o fim de um treino não concluído.
String fraseIncompletoAleatoria() =>
    frasesTreinoIncompleto[Random().nextInt(frasesTreinoIncompleto.length)];

/// Frases mostradas quando a pessoa COMPLETA o treino. Comemoram o esforço.
/// Uma é sorteada aleatoriamente ao fim do treino concluído.
const frasesTreinoCompleto = <String>[
  'Missão cumprida! Você foi até o fim. 💪',
  'Isso! Mais um treino na conta. Orgulhe-se!',
  'Disciplina em ação — você apareceu e fez acontecer!',
  'Forte hoje, mais forte amanhã. Excelente treino!',
  'Concluído! É assim que se constrói consistência.',
  'Você não negociou com a preguiça. Respeito!',
  'Mais um tijolo na sua evolução. Muito bem!',
  'Treino fechado! Seu "eu" do futuro agradece.',
  'Suou, resistiu, terminou. Guerreiro(a)!',
  'Feito é melhor que perfeito — e você fez. Parabéns!',
  'A régua subiu de novo. Bora manter o ritmo!',
  'Cada série te aproxima da sua melhor versão. 🔥',
];

/// Uma frase aleatória para o fim de um treino concluído.
String fraseCompletoAleatoria() =>
    frasesTreinoCompleto[Random().nextInt(frasesTreinoCompleto.length)];

/// Frases dos LEMBRETES de treino (notificação agendada nos dias com treino).
/// Chamam para a ação — uma é sorteada ao (re)agendar cada lembrete da semana.
const frasesLembrete = <String>[
  'Bora, guerreiro(a)! Sua melhora de potencial te espera. 💪',
  'Hora do treino. Seu "eu" do futuro agradece por você aparecer!',
  'Levanta e vai: 20 minutos hoje valem mais que a intenção de amanhã.',
  'A régua sobe com quem aparece. Bora treinar! 🔥',
  'Disciplina é fazer mesmo sem vontade. Seu treino te espera!',
  'Mais um dia, mais um tijolo na sua evolução. Vamos?',
  'Seu corpo pediu movimento. Atenda o chamado! 💪',
  'Consistência vence talento. Hoje é dia de somar mais um.',
  'Não negocie com a preguiça. 3, 2, 1... treino!',
  'Cada série te aproxima da sua melhor versão. Bora fechar mais uma!',
  'Guerreiro(a) não falta ao próprio propósito. Hora de treinar!',
  'O treino de hoje é a força de amanhã. Vamos com tudo!',
];

/// Uma frase aleatória para o lembrete de treino.
String fraseLembreteAleatoria() =>
    frasesLembrete[Random().nextInt(frasesLembrete.length)];
