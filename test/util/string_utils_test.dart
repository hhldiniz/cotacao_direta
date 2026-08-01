import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('withoutAccents', () {
    test('tira o acento e baixa a caixa', () {
      expect(withoutAccents("Franco Suíço"), "franco suico");
      expect(withoutAccents("Iene Japonês"), "iene japones");
      expect(withoutAccents("Coroa Islandesa"), "coroa islandesa");
    });

    test('deixa passar o que não tem acento', () {
      expect(withoutAccents("USD"), "usd");
      expect(withoutAccents(""), "");
    });
  });

  group('EnumValueAsString', () {
    test('é um singleton', () {
      expect(identical(EnumValueAsString(), EnumValueAsString()), isTrue);
    });

    test('extrai o código a partir do toString do enum', () {
      expect(
          EnumValueAsString().getEnumValue(Currencies.USD.toString()), "USD");
      expect(
          EnumValueAsString().getEnumValue(Currencies.BRL.toString()), "BRL");
    });

    test('devolve a string inteira quando não há ponto', () {
      expect(EnumValueAsString().getEnumValue("USD"), "USD");
    });

    test('corta a partir do primeiro ponto', () {
      expect(EnumValueAsString().getEnumValue("a.b.c"), "b.c");
    });

    test('devolve string vazia para entrada vazia', () {
      expect(EnumValueAsString().getEnumValue(""), "");
    });

    test('converte todas as moedas suportadas em códigos de três letras', () {
      var codes = Currencies.values
          .map((currency) =>
              EnumValueAsString().getEnumValue(currency.toString()))
          .toList();

      expect(codes.length, Currencies.values.length);
      expect(codes.toSet().length, Currencies.values.length,
          reason: "os códigos de moeda precisam ser únicos");
      for (var code in codes) {
        expect(code, matches(RegExp(r'^[A-Z]{3}$')));
      }
    });
  });
}
