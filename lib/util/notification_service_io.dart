import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificações locais fora da web (Android e Linux Desktop).
final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

Future<void> initializePlatformNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Abrir');
  const settings =
      InitializationSettings(android: androidSettings, linux: linuxSettings);
  await _plugin.initialize(settings);
  // No Android 13+ a notificação só aparece com a permissão concedida em
  // tempo de execução; nas demais plataformas suportadas isto é um no-op.
  await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

Future<void> showPlatformNotification(
    {required int id, required String title, required String body}) async {
  const androidDetails = AndroidNotificationDetails(
    'currency_alerts_channel',
    'Alertas de câmbio',
    channelDescription: 'Notificações de alertas de câmbio atingidos',
    importance: Importance.high,
    priority: Priority.high,
  );
  const linuxDetails = LinuxNotificationDetails();
  const details =
      NotificationDetails(android: androidDetails, linux: linuxDetails);
  await _plugin.show(id, title, body, details);
}
