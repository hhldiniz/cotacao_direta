import 'package:flutter/material.dart';

/// O ScaffoldMessenger da raiz do app, para avisos que nascem fora de uma tela.
///
/// Os alertas de câmbio são conferidos por um bloc, sem [BuildContext] à mão;
/// com a chave ligada ao `scaffoldMessengerKey` do MaterialApp, o aviso
/// aparece por cima de qualquer tela que estiver aberta.
final GlobalKey<ScaffoldMessengerState> inAppNotificationsKey =
    GlobalKey<ScaffoldMessengerState>();

/// Mostra um aviso dentro do próprio app, no lugar da notificação do sistema.
///
/// Devolve false quando não há app montado para mostrá-lo (a checagem em
/// segundo plano, por exemplo).
bool showInAppNotification({required String title, required String body}) {
  final messenger = inAppNotificationsKey.currentState;
  if (messenger == null) return false;
  messenger.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 8),
    showCloseIcon: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(body),
      ],
    ),
  ));
  return true;
}
