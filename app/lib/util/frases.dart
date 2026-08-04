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
