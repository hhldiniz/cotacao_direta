/// A web não tem uma implementação de notificações locais neste app: o
/// usuário ainda cria e acompanha os alertas normalmente pela tela de
/// alertas, só não recebe uma notificação do sistema quando um deles é
/// atingido.
Future<void> initializePlatformNotifications() async {}

Future<void> showPlatformNotification(
    {required int id, required String title, required String body}) async {}
