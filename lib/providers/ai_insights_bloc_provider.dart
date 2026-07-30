import 'package:cotacao_direta/blocs/ai_insights_bloc.dart';
import 'package:flutter/material.dart';

/// Cria o [AiInsightsBloc] e o mantém vivo enquanto esta parte da árvore
/// existir. Um InheritedWidget sozinho não dá conta disso: ele é recriado a cada
/// rebuild e não tem dispose, então o bloc precisa de um State para acompanhar o
/// ciclo de vida.
class AiInsightsBlocProvider extends StatefulWidget {
  final Widget child;

  /// Bloc pronto, fornecido pelo chamador. Quem cria também descarta: o
  /// provider só chama dispose no bloc que ele mesmo criou.
  final AiInsightsBloc? bloc;

  AiInsightsBlocProvider({Key? key, required this.child, this.bloc})
      : super(key: key);

  @override
  State<AiInsightsBlocProvider> createState() => _AiInsightsBlocProviderState();

  static AiInsightsBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AiInsightsBlocScope>()!
        .bloc;
  }
}

class _AiInsightsBlocProviderState extends State<AiInsightsBlocProvider> {
  late final AiInsightsBloc _bloc = widget.bloc ?? AiInsightsBloc();
  late final bool _ownsBloc = widget.bloc == null;

  @override
  Widget build(BuildContext context) =>
      _AiInsightsBlocScope(bloc: _bloc, child: widget.child);

  @override
  void dispose() {
    if (_ownsBloc) _bloc.dispose();
    super.dispose();
  }
}

class _AiInsightsBlocScope extends InheritedWidget {
  final AiInsightsBloc bloc;

  _AiInsightsBlocScope({Key? key, required this.bloc, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_AiInsightsBlocScope oldWidget) =>
      bloc != oldWidget.bloc;
}
