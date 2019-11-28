import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExchangeRateValue extends StatefulWidget {
  final Currencies currency;

  ExchangeRateValue(this.currency);

  @override
  State<StatefulWidget> createState() {
    return ExchangeRateValueState(currency);
  }
}

class ExchangeRateValueState extends State<ExchangeRateValue> {
  ExchangeValueBloc bloc;
  final _formatter = NumberFormat("#.###");
  final Currencies _currency;

  ExchangeRateValueState(this._currency);

  @override
  void didChangeDependencies() {
    bloc = ExchangeValueBlocProvider.of(context);
    bloc.retrieveRemote(_currency).then((value) {
      bloc.updateValue(value);
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bloc.getExchangeValueStream,
      initialData: 0,
      builder: (context, snapshot) => Text(
        _formatter.format(1 / snapshot.data),
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    // Warning. Since the bloc is not being initialized inside UI, calling dispose causes exceptions when widgets are rebuild.
    // Possible memory leaks were considered but not found with dev tools.
    bloc.dispose();
    super.dispose();
  }
}
