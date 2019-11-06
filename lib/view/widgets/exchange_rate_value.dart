import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:cotacao_direta/providers/exchange_rate_value_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExchangeRateValue extends StatefulWidget{

  final _state = ExchangeRateValueState();

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _state;
  }

}

class ExchangeRateValueState extends State<ExchangeRateValue>{

  HomeBloc bloc;
  final _formatter = NumberFormat("#.###");

  @override
  void didChangeDependencies() {
    bloc = HomeBlocProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bloc.getExchangeValue,
      initialData: 0,
      builder: (context, snapshot)=> Text(_formatter.format(snapshot.data), style: TextStyle(fontSize: 18),),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

}