import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_permission_status.dart';

/// Notificações locais fora da web (Android e Linux Desktop).
final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

Future<void> initializePlatformNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Abrir');
  const settings =
      InitializationSettings(android: androidSettings, linux: linuxSettings);
  await _plugin.initialize(settings);
  // No Android 13+ a notificação só aparece com a permissão concedida em
  // tempo de execução; nas demais plataformas suportadas isto é um no-op.
  await _android?.requestNotificationsPermission();
}

/// No Linux não existe permissão a conceder, então lá a resposta é sempre
/// [NotificationPermissionStatus.granted]; no Android ela vale o que o usuário
/// respondeu (ou desligou depois, nas configurações do sistema).
Future<NotificationPermissionStatus> readNotificationPermission() async {
  if (!Platform.isAndroid) return NotificationPermissionStatus.granted;
  final enabled = await _android?.areNotificationsEnabled();
  return enabled == false
      ? NotificationPermissionStatus.denied
      : NotificationPermissionStatus.granted;
}

Future<NotificationPermissionStatus> requestNotificationPermission() async {
  if (!Platform.isAndroid) return NotificationPermissionStatus.granted;
  final granted = await _android?.requestNotificationsPermission();
  return granted == false
      ? NotificationPermissionStatus.denied
      : NotificationPermissionStatus.granted;
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
