import 'package:cotacao_direta/blocs/selected_currency_details_bloc.dart';
import 'package:flutter/material.dart';

/// Cria o [SelectedCurrencyDetailsBloc] e o mantém vivo enquanto esta parte da árvore existir. Um
/// InheritedWidget sozinho não dá conta disso: ele é recriado a cada rebuild e
/// não tem dispose, então o bloc precisa de um State para acompanhar o ciclo de
/// vida.
class SelectedCurrencyDetailsBlocProvider extends StatefulWidget {
  final Widget child;

  /// Bloc pronto, fornecido pelo chamador. Quem cria também descarta: o
  /// provider só chama dispose no bloc que ele mesmo criou.
  final SelectedCurrencyDetailsBloc? bloc;

  SelectedCurrencyDetailsBlocProvider(
      {Key? key, required this.child, this.bloc})
      : super(key: key);

  @override
  State<SelectedCurrencyDetailsBlocProvider> createState() =>
      _SelectedCurrencyDetailsBlocProviderState();

  static SelectedCurrencyDetailsBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<
            _SelectedCurrencyDetailsBlocScope>()!
        .bloc;
  }
}

class _SelectedCurrencyDetailsBlocProviderState
    extends State<SelectedCurrencyDetailsBlocProvider> {
  late final SelectedCurrencyDetailsBloc _bloc =
      widget.bloc ?? SelectedCurrencyDetailsBloc();
  late final bool _ownsBloc = widget.bloc == null;

  @override
  Widget build(BuildContext context) =>
      _SelectedCurrencyDetailsBlocScope(bloc: _bloc, child: widget.child);

  @override
  void dispose() {
    if (_ownsBloc) _bloc.dispose();
    super.dispose();
  }
}

class _SelectedCurrencyDetailsBlocScope extends InheritedWidget {
  final SelectedCurrencyDetailsBloc bloc;

  _SelectedCurrencyDetailsBlocScope(
      {Key? key, required this.bloc, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_SelectedCurrencyDetailsBlocScope oldWidget) =>
      bloc != oldWidget.bloc;
}
