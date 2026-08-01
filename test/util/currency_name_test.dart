import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('currencyName', () {
    test('traduz o nome da moeda', () {
      expect(currencyName(Currencies.USD, const Locale("pt")), "Dólar Americano");
      expect(currencyName(Currencies.USD, const Locale("en")), "US Dollar");
    });

    test('cai no inglês em um idioma sem tradução', () {
      expect(currencyName(Currencies.BRL, const Locale("es")), "Brazilian Real");
    });

    test('toda moeda suportada tem nome nos dois idiomas', () {
      for (var currency in Currencies.values) {
        for (var locale in const [Locale("pt"), Locale("en")]) {
          expect(currencyName(currency, locale), isNotEmpty);
          expect(currencyName(currency, locale), isNot(currencyCode(currency)),
              reason: "${currency.name} está sem nome em ${locale.languageCode}");
        }
      }
    });
  });

  group('currencyForCode', () {
    test('encontra a moeda pelo código', () {
      expect(currencyForCode("BRL"), Currencies.BRL);
      expect(currencyForCode("jpy"), Currencies.JPY);
    });

    test('devolve nulo para um código desconhecido ou vazio', () {
      expect(currencyForCode("XXX"), isNull);
      expect(currencyForCode(""), isNull);
      expect(currencyForCode(null), isNull);
    });
  });

  group('currencyNameForCode', () {
    test('traduz o nome da moeda do código', () {
      expect(currencyNameForCode("BRL", const Locale("pt")), "Real Brasileiro");
      expect(currencyNameForCode("BRL", const Locale("en")), "Brazilian Real");
    });

    test('usa o próprio código quando a moeda é desconhecida', () {
      expect(currencyNameForCode("XXX", const Locale("pt")), "XXX");
      expect(currencyNameForCode(null, const Locale("pt")), "");
    });
  });

  group('currencyCode', () {
    test('usa o próprio nome do valor do enum', () {
      expect(currencyCode(Currencies.BRL), "BRL");
      expect(currencyCode(Currencies.JPY), "JPY");
    });
  });
}
