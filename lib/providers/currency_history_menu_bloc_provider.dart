import 'package:cotacao_direta/blocs/currency_history_menu_bloc.dart';
import 'package:flutter/material.dart';

class CurrencyHistoryMenuBlocProvider extends InheritedWidget {

  final CurrencyHistoryMenuBloc bloc;

  CurrencyHistoryMenuBlocProvider({Key key, Widget child}):
        bloc = CurrencyHistoryMenuBloc(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static CurrencyHistoryMenuBloc of(BuildContext context){
      return context.dependOnInheritedWidgetOfExactType<CurrencyHistoryMenuBlocProvider>().bloc;
  }

}