import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/util/currency_colors.dart';
import 'package:flutter/material.dart';

/// Cor de destaque de cada moeda. As quatro que a tela inicial trazia fixas
/// ficam com exatamente a cor que já tinham; as demais recebem uma cor da
/// paleta abaixo.
const Map<Currencies, Color> _accentByCurrency = {
  Currencies.USD: CurrencyColors.usd,
  Currencies.EUR: CurrencyColors.eur,
  Currencies.CAD: CurrencyColors.cad,
  Currencies.JPY: CurrencyColors.jpy,
};

/// Tons vivos, na mesma linha das cores das quatro moedas originais, para as
/// moedas que agora também podem virar bolha.
const List<Color> _palette = [
  Color(0xFF00B8D4), // ciano
  Color(0xFF7C4DFF), // roxo
  Color(0xFF00C853), // verde
  Color(0xFFFF6D00), // laranja
  Color(0xFF2979FF), // azul
  Color(0xFFD500F9), // magenta
  Color(0xFF00BFA5), // verde-água
  Color(0xFFC51162), // vinho
];

/// Ícone de cada moeda. O Material não tem símbolo para toda moeda, então só
/// as que têm ícone próprio aparecem aqui; o resto usa o ícone genérico de
/// pagamento — melhor do que emprestar o cifrão de outra moeda.
const Map<Currencies, IconData> _iconByCurrency = {
  Currencies.USD: Icons.attach_money,
  Currencies.EUR: Icons.euro,
  Currencies.CAD: Icons.monetization_on,
  Currencies.JPY: Icons.currency_yen,
  Currencies.GBP: Icons.currency_pound,
  Currencies.INR: Icons.currency_rupee,
  Currencies.RUB: Icons.currency_ruble,
  Currencies.TRY: Icons.currency_lira,
  Currencies.CNY: Icons.currency_yuan,
  Currencies.CHF: Icons.currency_franc,
};

/// Cor da bolha de [currency] na tela inicial.
///
/// Uma moeda sem cor própria recebe sempre a mesma cor da paleta, escolhida
/// pela posição dela no enum: a bolha não muda de cor de uma abertura do app
/// para a outra.
Color currencyAccentColor(Currencies currency) {
  return _accentByCurrency[currency] ??
      _palette[currency.index % _palette.length];
}

/// Ícone da bolha de [currency] na tela inicial.
IconData currencyIcon(Currencies currency) =>
    _iconByCurrency[currency] ?? Icons.payments;
