import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:flutter/material.dart';
import 'exchange_rate_value.dart';

class CanadianDollarExchangeRate extends StatelessWidget {
  final Color color;

  CanadianDollarExchangeRate({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Column(
          children: <Widget>[
            Text(
              "CAD ",
              style: TextStyle(
                fontSize: 18 * Responsive.scaleFactor(context),
                color: color,
              ),
            ),
          ],
        ),
        Column(
          children: <Widget>[
            ExchangeValueBlocProvider(
              child: ExchangeRateValue(Currencies.CAD, color: color),
            ),
          ],
        ),
      ],
    );
  }
}
