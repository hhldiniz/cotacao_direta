import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:flutter/cupertino.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:flutter/material.dart';
import 'exchange_rate_value.dart';

class CanadianDollarExchangeRate extends StatelessWidget
{

  final exchangeRateValue = ExchangeRateValue(Currencies.CAD);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Column(
          children: <Widget>[
            Text("CAD ", style: TextStyle(fontSize: 18, color: Colors.white),)
          ],
        ),
        Column(
          children: <Widget>[
            HomeBlocProvider(
              child: exchangeRateValue,
            )
          ],
        )
      ],
    );
  }

}