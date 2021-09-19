import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:flutter/widgets.dart';

class HomeBlocProvider extends InheritedWidget {
  final HomeBloc _bloc;

  HomeBlocProvider({Key? key, required Widget child})
      : _bloc = HomeBloc(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;

  static HomeBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HomeBlocProvider>()!
        ._bloc;
  }
}
