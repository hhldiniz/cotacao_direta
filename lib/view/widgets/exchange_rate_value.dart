import 'package:cotacao_direta/view/blocs/exchange_rate_value_bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExchangeRateValue extends StatelessWidget{

  final bloc = ExchangeRateValueBloc();
  final _formatter = NumberFormat("#.###");

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bloc.getValue,
      initialData: 0,
      builder: (context, snapshot)=> Text(_formatter.format(snapshot.data), style: TextStyle(fontSize: 18),),
    );
  }


}