/// Em que ponto está a instalação do app como PWA no aparelho de quem abriu a
/// página.
///
/// Fica num arquivo separado do serviço porque as duas implementações de
/// plataforma (io e web) precisam do mesmo tipo, e nenhuma delas pode importar
/// o arquivo que as escolhe.
enum PwaInstallStatus {
  /// Não há instalação a oferecer: ou o app não está rodando na web, ou o
  /// navegador não expõe nenhum caminho para instalá-lo.
  unsupported,

  /// A página já está rodando como app instalado (fora de uma aba comum).
  installed,

  /// O navegador guardou o pedido de instalação e o app pode abri-lo.
  promptable,

  /// Dá para instalar, mas só pelo menu do navegador — o caso do Safari no
  /// iOS, que não oferece o pedido de instalação a quem faz a página.
  manual,
}
