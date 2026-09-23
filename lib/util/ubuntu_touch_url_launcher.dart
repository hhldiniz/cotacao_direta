import 'package:flutter/services.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'ubuntu_touch.dart';

/// Abre links pelo URL dispatcher do Lomiri, no Ubuntu Touch.
///
/// O url_launcher do Linux usa o gtk_show_uri, que procura um .desktop que
/// trate `https:`. Um app confinado não enxerga nenhum, então o link
/// simplesmente não abria. No Ubuntu Touch o caminho é pedir ao
/// com.lomiri.URLDispatcher (por DBus, que o perfil padrão do AppArmor já
/// libera) que abra a URL no app certo — o navegador, no caso de `https:`. A
/// chamada ao DBus fica no runner nativo (linux/runner/url_dispatcher.cc).
///
/// Instalado por [registerIfNeeded] como a implementação do url_launcher, os
/// chamadores continuam usando o `launchUrl` de sempre.
class UbuntuTouchUrlLauncher extends UrlLauncherPlatform {
  static const MethodChannel channel =
      MethodChannel('cotacao_direta/url_dispatcher');

  /// Troca a implementação do url_launcher por esta, só no Ubuntu Touch.
  static void registerIfNeeded() {
    if (isUbuntuTouch) UrlLauncherPlatform.instance = UbuntuTouchUrlLauncher();
  }

  @override
  LinkDelegate? get linkDelegate => null;

  /// O dispatcher aceita qualquer esquema; se nenhum app tratar a URL, quem
  /// avisa o usuário é o próprio sistema.
  @override
  Future<bool> canLaunch(String url) async =>
      Uri.tryParse(url)?.hasScheme ?? false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) => _dispatch(url);

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) =>
      _dispatch(url);

  /// Não há web view embutida: tudo abre em outro app.
  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async =>
      mode == PreferredLaunchMode.platformDefault ||
      mode == PreferredLaunchMode.externalApplication;

  Future<bool> _dispatch(String url) async =>
      await channel.invokeMethod<bool>('dispatch', url) ?? false;
}
