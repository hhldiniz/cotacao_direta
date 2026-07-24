import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:flutter/widgets.dart';

/// Cria o [HomeBloc] e o mantém vivo enquanto esta parte da árvore existir. Um
/// InheritedWidget sozinho não dá conta disso: ele é recriado a cada rebuild e
/// não tem dispose, então o bloc precisa de um State para acompanhar o ciclo de
/// vida.
class HomeBlocProvider extends StatefulWidget {
  final Widget child;

  /// Bloc pronto, fornecido pelo chamador. Quem cria também descarta: o
  /// provider só chama dispose no bloc que ele mesmo criou.
  final HomeBloc? bloc;

  HomeBlocProvider({Key? key, required this.child, this.bloc})
      : super(key: key);

  @override
  State<HomeBlocProvider> createState() => _HomeBlocProviderState();

  static HomeBloc of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HomeBlocScope>()!.bloc;
  }
}

class _HomeBlocProviderState extends State<HomeBlocProvider> {
  late final HomeBloc _bloc = widget.bloc ?? HomeBloc();
  late final bool _ownsBloc = widget.bloc == null;

  @override
  Widget build(BuildContext context) =>
      _HomeBlocScope(bloc: _bloc, child: widget.child);

  @override
  void dispose() {
    if (_ownsBloc) _bloc.dispose();
    super.dispose();
  }
}

class _HomeBlocScope extends InheritedWidget {
  final HomeBloc bloc;

  _HomeBlocScope({Key? key, required this.bloc, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_HomeBlocScope oldWidget) => bloc != oldWidget.bloc;
}
