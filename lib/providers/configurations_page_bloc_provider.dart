import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:flutter/material.dart';

class ConfigurationsPageBlocProvider extends InheritedWidget {
  final ConfigurationsPageBloc bloc;

  ConfigurationsPageBlocProvider({Key? key, required Widget child})
      : bloc = ConfigurationsPageBloc(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static ConfigurationsPageBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ConfigurationsPageBlocProvider>()!
        .bloc;
  }
}
