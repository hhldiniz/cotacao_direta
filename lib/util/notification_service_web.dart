import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'notification_permission_status.dart';
import 'pwa_install_service.dart';

// Notificações na web, pela Notification API do navegador.
//
// Três detalhes separam esta implementação da nativa:
//
// - a permissão só pode ser pedida de dentro de um gesto do usuário, então
//   quem chama `requestNotificationPermission` é o botão do cartão da tela de
//   alertas, e não a inicialização do app;
// - no iOS e no iPadOS o `Notification` só existe quando a página roda a
//   partir do ícone na Tela de Início. Numa aba do Safari ele nem é definido,
//   e é por isso que um teste no navegador não mostra notificação nenhuma:
//   não há permissão a conceder ali, e sim um app a instalar antes;
// - ainda no iOS, `new Notification(...)` é um construtor ilegal: a
//   notificação tem de sair pelo registro do service worker. Como o do app já
//   é registrado por `web/flutter_bootstrap.js`, é ele o caminho principal
//   aqui, com o construtor ficando de reserva para o `flutter run -d chrome`,
//   que roda sem service worker.

@JS('Notification.permission')
external String get _permission;

@JS('Notification.requestPermission')
external JSPromise<JSString> _requestPermission();

@JS('navigator.serviceWorker')
external _ServiceWorkerContainer? get _serviceWorkerContainer;

extension type _ServiceWorkerContainer._(JSObject _) implements JSObject {
  /// Resolve com o registro do service worker do app, ou com `undefined`
  /// quando não há nenhum — daí o tipo anulável, e não `ready`, que fica
  /// pendente para sempre nesse caso.
  external JSPromise<_ServiceWorkerRegistration?> getRegistration();
}

extension type _ServiceWorkerRegistration._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> showNotification(
      String title, _NotificationOptions options);
}

extension type _NotificationOptions._(JSObject _) implements JSObject {
  external factory _NotificationOptions({
    String body,
    String tag,
    String icon,
    String badge,
  });
}

@JS('Notification')
extension type _Notification._(JSObject _) implements JSObject {
  external factory _Notification(String title, _NotificationOptions options);
}

/// O navegador conhece a API? No iOS isto é `false` fora do app instalado.
bool get _hasNotificationApi => globalContext.has('Notification');

/// Nada a fazer na inicialização: pedir a permissão aqui, longe de um toque do
/// usuário, é recusado pelos navegadores (e no Safari nem chega a perguntar).
Future<void> initializePlatformNotifications() async {}

Future<NotificationPermissionStatus> readNotificationPermission() async {
  if (!_hasNotificationApi) {
    // O `manual` do serviço de instalação é exatamente o caso do iOS numa aba
    // comum: o aparelho até faz notificação, mas só depois de o app ser
    // adicionado à Tela de Início.
    return PwaInstallService.status == PwaInstallStatus.manual
        ? NotificationPermissionStatus.requiresInstall
        : NotificationPermissionStatus.unsupported;
  }
  return switch (_permission) {
    'granted' => NotificationPermissionStatus.granted,
    'denied' => NotificationPermissionStatus.denied,
    _ => NotificationPermissionStatus.notRequested,
  };
}

Future<NotificationPermissionStatus> requestNotificationPermission() async {
  final current = await readNotificationPermission();
  // Depois de uma recusa o navegador responde 'denied' na hora, sem perguntar
  // de novo; nos outros casos não há o que pedir.
  if (current != NotificationPermissionStatus.notRequested) return current;

  try {
    final outcome = (await _requestPermission().toDart).toDart;
    return switch (outcome) {
      'granted' => NotificationPermissionStatus.granted,
      'denied' => NotificationPermissionStatus.denied,
      _ => NotificationPermissionStatus.notRequested,
    };
  } catch (error) {
    // Navegador antigo, em que requestPermission só aceita callback e não
    // devolve Promise: sem como esperar a resposta, o estado atual é o que dá
    // para afirmar.
    return readNotificationPermission();
  }
}

Future<void> showPlatformNotification(
    {required int id, required String title, required String body}) async {
  if (await readNotificationPermission() !=
      NotificationPermissionStatus.granted) {
    return;
  }

  final options = _NotificationOptions(
    body: body,
    // Uma notificação por alerta: se o mesmo alerta for notificado de novo, a
    // nova substitui a anterior em vez de empilhar.
    tag: 'currency-alert-$id',
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
  );

  // Uma notificação que não sai não pode derrubar a checagem dos alertas
  // seguintes, então cada tentativa vai protegida.
  try {
    final registration = await _serviceWorkerContainer?.getRegistration().toDart;
    if (registration != null) {
      await registration.showNotification(title, options).toDart;
      return;
    }
  } catch (error) {
    // Service worker ainda instalando, por exemplo: cai no construtor abaixo.
  }

  // Sem service worker — o caso do `flutter run -d chrome`, que não registra
  // nenhum — resta o construtor, que funciona no desktop. No iOS ele lança
  // ("Illegal constructor"), e lá não há segundo caminho a tentar.
  try {
    _Notification(title, options);
  } catch (error) {
    return;
  }
}
