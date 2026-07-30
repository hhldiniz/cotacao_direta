import 'dart:math';

/// Casas decimais que fazem uma cotação da ordem de grandeza de [value]
/// aparecer com [significantDigits] dígitos significativos.
///
/// O app guarda em `Currency.value` quantas unidades da moeda valem uma unidade
/// da contrapartida (ver `CurrencyRepository`), então cotação de criptomoeda dá
/// um número minúsculo: com o bitcoin na casa das centenas de milhares de
/// reais, o valor guardado fica em torno de 0,0000017. Formatado com duas casas
/// fixas, todo rótulo do gráfico sairia como "0,00".
///
/// Valores de 1 para cima ficam com [minimumDigits] casas: para moeda
/// fiduciária, duas casas já bastam e mais dígitos só poluiriam o eixo.
int quoteDecimalDigits(double value,
    {int minimumDigits = 2,
    int significantDigits = 3,
    int maximumDigits = 12}) {
  final magnitude = value.abs();
  if (!magnitude.isFinite || magnitude == 0 || magnitude >= 1)
    return minimumDigits;
  // Zeros entre a vírgula e o primeiro dígito significativo: 0,0017 tem dois.
  final leadingZeros = -(log(magnitude) / ln10).floor() - 1;
  return (leadingZeros + significantDigits)
      .clamp(minimumDigits, maximumDigits);
}
