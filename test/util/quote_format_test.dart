import 'package:cotacao_direta/util/quote_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quoteDecimalDigits', () {
    test('duas casas para valores de 1 para cima', () {
      expect(quoteDecimalDigits(27.4), 2);
      expect(quoteDecimalDigits(1), 2);
      expect(quoteDecimalDigits(3812.5), 2);
    });

    test('três dígitos significativos para valores abaixo de 1', () {
      // Cotação típica de moeda fiduciária forte: 0,185 dólar por real.
      expect(quoteDecimalDigits(0.185), 3);
      expect(quoteDecimalDigits(0.0017), 5);
    });

    test('acompanha a ordem de grandeza de uma cotação de criptomoeda', () {
      // Bitcoin em torno de R$ 600 mil: o app guarda 1/600000.
      var digits = quoteDecimalDigits(0.0000017);
      expect(digits, 8);
      expect((0.0000017).toStringAsFixed(digits), "0.00000170",
          reason: "com duas casas fixas o rótulo sairia como 0.00");
    });

    test('respeita o mínimo e o máximo de casas', () {
      expect(quoteDecimalDigits(0.185, minimumDigits: 4), 4);
      expect(quoteDecimalDigits(1e-30, maximumDigits: 10), 10);
    });

    test('ignora o sinal', () {
      expect(quoteDecimalDigits(-0.0017), quoteDecimalDigits(0.0017));
    });

    test('cai no mínimo para zero e para valores não finitos', () {
      expect(quoteDecimalDigits(0), 2);
      expect(quoteDecimalDigits(double.infinity), 2);
      expect(quoteDecimalDigits(double.nan), 2);
    });
  });
}
