import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/exchange_rate_value.dart';
import 'package:flutter/material.dart';

class DollarExchangeRate extends StatelessWidget {
  final Color color;
  final double? fontSize;
  // Os cartões da tela inicial já mostram o código da moeda no cabeçalho;
  // esconder o rótulo aqui evita repetir "USD" duas vezes no mesmo cartão.
  final bool showLabel;

  DollarExchangeRate({
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
                "USD ",
                style: TextStyle(fontSize: size, color: color),
              ),
            ],
          ),
        Column(
          children: <Widget>[
            ExchangeValueBlocProvider(
              child: ExchangeRateValue(Currencies.USD, color: color, fontSize: size),
            ),
          ],
        ),
      ],
    );
  }
}
