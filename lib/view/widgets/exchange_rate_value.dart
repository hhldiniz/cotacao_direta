import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/notifications/update_currency_value_notification.dart';
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
  late ExchangeValueBloc bloc;
  final _formatter = NumberFormat("#.###");
  final Currencies _currency;

  ExchangeRateValueState(this._currency);

  @override
  void didChangeDependencies() {
    bloc = ExchangeValueBlocProvider.of(context);
    bloc.retrieveCurrencyValue(_currency).then((value) {
      bloc.updateValue(value);
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<num>(
        stream: bloc.getNextStreamController(),
        initialData: 0,
        builder: (context, snapshot) =>
            NotificationListener<UpdateCurrencyValueNotification>(
              onNotification: (UpdateCurrencyValueNotification notification) {
                didChangeDependencies();
                return true;
              },
              child: Text(
                _formatter
                    .format(snapshot.data != null ? 1 / snapshot.data! : 0),
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ));
  }

  @override
  void dispose() {
    // Warning. Since the bloc is not being initialized inside UI, calling dispose causes exceptions when widgets are rebuild.
    // Possible memory leaks were considered but not found with dev tools.
    bloc.dispose();
    super.dispose();
  }
}
