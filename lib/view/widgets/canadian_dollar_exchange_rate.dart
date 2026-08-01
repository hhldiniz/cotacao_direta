import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:flutter/material.dart';
import 'exchange_rate_value.dart';

class CanadianDollarExchangeRate extends StatelessWidget {
  final Color color;
  final double? fontSize;
  final bool showLabel;

  CanadianDollarExchangeRate({
    this.color = Colors.white,
    this.fontSize,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = fontSize ?? 18 * Responsive.scaleFactor(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showLabel)
          Column(
            children: <Widget>[
              Text(
                "CAD ",
                style: TextStyle(fontSize: size, color: color),
              ),
            ],
          ),
        Column(
          children: <Widget>[
            ExchangeValueBlocProvider(
              child: ExchangeRateValue(Currencies.CAD, color: color, fontSize: size),
            ),
          ],
        ),
      ],
    );
  }
}
