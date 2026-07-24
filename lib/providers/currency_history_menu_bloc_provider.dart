import 'package:cotacao_direta/blocs/currency_history_menu_bloc.dart';
import 'package:flutter/material.dart';

/// Cria o [CurrencyHistoryMenuBloc] e o mantém vivo enquanto esta parte da árvore existir. Um
/// InheritedWidget sozinho não dá conta disso: ele é recriado a cada rebuild e
/// não tem dispose, então o bloc precisa de um State para acompanhar o ciclo de
/// vida.
class CurrencyHistoryMenuBlocProvider extends StatefulWidget {
  final Widget child;

  /// Bloc pronto, fornecido pelo chamador. Quem cria também descarta: o
  /// provider só chama dispose no bloc que ele mesmo criou.
  final CurrencyHistoryMenuBloc? bloc;

  CurrencyHistoryMenuBlocProvider({Key? key, required this.child, this.bloc})
      : super(key: key);

  @override
  State<CurrencyHistoryMenuBlocProvider> createState() =>
      _CurrencyHistoryMenuBlocProviderState();

  static CurrencyHistoryMenuBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_CurrencyHistoryMenuBlocScope>()!
        .bloc;
  }
}

class _CurrencyHistoryMenuBlocProviderState
    extends State<CurrencyHistoryMenuBlocProvider> {
  late final CurrencyHistoryMenuBloc _bloc =
      widget.bloc ?? CurrencyHistoryMenuBloc();
  late final bool _ownsBloc = widget.bloc == null;

  @override
  Widget build(BuildContext context) =>
      _CurrencyHistoryMenuBlocScope(bloc: _bloc, child: widget.child);

  @override
  void dispose() {
    if (_ownsBloc) _bloc.dispose();
    super.dispose();
  }
}

class _CurrencyHistoryMenuBlocScope extends InheritedWidget {
  final CurrencyHistoryMenuBloc bloc;

  _CurrencyHistoryMenuBlocScope(
      {Key? key, required this.bloc, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_CurrencyHistoryMenuBlocScope oldWidget) =>
      bloc != oldWidget.bloc;
}
