import 'dart:async';
import 'dart:js_interop';

import 'pwa_install_status.dart';

/// Objeto montado pelo script de `web/index.html`, que é quem de fato ouve o
/// `beforeinstallprompt` do navegador. Ver o comentário de lá para o porquê de
/// a escuta não poder começar aqui.
@JS('cotacaoDiretaPwa')
external JSObject? get _bridgeObject;

extension type _PwaBridge._(JSObject _) implements JSObject {
  external bool get canInstall;

  external bool get isInstalled;

  external bool get isIos;

  /// Resolve com o desfecho do pedido de instalação: `accepted`, `dismissed`
  /// ou `unavailable`.
  external JSPromise<JSString> promptInstall();

  external void onChange(JSFunction callback);
}

/// Nulo só se a página tiver sido servida por um `index.html` antigo, sem o
/// script da ponte; aí não há instalação a oferecer.
_PwaBridge? get _bridge {
  final object = _bridgeObject;
  return object == null ? null : _PwaBridge._(object);
}

/// Um controlador para a página inteira: o `onChange` do lado JavaScript não
/// tem como cancelar a inscrição, então registrar um ouvinte novo a cada
/// chamada acumularia ouvintes enquanto o app roda.
StreamController<PwaInstallStatus>? _statusController;

PwaInstallStatus readPwaInstallStatus() {
  final bridge = _bridge;
  if (bridge == null) return PwaInstallStatus.unsupported;
  if (bridge.isInstalled) return PwaInstallStatus.installed;
  if (bridge.canInstall) return PwaInstallStatus.promptable;
  if (bridge.isIos) return PwaInstallStatus.manual;
  return PwaInstallStatus.unsupported;
}

Stream<PwaInstallStatus> pwaInstallStatusChanges() {
  final bridge = _bridge;
  if (bridge == null) return const Stream<PwaInstallStatus>.empty();

  var controller = _statusController;
  if (controller == null) {
    controller = StreamController<PwaInstallStatus>.broadcast();
    _statusController = controller;
    final target = controller;
    bridge.onChange((() {
      target.add(readPwaInstallStatus());
    }).toJS);
  }
  return controller.stream;
}

Future<bool> promptPwaInstall() async {
  final bridge = _bridge;
  if (bridge == null) return false;
  final outcome = (await bridge.promptInstall().toDart).toDart;
  return outcome == 'accepted';
}
