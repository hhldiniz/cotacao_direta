import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/view/widgets/exchange_rate_value.dart';
import 'package:cotacao_direta/providers/exchange_rate_value_provider.dart';
import 'package:flutter/material.dart';

class EuroExchangeRate extends StatelessWidget{

  final exchangeRateValue = ExchangeRateValue(Currencies.EUR);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Column(
          children: <Widget>[
            Text("EUR ", style: TextStyle(fontSize: 18, color: Colors.white),)
          ],
        ),
        Column(
          children: <Widget>[
            ExchangeValueBlocProvider(
              child: exchangeRateValue,
            )
          ],
        )
      ],
    );
  }
}