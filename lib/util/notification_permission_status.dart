/// Em que ponto está a permissão de mostrar notificações do sistema no
/// aparelho de quem abriu o app.
///
/// Fica num arquivo separado do serviço porque as duas implementações de
/// plataforma (io e web) precisam do mesmo tipo, e nenhuma delas pode importar
/// o arquivo que as escolhe.
enum NotificationPermissionStatus {
  /// Não há notificação a pedir: a plataforma (ou o navegador) não tem a API.
  unsupported,

  /// A API existe, mas só depois de o app ser instalado no aparelho. É o caso
  /// do Safari no iOS e no iPadOS: numa aba comum o `Notification` sequer é
  /// definido, e ele só passa a existir quando a página roda a partir do ícone
  /// adicionado à Tela de Início.
  requiresInstall,

  /// Dá para pedir, e ainda não foi pedido.
  notRequested,

  /// O usuário permitiu; as notificações aparecem.
  granted,

  /// O usuário recusou. O navegador não deixa perguntar de novo: só mudando a
  /// permissão nas configurações do site é que volta a funcionar.
  denied,
}
