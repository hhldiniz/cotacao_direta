import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/exchange_rate_value.dart';
import 'package:flutter/material.dart';

class EuroExchangeRate extends StatelessWidget {
  final Color color;
  final double? fontSize;
  final bool showLabel;

  EuroExchangeRate({
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
                "EUR ",
                style: TextStyle(fontSize: size, color: color),
              ),
            ],
          ),
        Column(
          children: <Widget>[
            ExchangeValueBlocProvider(
              child: ExchangeRateValue(Currencies.EUR, color: color, fontSize: size),
            ),
          ],
        ),
      ],
    );
  }
}
