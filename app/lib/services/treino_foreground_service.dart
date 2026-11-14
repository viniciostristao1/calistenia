import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Cronômetro do treino visível com o app minimizado (ex.: bike).
///
/// Usa um *foreground service* (`flutter_foreground_task`) com notificação
/// persistente: o Android mostra essa notificação na barra de status, na tela
/// de bloqueio e — em aparelhos com "ilha dinâmica"/pílula (Samsung, Xiaomi,
/// Motorola...) — como cartão flutuante. Sem ela, o app pausava ao minimizar
/// e o tempo sumia da tela.
///
/// O tempo em si continua sendo contado pelo `PlayerScreen` (isolate da UI);
/// o service só mantém o processo em prioridade de foreground (o Timer não é
/// suspenso) e exibe o texto atualizado via [atualizar]. O `TaskHandler` é
/// intencionalmente mínimo (sem `onRepeatEvent`): a UI empurra o texto a cada
/// segundo cheio.
class TreinoForegroundService {
  TreinoForegroundService._();

  static const String canalId = 'calis_treino_v1';
  static const String canalNome = 'Cronômetro do treino';
  static const String canalDescricao =
      'Mostra o tempo do treino com o app minimizado';

  static bool _initOk = false;

  /// Configura o plugin (canal + opções). Idempotente.
  static void init() {
    if (_initOk) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: canalId,
        channelName: canalNome,
        channelDescription: canalDescricao,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: false,
        showBadge: false,
        onlyAlertOnce: true,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
        stopWithTask: true,
      ),
    );
    _initOk = true;
  }

  /// Garante permissão de notificação (Android 13+). Retorna true se pode exibir.
  static Future<bool> garantirPermissao() async {
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status == NotificationPermission.granted) return true;
    final novo = await FlutterForegroundTask.requestNotificationPermission();
    return novo == NotificationPermission.granted;
  }

  /// Sobe o service com o texto inicial. Se já estiver rodando, só atualiza.
  static Future<bool> iniciar({
    required String titulo,
    required String texto,
  }) async {
    init();
    if (await FlutterForegroundTask.isRunningService) {
      return atualizar(titulo: titulo, texto: texto);
    }
    final r = await FlutterForegroundTask.startService(
      serviceId: 5001,
      serviceTypes: [ForegroundServiceTypes.health],
      notificationTitle: titulo,
      notificationText: texto,
      notificationInitialRoute: '/',
      callback: inicioCallback,
    );
    return r is ServiceRequestSuccess;
  }

  /// Atualiza título/texto da notificação persistente. Silencioso se parada.
  static Future<bool> atualizar({
    required String titulo,
    required String texto,
  }) async {
    if (!await FlutterForegroundTask.isRunningService) return false;
    final r = await FlutterForegroundTask.updateService(
      notificationTitle: titulo,
      notificationText: texto,
    );
    return r is ServiceRequestSuccess;
  }

  /// Derruba o service (some a notificação). Silencioso se já parado.
  static Future<void> parar() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}

/// Callback de entrada do service (precisa ser top-level).
@pragma('vm:entry-point')
void inicioCallback() {
  FlutterForegroundTask.setTaskHandler(_TreinoTaskHandler());
}

/// Handler mínimo: sem tick próprio — a UI empurra o texto via `atualizar`.
class _TreinoTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
