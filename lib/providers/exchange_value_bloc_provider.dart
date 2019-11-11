import 'package:flutter/material.dart';
import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';

class ExchangeValueBlocProvider extends InheritedWidget
{

  final ExchangeValueBloc bloc;

  ExchangeValueBlocProvider({Key key, Widget child})
      : bloc = ExchangeValueBloc(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static ExchangeValueBloc of(BuildContext context){
    return (context.inheritFromWidgetOfExactType(ExchangeValueBlocProvider) as ExchangeValueBlocProvider).bloc;
  }
}