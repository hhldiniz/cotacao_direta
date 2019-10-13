import 'package:cotacao_direta/view/widgets/exchange_rate_value.dart';
import 'package:flutter/material.dart';

class EuroExchangeRate extends StatelessWidget{

  final exchangeRateValue = ExchangeRateValue();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Column(
          children: <Widget>[
            Text("EUR ", style: TextStyle(fontSize: 18),)
          ],
        ),
        Column(
          children: <Widget>[
            exchangeRateValue
          ],
        )
      ],
    );
  }
}