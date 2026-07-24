import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/notifications/update_currency_value_notification.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
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
  // O bloc pertence ao ExchangeValueBlocProvider, que o descarta junto com o
  // próprio State: este widget apenas o consome.
  late ExchangeValueBloc bloc;
  final _formatter = NumberFormat("#.###");
  final Currencies _currency;

  ExchangeRateValueState(this._currency);

  @override
  void didChangeDependencies() {
    bloc = ExchangeValueBlocProvider.of(context);
    bloc.retrieveCurrencyValue(_currency).then((value) {
      bloc.updateValue(value);
    }).onError(
      (error, stackTrace) {
        print(error.toString());
      },
    );
    super.didChangeDependencies();
  }

  /// Enquanto a cotação não chega, o texto fica vazio; se ela não existir,
  /// mostramos "Sem Dados" em vez de um número inventado.
  String _exchangeRateLabel(
      BuildContext context, AsyncSnapshot<num?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return "";
    var value = snapshot.data;
    if (value == null || value == 0) {
      return MyAppLocalizations.of(context)!.noDataLabel!;
    }
    return _formatter.format(1 / value);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<num?>(
        stream: bloc.getNextStreamController(),
        builder: (context, snapshot) =>
            NotificationListener<UpdateCurrencyValueNotification>(
              onNotification: (UpdateCurrencyValueNotification notification) {
                didChangeDependencies();
                return true;
              },
              child: Text(
                _exchangeRateLabel(context, snapshot),
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ));
  }
}
