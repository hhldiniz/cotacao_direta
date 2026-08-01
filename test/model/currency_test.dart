import 'package:cotacao_direta/model/base_model.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency', () {
    test('é um BaseModel', () {
      expect(Currency(), isA<BaseModel>());
    });

    test('mantém os valores recebidos no construtor', () {
      var currency = Currency(
          id: "USD",
          value: 5.42,
          historicalDate: "2024-01-31T00:00:00.000",
          timestamp: "2024-01-31T10:15:00.000",
          friendlyName: "Dólar dos Estados Unidos",
          counterCurrency: "BRL");

      expect(currency.id, "USD");
      expect(currency.value, 5.42);
      expect(currency.historicalDate, "2024-01-31T00:00:00.000");
      expect(currency.timestamp, "2024-01-31T10:15:00.000");
      expect(currency.friendlyName, "Dólar dos Estados Unidos");
      expect(currency.counterCurrency, "BRL");
    });

    test('todos os campos são opcionais e começam nulos', () {
      var currency = Currency();

      expect(currency.id, isNull);
      expect(currency.value, isNull);
      expect(currency.historicalDate, isNull);
      expect(currency.timestamp, isNull);
      expect(currency.friendlyName, isNull);
      expect(currency.counterCurrency, isNull);
    });

    test('toMap gera as colunas esperadas pela tabela Currency', () {
      var currency = Currency(
          id: "EUR",
          value: 6.1,
          historicalDate: "2024-02-01T00:00:00.000",
          timestamp: "2024-02-01T09:00:00.000",
          friendlyName: "Euro",
          counterCurrency: "BRL");

      expect(currency.toMap(), {
        'id': "EUR",
        'value': 6.1,
        'historicalDate': "2024-02-01T00:00:00.000",
        'timestamp': "2024-02-01T09:00:00.000",
        'friendlyName': "Euro",
        'counterCurrency': "BRL"
      });
    });

    test('toMap preserva nulos, sem substituí-los por valores padrão', () {
      expect(Currency(id: "JPY").toMap(), {
        'id': "JPY",
        'value': null,
        'historicalDate': null,
        'timestamp': null,
        'friendlyName': null,
        'counterCurrency': null
      });
    });

    test('toString expõe todos os campos', () {
      var text = Currency(
              id: "CAD",
              value: 4.0,
              historicalDate: "2024-03-01",
              timestamp: "2024-03-01T12:00:00.000",
              friendlyName: "Dólar canadense",
              counterCurrency: "BRL")
          .toString();

      expect(text, contains("id: CAD"));
      expect(text, contains("value: 4.0"));
      expect(text, contains("historicalDate: 2024-03-01"));
      expect(text, contains("timestamp: 2024-03-01T12:00:00.000"));
      expect(text, contains("friendlyName: Dólar canadense"));
      expect(text, contains("counterCurrency: BRL"));
    });
  });
}
