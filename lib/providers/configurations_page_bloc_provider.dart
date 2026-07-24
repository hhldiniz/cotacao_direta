import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:flutter/material.dart';

/// Cria o [ConfigurationsPageBloc] e o mantém vivo enquanto esta parte da árvore existir. Um
/// InheritedWidget sozinho não dá conta disso: ele é recriado a cada rebuild e
/// não tem dispose, então o bloc precisa de um State para acompanhar o ciclo de
/// vida.
class ConfigurationsPageBlocProvider extends StatefulWidget {
  final Widget child;

  /// Bloc pronto, fornecido pelo chamador. Quem cria também descarta: o
  /// provider só chama dispose no bloc que ele mesmo criou.
  final ConfigurationsPageBloc? bloc;

  ConfigurationsPageBlocProvider({Key? key, required this.child, this.bloc})
      : super(key: key);

  @override
  State<ConfigurationsPageBlocProvider> createState() =>
      _ConfigurationsPageBlocProviderState();

  static ConfigurationsPageBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ConfigurationsPageBlocScope>()!
        .bloc;
  }
}

class _ConfigurationsPageBlocProviderState
    extends State<ConfigurationsPageBlocProvider> {
  late final ConfigurationsPageBloc _bloc =
      widget.bloc ?? ConfigurationsPageBloc();
  late final bool _ownsBloc = widget.bloc == null;

  @override
  Widget build(BuildContext context) =>
      _ConfigurationsPageBlocScope(bloc: _bloc, child: widget.child);

  @override
  void dispose() {
    if (_ownsBloc) _bloc.dispose();
    super.dispose();
  }
}

class _ConfigurationsPageBlocScope extends InheritedWidget {
  final ConfigurationsPageBloc bloc;

  _ConfigurationsPageBlocScope(
      {Key? key, required this.bloc, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_ConfigurationsPageBlocScope oldWidget) =>
      bloc != oldWidget.bloc;
}
