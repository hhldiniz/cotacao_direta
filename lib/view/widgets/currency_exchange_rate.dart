import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/exchange_rate_value.dart';
import 'package:flutter/material.dart';

/// Cotação de uma moeda qualquer, com o bloc que a busca.
///
/// Substitui os widgets que existiam um por moeda (DollarExchangeRate,
/// EuroExchangeRate, CanadianDollarExchangeRate e YenExchangeRate): as moedas
/// da tela inicial passaram a ser escolhidas pelo usuário, então não há mais
/// como ter um widget por moeda.
class CurrencyExchangeRate extends StatelessWidget {
  final Currencies currency;
  final Color color;
  final double? fontSize;

  /// Os cartões da tela inicial já mostram o código da moeda no cabeçalho;
  /// esconder o rótulo aqui evita repetir "USD" duas vezes no mesmo cartão.
  final bool showLabel;

  const CurrencyExchangeRate(
    this.currency, {
    super.key,
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
          Text(
            "${currencyCode(currency)} ",
            style: TextStyle(fontSize: size, color: color),
          ),
        ExchangeValueBlocProvider(
          child: ExchangeRateValue(currency, color: color, fontSize: size),
        ),
      ],
    );
  }
}
