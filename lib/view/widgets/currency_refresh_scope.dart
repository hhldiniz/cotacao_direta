import 'package:flutter/widgets.dart';

/// Marca, para os widgets de cotação abaixo dela, que os valores em tela
/// precisam ser buscados de novo.
///
/// Existe porque as abas ficam sempre montadas dentro do IndexedStack da tela
/// inicial: sem nada que as avise, as cotações só seriam buscadas uma vez, no
/// primeiro `didChangeDependencies` de cada widget, e continuariam as mesmas
/// depois de trocar a moeda de contrapartida nas configurações.
///
/// Um InheritedWidget resolve isso sem plumbing: quando [revision] muda, o
/// framework chama `didChangeDependencies` em quem dependeu deste escopo, que
/// é justamente onde a busca da cotação já acontecia.
///
/// (Uma Notification não serviria: ela sobe a árvore, e quem precisa saber da
/// atualização está abaixo de quem a dispara.)
class CurrencyRefreshScope extends InheritedWidget {
  /// Incrementado a cada pedido de atualização. O valor em si não importa, só
  /// o fato de ter mudado.
  final int revision;

  const CurrencyRefreshScope({
    super.key,
    required this.revision,
    required super.child,
  });

  /// Registra a dependência de quem chama. Fora de um escopo devolve zero, para
  /// que os widgets de cotação continuem funcionando sozinhos (nos testes, por
  /// exemplo).
  static int of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CurrencyRefreshScope>();
    return scope?.revision ?? 0;
  }

  @override
  bool updateShouldNotify(CurrencyRefreshScope oldWidget) =>
      oldWidget.revision != revision;
}
