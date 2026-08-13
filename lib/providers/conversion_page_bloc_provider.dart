import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:flutter/material.dart';

/// Cria o [ConversionPageBloc] e o mantém vivo enquanto esta parte da árvore existir. Um
/// InheritedWidget sozinho não dá conta disso: ele é recriado a cada rebuild e
/// não tem dispose, então o bloc precisa de um State para acompanhar o ciclo de
/// vida.
class ConversionPageBlocProvider extends StatefulWidget {
  final Widget child;

  /// Bloc pronto, fornecido pelo chamador. Quem cria também descarta: o
  /// provider só chama dispose no bloc que ele mesmo criou.
  final ConversionPageBloc? bloc;

  /// Par de moedas com que a tela abre e moedas que o seletor mostra primeiro.
  /// São repassados ao bloc quando é o provider quem o cria; um bloc pronto
  /// já vem com as suas escolhas feitas.
  final Currencies? initialFromCurrency;
  final Currencies? initialToCurrency;
  final List<Currencies> priorityCurrencies;

  ConversionPageBlocProvider({
    Key? key,
    required this.child,
    this.bloc,
    this.initialFromCurrency,
    this.initialToCurrency,
    this.priorityCurrencies = const [],
  }) : super(key: key);

  @override
  State<ConversionPageBlocProvider> createState() =>
      _ConversionPageBlocProviderState();

  static ConversionPageBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ConversionPageBlocScope>()!
        .bloc;
  }
}

class _ConversionPageBlocProviderState
    extends State<ConversionPageBlocProvider> {
  late final ConversionPageBloc _bloc = widget.bloc ??
      ConversionPageBloc(
        initialFromCurrency: widget.initialFromCurrency,
        initialToCurrency: widget.initialToCurrency,
        priorityCurrencies: widget.priorityCurrencies,
      );
  late final bool _ownsBloc = widget.bloc == null;

  @override
  Widget build(BuildContext context) =>
      _ConversionPageBlocScope(bloc: _bloc, child: widget.child);

  @override
  void dispose() {
    if (_ownsBloc) _bloc.dispose();
    super.dispose();
  }
}

class _ConversionPageBlocScope extends InheritedWidget {
  final ConversionPageBloc bloc;

  _ConversionPageBlocScope(
      {Key? key, required this.bloc, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_ConversionPageBlocScope oldWidget) =>
      bloc != oldWidget.bloc;
}
