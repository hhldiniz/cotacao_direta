import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:flutter/cupertino.dart';
import 'package:cotacao_direta/providers/exchange_rate_value_provider.dart';
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
            Text("CAD ", style: TextStyle(fontSize: 18),)
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