import 'package:cotacao_direta/enums/cryptocurrency_enum.dart';
import 'package:cotacao_direta/util/cryptocurrency_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cryptocurrencyName', () {
    test('toda criptomoeda da listagem tem nome', () {
      for (var cryptocurrency in Cryptocurrencies.values) {
        expect(() => cryptocurrencyName(cryptocurrency), returnsNormally,
            reason: "$cryptocurrency ficou sem entrada no mapa de nomes");
        expect(cryptocurrencyName(cryptocurrency), isNotEmpty);
      }
    });

    test('devolve o nome da moeda, não o código', () {
      expect(cryptocurrencyName(Cryptocurrencies.BTC), "Bitcoin");
      expect(cryptocurrencyName(Cryptocurrencies.ETH), "Ethereum");
    });
  });

  group('iconForCryptocurrency', () {
    test('o bitcoin usa o glifo próprio do Material Icons', () {
      expect(iconForCryptocurrency(Cryptocurrencies.BTC),
          Icons.currency_bitcoin);
    });

    test('as demais usam o ícone genérico de token', () {
      for (var cryptocurrency in Cryptocurrencies.values
          .where((cryptocurrency) => cryptocurrency != Cryptocurrencies.BTC)) {
        expect(iconForCryptocurrency(cryptocurrency), Icons.token);
      }
    });
  });
}
