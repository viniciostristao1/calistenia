import '../services/idioma_repository.dart';

class Strings {
  final Idioma idioma;
  const Strings(this.idioma);

  static Strings of(Idioma idioma) => Strings(idioma);

  String _t(String pt, String en, String es) => switch (idioma) {
        Idioma.en => en,
        Idioma.es => es,
        Idioma.pt => pt,
      };

  // Config
  String get configTitulo => _t('Configurações', 'Settings', 'Configuración');
  String get tema => _t('Tema', 'Theme', 'Tema');
  String get temaDesc => _t('Muda as cores e o visual do app inteiro.', 'Changes colors and look of the whole app.', 'Cambia los colores y el aspecto de toda la app.');
  String get idioma => _t('Idioma', 'Language', 'Idioma');
  String get idiomaDesc => _t('Escolha o idioma do app.', 'Choose the app language.', 'Elige el idioma de la app.');
  String get som => _t('Som', 'Sound', 'Sonido');
  String get somDesc => _t('Bips nas transições e no fim do treino.', 'Beeps on transitions and at workout end.', 'Pitidos en transiciones y al final del entreno.');
  String get gamificacao => _t('Gamificação', 'Gamification', 'Gamificación');
  String get gamificacaoDesc => _t('Medalhas, troféus e a pergunta “treino completo?” no fim do treino.', 'Medals, trophies and the “workout complete?” prompt at the end.', 'Medallas, trofeos y la pregunta “¿entreno completo?” al final.');
  String get lembrarTreinar => _t('Lembrar de treinar', 'Training reminders', 'Recordatorios');
  String get lembrarDescOn => _t('Notificação ligada nos dias com treino.', 'Notifications on for training days.', 'Notificaciones activas en días con entreno.');
  String get lembrarDescOff => _t('Desligado.', 'Off.', 'Desactivado.');
  String get nenhumTreinoAgendado => _t('Nenhum treino agendado ainda. Marque os dias de um treino no editor para o lembrete aparecer aqui.', 'No training scheduled yet. Assign days to a workout in the editor to see reminders here.', 'Aún no hay entreno programado. Asigna días a un entreno en el editor para ver recordatorios aquí.');
  String get gerenciarHorarios => _t('Gerenciar horários', 'Manage schedules', 'Gestionar horarios');
  String get ocultarHorarios => _t('Ocultar horários', 'Hide schedules', 'Ocultar horarios');
  String diasCount(int n) => _t('$n ${n == 1 ? 'dia' : 'dias'}', '$n ${n == 1 ? 'day' : 'days'}', '$n ${n == 1 ? 'día' : 'días'}');
  String get conta => _t('Conta', 'Account', 'Cuenta');
  String get contaDesc => _t('Entre com Google para guardar treinos, check-ins e progressão na sua conta e recuperá-los em qualquer aparelho.', 'Sign in with Google to save workouts, check-ins and progress to your account and restore on any device.', 'Inicia sesión con Google para guardar entrenos, check-ins y progreso en tu cuenta y restaurarlos en cualquier dispositivo.');
  String get entrarGoogle => _t('Entrar com Google', 'Sign in with Google', 'Iniciar sesión con Google');
  String get sair => _t('Sair', 'Sign out', 'Cerrar sesión');
  String get conectado => _t('Conectado', 'Connected', 'Conectado');
  String get backupArquivo => _t('Backup em arquivo', 'File backup', 'Copia en archivo');
  String get backupDesc => _t('Uma segunda via, independente da conta: exporte tudo (treinos, progressão, check-ins, conquistas) num arquivo .json e restaure quando quiser.', 'A second copy, independent of the account: export everything (workouts, progress, check-ins, achievements) to a .json file and restore anytime.', 'Una segunda copia, independiente de la cuenta: exporta todo (entrenos, progreso, check-ins, logros) a un .json y restaura cuando quieras.');
  String get exportar => _t('Exportar', 'Export', 'Exportar');
  String get importar => _t('Importar', 'Import', 'Importar');

  // Home / Root
  String get treinos => _t('Treinos', 'Workouts', 'Entrenos');
  String get novoTreino => _t('Novo treino', 'New workout', 'Nuevo entreno');
  String nenhumTreinoEm(String dia) => _t('Nenhum treino em $dia', 'No workout on $dia', 'Ningún entreno en $dia');
  String get toqueNovoTreino => _t('Toque em “Novo treino” para criar.', 'Tap “New workout” to create one.', 'Toca “Nuevo entreno” para crear.');
  String get compartilharDia => _t('Compartilhar o dia', 'Share day', 'Compartir día');
  String get compartilharSemana => _t('Compartilhar a semana toda', 'Share whole week', 'Compartir toda la semana');
  String get nenhumTreinoDiaCompartilhar => _t('Nenhum treino neste dia para compartilhar.', 'No workout this day to share.', 'Ningún entreno este día para compartir.');
  String get nenhumTreinoCadastrado => _t('Nenhum treino cadastrado ainda.', 'No workouts yet.', 'Aún no hay entrenos.');
  String get sairApp => _t('Sair do app?', 'Exit app?', '¿Salir de la app?');
  String get cancelar => _t('Cancelar', 'Cancel', 'Cancelar');
  String get fechar => _t('Fechar', 'Close', 'Cerrar');
  String get copiar => _t('Copiar', 'Copy', 'Copiar');
  String get copiado => _t('Copiado!', 'Copied!', '¡Copiado!');
  String get sair => _t('Sair', 'Exit', 'Salir');

  // Check-in
  String get checkIn => _t('Check-in', 'Check-in', 'Check-in');
  String get calendario => _t('Calendário', 'Calendar', 'Calendario');
  String get galeria => _t('Galeria', 'Gallery', 'Galería');
  String get historico => _t('Histórico', 'History', 'Historial');
  String get nenhumDiaMarcado => _t('Nenhum dia marcado', 'No day marked', 'Ningún día marcado');
  String diasTreinados(int n) => _t('$n ${n == 1 ? 'dia' : 'dias'} treinados', '$n ${n == 1 ? 'day' : 'days'} trained', '$n ${n == 1 ? 'día' : 'días'} entrenados');
  String get insigniasDoMes => _t('Insígnias do mês', 'Badges of the month', 'Insignias del mes');
  String get mesPerfeito => _t('Mês perfeito! ✨', 'Perfect month! ✨', '¡Mes perfecto! ✨');
  String get sequenciaRisco => _t('Sequência em risco — treine hoje para não perder seu nível!', 'Streak at risk — train today to keep your level!', '¡Racha en riesgo — entrena hoy para no perder tu nivel!');
  String get conquistasAtuais => _t('Conquistas atuais', 'Current achievements', 'Logros actuales');
  String get nenhumaConquista => _t('Nenhuma conquista ativa ainda. Complete treinos para conquistar!', 'No active achievements yet. Complete workouts to earn them!', '¡Aún no hay logros activos. ¡Completa entrenos para conseguirlos!');
  String get medalhas => _t('Medalhas', 'Medals', 'Medallas');
  String get trofeus => _t('Troféus', 'Trophies', 'Trofeos');
  String get trofeusDesc => _t('Sequências mais longas (o Ouro pede progressão)', 'Longest streaks (Gold needs progress)', 'Rachas más largas (Oro requiere progreso)');
  String get diasSeguidos => _t('Dias de treino seguidos', 'Consecutive training days', 'Días de entreno seguidos');
  String get insignias => _t('Insígnias', 'Badges', 'Insignias');
  String get insigniasDesc => _t('Estrelas ganhas em meses anteriores', 'Stars earned in past months', 'Estrellas ganadas en meses anteriores');
  String get titulosPerdidos => _t('Títulos perdidos', 'Lost titles', 'Títulos perdidos');
  String get titulosPerdidosDesc => _t('Medalhas e troféus por quebra de sequência', 'Medals and trophies lost by breaking streak', 'Medallas y trofeos perdidos por romper la racha');
  String get historicoVazio => _t('Histórico vazio', 'History empty', 'Historial vacío');
  String get historicoVazioDesc => _t('As estrelas ganhas em meses anteriores e os títulos perdidos (quebra de sequência) ficam guardados aqui, por mês.', 'Stars from past months and lost titles (broken streak) are saved here, by month.', 'Las estrellas de meses anteriores y los títulos perdidos (racha rota) se guardan aquí, por mes.');
  String get sequenciaAtual => _t('Sequência atual', 'Current streak', 'Racha actual');
  String dias(int n) => _t('$n ${n == 1 ? 'dia' : 'dias'}', '$n ${n == 1 ? 'day' : 'days'}', '$n ${n == 1 ? 'día' : 'días'}');
  String get recorde => _t('Recorde', 'Record', 'Récord');
  String get diasNoTotal => _t('dias no total', 'days total', 'días en total');
  String get nenhumExercicioDia => _t('Nenhum exercício marcado neste dia.', 'No exercise marked this day.', 'Ningún ejercicio marcado este día.');
  String get marcarExercicio => _t('Marcar exercício', 'Mark exercise', 'Marcar ejercicio');
  String get marcarQualExercicio => _t('Marcar qual exercício?', 'Mark which exercise?', '¿Marcar qué ejercicio?');
  String get crieExerciciosPrimeiro => _t('Crie exercícios nos treinos primeiro.', 'Create exercises in workouts first.', 'Crea ejercicios en los entrenos primero.');

  // Progressao
  String get progressao => _t('Progressão', 'Progress', 'Progreso');
  String get desenvolvimento => _t('Desenvolvimento', 'Development', 'Desarrollo');
  String get rating => _t('Rating', 'Rating', 'Rating');
  String get tendencia => _t('Tendência', 'Trend', 'Tendencia');
  String get seuRatingSemanas => _t('Seu Rating nas últimas semanas.', 'Your Rating in recent weeks.', 'Tu Rating en las últimas semanas.');
  String get ratingDesc => _t('Rating 0–100 = Consistência (0–40, % dos dias agendados nos últimos 28 dias — hoje é neutro) + Frequência (0–20, seu volume de treino) + Progressão (0–40, o quanto seus recordes — de repetições OU de peso — melhoraram nos últimos ~42 dias). Consistência é o alicerce; para passar do platô, bata recordes.', 'Rating 0–100 = Consistency (0–40, % of scheduled days in last 28 days — today is neutral) + Frequency (0–20, your training volume) + Progress (0–40, how much your records — reps OR weight — improved in ~42 days). Consistency is the base; to break the plateau, beat records.', 'Rating 0–100 = Consistencia (0–40, % de días programados en últimos 28 días — hoy es neutral) + Frecuencia (0–20, tu volumen) + Progreso (0–40, cuánto mejoraron tus récords — reps O peso — en ~42 días). La consistencia es la base; para superar el estancamiento, bate récords.');
  String get nenhumaProgressao => _t('Nenhuma progressão ainda', 'No progress yet', 'Aún no hay progreso');
  String get nenhumaProgressaoDesc => _t('Ao editar um exercício, toque em “Adicionar à progressão” para registrar quantas repetições você fez. A evolução aparece aqui em barras.', 'When editing an exercise, tap “Add to progress” to log how many reps you did. Progress appears here as bars.', 'Al editar un ejercicio, toca “Añadir al progreso” para registrar cuántas reps hiciste. La evolución aparece aquí en barras.');

  // Player
  String get voceCompletouTreino => _t('Você completou o treino?', 'Did you complete the workout?', '¿Completaste el entreno?');
  String get todasRepsPlanejado => _t('Todas as repetições, do jeito que você planejou.', 'All reps, as you planned.', 'Todas las reps, como planeaste.');
  String get simCompletei => _t('Sim, completei', 'Yes, I did', 'Sí, completé');
  String get naoConseguiHoje => _t('Não consegui hoje', 'Could not today', 'No pude hoy');
  String get treinoCompleto => _t('Treino completo!', 'Workout complete!', '¡Entreno completo!');
  String get checkinConcluido => _t('Check-in concluído', 'Check-in done', 'Check-in completado');
  String get fazParte => _t('Faz parte do processo. O importante é não parar!', 'It’s part of the process. The key is not to stop!', 'Es parte del proceso. ¡Lo importante es no parar!');
  String get esforçoConta => _t('Seu esforço conta: metade da consistência e a sua sequência mantida.', 'Your effort counts: half consistency and your streak kept.', 'Tu esfuerzo cuenta: mitad de consistencia y tu racha mantenida.');
  String get repetirTreino => _t('Repetir treino', 'Repeat workout', 'Repetir entreno');
  String get tentarDeNovo => _t('Tentar de novo', 'Try again', 'Intentar de nuevo');
  String get voltar => _t('Voltar', 'Back', 'Volver');

  // Dias
  List<String> get diasCurtos => switch (idioma) {
        Idioma.en => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        Idioma.es => ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
        Idioma.pt => ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
      };
  List<String> get diasLongos => switch (idioma) {
        Idioma.en => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        Idioma.es => ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'],
        Idioma.pt => ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'],
      };
  List<String> get meses => switch (idioma) {
        Idioma.en => ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
        Idioma.es => ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
        Idioma.pt => ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'],
      };
}
