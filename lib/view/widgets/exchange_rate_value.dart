import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExchangeRateValue extends StatefulWidget{

  final Currencies currency;

  ExchangeRateValue(this.currency);

  @override
  State<StatefulWidget> createState() {
    return ExchangeRateValueState(currency);
  }

}

class ExchangeRateValueState extends State<ExchangeRateValue>{

  HomeBloc bloc;
  final _formatter = NumberFormat("#.###");
  final Currencies _currency;

  ExchangeRateValueState(this._currency);

  @override
  void didChangeDependencies() {
    bloc = HomeBlocProvider.of(context);
    bloc.retrieveRemoteValue(_currency).then((value){
      bloc.updateValue(value);
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bloc.getExchangeValueStream,
      initialData: 0,
      builder: (context, snapshot)=> Text(_formatter.format(1/snapshot.data), style: TextStyle(fontSize: 18, color: Colors.white),),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

}