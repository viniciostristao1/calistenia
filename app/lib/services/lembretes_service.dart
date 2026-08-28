import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../util/frases.dart';
import '../util/gamificacao.dart' show diasAgendados, emRiscoDePerda;
import 'conclusao_repository.dart';
import 'treinos_repository.dart';

const _chaveLembretes = 'lembretes_v1';

/// Base dos ids de notificação: um id por dia da semana (0=seg..6=dom), então
/// os lembretes ocupam [_idBase] .. [_idBase]+6. Fora da faixa dos outros usos.
const int _idBase = 4200;
const int _idRisco = 4300;

/// Configuração dos lembretes de treino: liga/desliga global + horário (minutos
/// do dia, 0..1439) por dia da semana. O lembrete só dispara nos dias que TÊM
/// treino agendado — o horário de um dia sem treino fica guardado, mas inerte.
class LembretesConfig {
  final bool ativo;
  final Map<int, int> horarios; // dia (0=seg..6=dom) -> minutos do dia

  const LembretesConfig({required this.ativo, required this.horarios});

  static const int horarioPadrao = 7 * 60; // 07:00
  static const LembretesConfig vazio =
      LembretesConfig(ativo: false, horarios: {});

  int horarioDe(int dia) => horarios[dia] ?? horarioPadrao;
  int horaDe(int dia) => horarioDe(dia) ~/ 60;
  int minutoDe(int dia) => horarioDe(dia) % 60;

  LembretesConfig comAtivo(bool v) =>
      LembretesConfig(ativo: v, horarios: horarios);

  LembretesConfig comHorario(int dia, int minutos) {
    final m = Map<int, int>.of(horarios)..[dia] = minutos.clamp(0, 1439);
    return LembretesConfig(ativo: ativo, horarios: m);
  }

  Map<String, dynamic> toJson() => {
        'ativo': ativo,
        'horarios': horarios.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory LembretesConfig.fromJson(Map<String, dynamic> j) => LembretesConfig(
        ativo: (j['ativo'] ?? false) as bool,
        horarios: ((j['horarios'] ?? {}) as Map).map(
          (k, v) => MapEntry(int.parse(k as String), (v as num).toInt()),
        ),
      );
}

/// Fonte única da config de lembretes (persistida em `lembretes_v1`).
final lembretesConfigProvider =
    AsyncNotifierProvider<LembretesConfigNotifier, LembretesConfig>(
        LembretesConfigNotifier.new);

class LembretesConfigNotifier extends AsyncNotifier<LembretesConfig> {
  @override
  Future<LembretesConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chaveLembretes);
    if (raw == null || raw.isEmpty) return LembretesConfig.vazio;
    try {
      return LembretesConfig.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return LembretesConfig.vazio;
    }
  }

  Future<void> _salvar(LembretesConfig c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveLembretes, jsonEncode(c.toJson()));
    state = AsyncData(c);
  }

  LembretesConfig get _atual => state.value ?? LembretesConfig.vazio;

  Future<void> definirAtivo(bool v) => _salvar(_atual.comAtivo(v));

  Future<void> definirHorario(int dia, int minutos) =>
      _salvar(_atual.comHorario(dia, minutos));
}

/// Envolve o plugin de notificação local para os lembretes SEMANAIS de treino.
///
/// Cada dia da semana com treino agendado ganha uma notificação que se repete
/// toda semana no mesmo horário (via `matchDateTimeComponents.dayOfWeekAndTime`)
/// — quem dispara é o próprio Android (offline, sobrevive a reboot pelo
/// BootReceiver). Sem app aberto, sem servidor.
///
/// Segue o padrão de horário do `lista_app`/Taskix: monta o instante como
/// TZDateTime em UTC reinterpretando o relógio LOCAL (o Brasil não tem horário
/// de verão), então o dia-da-semana e o HH:MM batem com o relógio de parede.
class LembretesService {
  LembretesService._();
  static final LembretesService instance = LembretesService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  static const String _canalId = 'lembretes_treino_v1';
  static const String _canalNome = 'Lembretes de treino';
  static const String _canalDesc =
      'Aviso motivacional nos dias com treino agendado';

  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    _canalId,
    _canalNome,
    description: _canalDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Inicializa plugin + timezone + canal. Idempotente. Chamado no `main()`.
  Future<void> init() async {
    if (_pronto) return;
    tzdata.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('ic_stat_notif');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );
    await _android?.createNotificationChannel(_canal);
    _pronto = true;
  }

  /// Pede a permissão de notificação (Android 13+). Retorna true se concedida
  /// (ou se não aplicável). Chamado antes de agendar.
  Future<bool> pedirPermissao() async {
    final a = _android;
    if (a == null) return true;
    final ok = await a.requestNotificationsPermission();
    return ok ?? true;
  }

  NotificationDetails _detalhes(String corpo) => NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNome,
          channelDescription: _canalDesc,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          icon: 'ic_stat_notif',
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(corpo),
        ),
      );

  /// Próxima ocorrência (no futuro) do [dia] (0=seg..6=dom) às [hora]:[min],
  /// como TZDateTime em UTC reinterpretando o relógio local.
  tz.TZDateTime _proxima(int dia, int hora, int min) {
    final alvoWeekday = dia + 1; // DateTime.weekday: 1=seg..7=dom
    final agora = DateTime.now();
    var d = DateTime(agora.year, agora.month, agora.day, hora, min);
    // Avança dia a dia até cair no weekday certo E num instante futuro.
    while (d.weekday != alvoWeekday || !d.isAfter(agora)) {
      d = DateTime(d.year, d.month, d.day + 1, hora, min);
    }
    return tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.UTC, d.millisecondsSinceEpoch);
  }

  /// (Re)agenda os lembretes: uma notificação semanal para cada dia em [dias]
  /// (os que têm treino), no horário da [config]. Cancela os demais slots.
  /// Se desligado, sem dias, ou permissão negada, deixa tudo cancelado.
  Future<void> reagendar(LembretesConfig config, Set<int> dias) async {
    if (!_pronto) await init();
    // Zera os 7 slots primeiro (idempotente: reflete exatamente o estado atual).
    for (var d = 0; d < 7; d++) {
      await _plugin.cancel(_idBase + d);
    }
    if (!config.ativo || dias.isEmpty) return;
    if (!await pedirPermissao()) return;

    for (final dia in dias) {
      if (dia < 0 || dia > 6) continue;
      final quando = _proxima(dia, config.horaDe(dia), config.minutoDe(dia));
      final corpo = fraseLembreteAleatoria();
      await _plugin.zonedSchedule(
        _idBase + dia,
        'Hora do treino 💪',
        corpo,
        quando,
        _detalhes(corpo),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Cancela todos os lembretes (ex.: usuário desligou a chave).
  Future<void> cancelarTudo() async {
    for (var d = 0; d < 7; d++) {
      await _plugin.cancel(_idBase + d);
    }
    await _plugin.cancel(_idRisco);
  }

  Future<void> agendarRisco(bool emRisco) async {
    if (!_pronto) await init();
    await _plugin.cancel(_idRisco);
    if (!emRisco) return;
    if (!await pedirPermissao()) return;
    final agora = DateTime.now();
    var alvo = DateTime(agora.year, agora.month, agora.day, 20, 0);
    if (!alvo.isAfter(agora)) return;
    final quando = tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.UTC, alvo.millisecondsSinceEpoch);
    await _plugin.zonedSchedule(
      _idRisco,
      'Sequência em risco ⚠️',
      'Você está a 1 dia de perder seu nível — treine hoje para manter!',
      quando,
      _detalhes('Toque para treinar agora e manter sua sequência.'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

/// Mantém os lembretes em sincronia com a config e com os dias que têm treino.
/// Observado num ponto vivo do app (`ref.watch` no `main`) — reagenda sozinho
/// quando o usuário muda o horário/chave OU quando um treino muda de dia.
final lembretesControllerProvider = Provider<void>((ref) {
  Future<void> agendar() async {
    final config = ref.read(lembretesConfigProvider).value;
    final treinos = ref.read(treinosProvider).value;
    if (config == null || treinos == null) return;
    try {
      await LembretesService.instance
          .reagendar(config, diasAgendados(treinos));
    } catch (_) {}
  }

  Future<void> agendarRisco() async {
    final treinos = ref.read(treinosProvider).value;
    final concs = ref.read(conclusaoProvider).value;
    if (treinos == null || concs == null) return;
    try {
      final risco = emRiscoDePerda(concs, treinos);
      await LembretesService.instance.agendarRisco(risco);
    } catch (_) {}
  }

  ref.listen(lembretesConfigProvider, (_, _) => agendar(), fireImmediately: true);
  ref.listen(treinosProvider, (_, _) {
    agendar();
    agendarRisco();
  }, fireImmediately: true);
  ref.listen(conclusaoProvider, (_, _) => agendarRisco(), fireImmediately: true);
});
