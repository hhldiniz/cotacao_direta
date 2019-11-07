import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/view/widgets/exchange_rate_value.dart';
import 'package:flutter/material.dart';
import 'package:cotacao_direta/providers/exchange_rate_value_provider.dart';

class DollarExchangeRate extends StatelessWidget{

  final exchangeRateValue = ExchangeRateValue(Currencies.USD);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Column(
          children: <Widget>[
            Text("USD ", style: TextStyle(fontSize: 18, color: Colors.white),)
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