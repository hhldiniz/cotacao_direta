import 'package:cotacao_direta/blocs/currency_history_bloc.dart';
import 'package:flutter/widgets.dart';

class CurrencyHistoryBlocProvider extends InheritedWidget{

  final CurrencyHistoryBloc bloc;

  CurrencyHistoryBlocProvider({Key key, Widget child}):
      bloc = CurrencyHistoryBloc(),
      super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;


  static CurrencyHistoryBloc of(BuildContext context){
    return context.dependOnInheritedWidgetOfExactType<CurrencyHistoryBlocProvider>().bloc;
  }
}