import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:flutter/widgets.dart';

/// Cria o [CurrencyAlertsBloc] e o mantém vivo enquanto esta parte da árvore
/// existir. Um InheritedWidget sozinho não dá conta disso: ele é recriado a
/// cada rebuild e não tem dispose, então o bloc precisa de um State para
/// acompanhar o ciclo de vida.
class CurrencyAlertsBlocProvider extends StatefulWidget {
  final Widget child;

  /// Bloc pronto, fornecido pelo chamador. Quem cria também descarta: o
  /// provider só chama dispose no bloc que ele mesmo criou.
  final CurrencyAlertsBloc? bloc;

  CurrencyAlertsBlocProvider({Key? key, required this.child, this.bloc})
      : super(key: key);

  @override
  State<CurrencyAlertsBlocProvider> createState() =>
      _CurrencyAlertsBlocProviderState();

  static CurrencyAlertsBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_CurrencyAlertsBlocScope>()!
        .bloc;
  }
}

class _CurrencyAlertsBlocProviderState
    extends State<CurrencyAlertsBlocProvider> {
  late final CurrencyAlertsBloc _bloc = widget.bloc ?? CurrencyAlertsBloc();
  late final bool _ownsBloc = widget.bloc == null;

  @override
  Widget build(BuildContext context) =>
      _CurrencyAlertsBlocScope(bloc: _bloc, child: widget.child);

  @override
  void dispose() {
    if (_ownsBloc) _bloc.dispose();
    super.dispose();
  }
}

class _CurrencyAlertsBlocScope extends InheritedWidget {
  final CurrencyAlertsBloc bloc;

  _CurrencyAlertsBlocScope({Key? key, required this.bloc, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_CurrencyAlertsBlocScope oldWidget) =>
      bloc != oldWidget.bloc;
}
