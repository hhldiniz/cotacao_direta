import 'pwa_install_status.dart';

/// Fora da web não existe instalação como PWA: o app é distribuído como
/// aplicativo nativo, então a opção simplesmente não aparece.
PwaInstallStatus readPwaInstallStatus() => PwaInstallStatus.unsupported;

Stream<PwaInstallStatus> pwaInstallStatusChanges() =>
    const Stream<PwaInstallStatus>.empty();

Future<bool> promptPwaInstall() async => false;
