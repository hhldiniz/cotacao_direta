import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'in_app_notifications.dart';
import 'notification_permission_status.dart';
import 'ubuntu_touch.dart';

/// Notificações locais fora da web (Android e Linux Desktop).
///
/// No Ubuntu Touch o aviso fica dentro do app. O flutter_local_notifications
/// fala org.freedesktop.Notifications, que o AppArmor nega a um app confinado,
/// e o caminho nativo do sistema (o Postal, do lomiri-push-service) descarta a
/// notificação quando o app está em primeiro plano. Como o Lomiri suspende o
/// app assim que ele sai da tela, e os alertas só são conferidos com ele
/// rodando, o primeiro plano é justamente o único momento em que um alerta
/// dispara por lá: uma notificação do sistema nunca chegaria a aparecer.
final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

Future<void> initializePlatformNotifications() async {
  if (isUbuntuTouch) return;
  // O ícone pequeno da notificação é recortado pelo canal alfa, então usar
  // o @mipmap/ic_launcher (opaco) deixaria só um quadrado branco na barra
  // de status. A camada monocromática do ícone é a marca sobre fundo
  // transparente, que é exatamente o formato esperado aqui — a cor dela não
  // importa, porque o sistema tinge a silhueta.
  const androidSettings =
      AndroidInitializationSettings('@drawable/ic_launcher_monochrome');
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
  if (isUbuntuTouch) {
    showInAppNotification(title: title, body: body);
    return;
  }
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
