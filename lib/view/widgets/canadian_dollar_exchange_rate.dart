import 'package:flutter/cupertino.dart';
import 'exchange_rate_value.dart';

class CanadianDollarExchangeRate extends StatelessWidget
{

  final exchangeRateValue = ExchangeRateValue();

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
            exchangeRateValue
          ],
        )
      ],
    );
  }

}