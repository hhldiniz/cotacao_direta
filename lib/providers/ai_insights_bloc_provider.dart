import 'package:cotacao_direta/blocs/ai_insights_bloc.dart';
import 'package:flutter/material.dart';

/// Creates the [AiInsightsBloc] and keeps it alive for as long as this part of
/// the tree exists. An InheritedWidget alone cannot do that: it is rebuilt on
/// every rebuild and has no dispose, so the bloc needs a State to follow the
/// lifecycle.
class AiInsightsBlocProvider extends StatefulWidget {
  final Widget child;

  /// Ready-made bloc supplied by the caller. Whoever creates it also disposes
  /// of it: the provider only disposes the bloc it created itself.
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
