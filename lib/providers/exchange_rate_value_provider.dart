import 'package:flutter/material.dart';
import 'package:cotacao_direta/blocs/exchange_rate_value_bloc.dart';

class ExchangeValueBlocProvider extends InheritedWidget
{

  final ExchangeRateValueBloc bloc;

  ExchangeValueBlocProvider({Key key, Widget child})
      : bloc = ExchangeRateValueBloc(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static ExchangeRateValueBloc of(BuildContext context){
    return (context.inheritFromWidgetOfExactType(ExchangeValueBlocProvider) as ExchangeValueBlocProvider).bloc;
  }
}