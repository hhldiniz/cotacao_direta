import 'package:cotacao_direta/model/base_model.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Configuration', () {
    test('é um BaseModel', () {
      expect(Configuration(1), isA<BaseModel>());
    });

    test('usa os padrões quando só o id é informado', () {
      var configuration = Configuration(1);

      expect(configuration.id, 1);
      expect(configuration.overrideDefaultCurrency, isFalse);
      expect(configuration.selectedOverrideCurrencyCode, "");
    });

    test('aceita os valores informados', () {
      var configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR");

      expect(configuration.overrideDefaultCurrency, isTrue);
      expect(configuration.selectedOverrideCurrencyCode, "EUR");
    });

    test('toMap converte o booleano em 1 quando o override está ligado', () {
      var map = Configuration(1,
              overrideDefaultCurrency: true,
              selectedOverrideCurrencyCode: "JPY")
          .toMap();

      expect(map, {
        'id': 1,
        'overrideDefaultCurrency': 1,
        'selectedOverrideCurrencyCode': "JPY"
      });
    });

    test('toMap converte o booleano em 0 quando o override está desligado', () {
      var map = Configuration(1, overrideDefaultCurrency: false).toMap();

      expect(map['overrideDefaultCurrency'], 0);
    });

    test('toMap preserva o código nulo', () {
      var map = Configuration(1, selectedOverrideCurrencyCode: null).toMap();

      expect(map['selectedOverrideCurrencyCode'], isNull);
    });

    test('toString expõe todos os campos', () {
      var text = Configuration(1,
              overrideDefaultCurrency: true,
              selectedOverrideCurrencyCode: "GBP")
          .toString();

      expect(text, contains("id: 1"));
      expect(text, contains("overrideDefaultCurrency: true"));
      expect(text, contains("selectedOverrideCurrencyCode: GBP"));
    });
  });
}
