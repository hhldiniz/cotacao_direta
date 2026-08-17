import 'notification_permission_status.dart';
import 'notification_service_io.dart'
    if (dart.library.js_interop) 'notification_service_web.dart';

export 'notification_permission_status.dart';

/// Notificações do sistema avisando que um alerta de câmbio foi atingido.
///
/// Cada plataforma resolve isto de um jeito: Android e Linux pelo
/// flutter_local_notifications, a web pela Notification API do navegador. O
/// que muda de verdade entre elas é a permissão — nativamente ela é pedida uma
/// vez na inicialização, e no navegador ela só pode ser pedida a partir de um
/// toque do usuário, daí [permissionStatus] e [requestPermission] serem parte
/// da interface e não um detalhe escondido do [initialize].
class NotificationService {
  static NotificationService? _instance;

  factory NotificationService() {
    if (_instance == null) _instance = NotificationService._internalConstructor();
    return _instance!;
  }

  NotificationService._internalConstructor();

  Future<void> initialize() => initializePlatformNotifications();

  /// Estado da permissão agora, sem pedir nada ao usuário.
  Future<NotificationPermissionStatus> permissionStatus() =>
      readNotificationPermission();

  /// Abre o pedido de permissão e devolve o estado depois da resposta.
  ///
  /// Na web precisa ser chamado de dentro de um gesto do usuário (o toque num
  /// botão): o Safari, em especial, ignora o pedido feito fora disso.
  Future<NotificationPermissionStatus> requestPermission() =>
      requestNotificationPermission();

  Future<void> showAlertTriggered(
          {required int id, required String title, required String body}) =>
      showPlatformNotification(id: id, title: title, body: body);
}
