import 'background_alert_service_io.dart'
    if (dart.library.js_interop) 'background_alert_service_web.dart';

/// Checagem periódica dos alertas de câmbio com o app fechado.
///
/// Existe só no Android, onde o WorkManager do sistema acorda o app de tempos
/// em tempos. Nas outras plataformas os alertas continuam sendo conferidos
/// quando a tela inicial busca cotações (ver `home.dart`):
///
/// - na web não há como rodar código periodicamente em segundo plano sem um
///   servidor que envie os pushes — o Safari, em especial, não implementa
///   Periodic Background Sync, então nem no PWA instalado isso existe;
/// - no Linux Desktop o app só roda enquanto a janela está aberta.
Future<void> startBackgroundAlertChecks() =>
    startPlatformBackgroundAlertChecks();
