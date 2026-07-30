/// Dias da semana. Índice 0 = segunda-feira ... 6 = domingo.
/// (Casa com `DateTime.weekday`, que é 1=seg .. 7=dom.)
const nomesDiasCurtos = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const nomesDiasLongos = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// Índice (0..6) do dia de hoje.
int get diaDeHoje => DateTime.now().weekday - 1;
