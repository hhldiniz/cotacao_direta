import 'package:cotacao_direta/view/widgets/exchange_rate_value.dart';
import 'package:flutter/material.dart';

class DollarExchangeRate extends StatelessWidget{

  final exchangeRateValue = ExchangeRateValue();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Column(
          children: <Widget>[
            Text("U\$\$ ", style: TextStyle(fontSize: 18),)
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