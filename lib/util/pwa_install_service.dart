import 'pwa_install_service_io.dart'
    if (dart.library.js_interop) 'pwa_install_service_web.dart';
import 'pwa_install_status.dart';

export 'pwa_install_status.dart';

/// Instalação do app como PWA: adicionar a versão web ao aparelho, para abrir
/// pelo ícone e em janela própria, sem a barra do navegador.
///
/// Quem oferece a instalação é o navegador, e só depois de aceitar o site como
/// instalável (manifest, service worker e HTTPS). Esta classe é a leitura, do
/// lado Flutter, do que ele decidiu — nas outras plataformas ela responde
/// sempre [PwaInstallStatus.unsupported].
class PwaInstallService {
  PwaInstallService._();

  /// Estado no momento da chamada.
  static PwaInstallStatus get status => readPwaInstallStatus();

  /// Emite a cada mudança de estado: o navegador liberar a instalação, o app
  /// ser instalado, a janela passar a rodar instalada.
  static Stream<PwaInstallStatus> get statusChanges =>
      pwaInstallStatusChanges();

  /// Abre o pedido de instalação do navegador e espera a resposta. Devolve
  /// `true` se o usuário aceitou instalar.
  static Future<bool> promptInstall() => promptPwaInstall();
}
