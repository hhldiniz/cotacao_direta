import 'notification_service_io.dart'
    if (dart.library.js_interop) 'notification_service_web.dart';

class NotificationService {
  static NotificationService? _instance;

  factory NotificationService() {
    if (_instance == null) _instance = NotificationService._internalConstructor();
    return _instance!;
  }

  NotificationService._internalConstructor();

  Future<void> initialize() => initializePlatformNotifications();

  Future<void> showAlertTriggered(
          {required int id, required String title, required String body}) =>
      showPlatformNotification(id: id, title: title, body: body);
}
