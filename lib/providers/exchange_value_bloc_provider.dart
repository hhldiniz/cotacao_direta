import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:flutter/material.dart';

/// Cria o [ExchangeValueBloc] e o mantém vivo enquanto esta parte da árvore
/// existir. Um InheritedWidget sozinho não dá conta disso: ele é recriado a
/// cada rebuild e não tem dispose, então o bloc precisa de um State para
/// acompanhar o ciclo de vida.
class ExchangeValueBlocProvider extends StatefulWidget {
  final Widget child;

  /// Bloc pronto, fornecido pelo chamador. Quem cria também descarta: o
  /// provider só chama dispose no bloc que ele mesmo criou.
  final ExchangeValueBloc? bloc;

  ExchangeValueBlocProvider({Key? key, required this.child, this.bloc})
      : super(key: key);

  @override
  State<ExchangeValueBlocProvider> createState() =>
      _ExchangeValueBlocProviderState();

  static ExchangeValueBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ExchangeValueBlocScope>()!
        .bloc;
  }
}

class _ExchangeValueBlocProviderState extends State<ExchangeValueBlocProvider> {
  late final ExchangeValueBloc _bloc = widget.bloc ?? ExchangeValueBloc();
  late final bool _ownsBloc = widget.bloc == null;

  @override
  Widget build(BuildContext context) {
    return _ExchangeValueBlocScope(bloc: _bloc, child: widget.child);
  }

  @override
  void dispose() {
    if (_ownsBloc) _bloc.dispose();
    super.dispose();
  }
}

class _ExchangeValueBlocScope extends InheritedWidget {
  final ExchangeValueBloc bloc;

  _ExchangeValueBlocScope({Key? key, required this.bloc, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_ExchangeValueBlocScope oldWidget) =>
      bloc != oldWidget.bloc;
}
