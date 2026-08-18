import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/base_model.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyAlert', () {
    test('é um BaseModel', () {
      expect(
          CurrencyAlert(
              currencyCode: "USD",
              targetValue: 5.0,
              condition: CurrencyAlertCondition.above,
              counterCurrency: "BRL"),
          isA<BaseModel>());
    });

    test('usa os padrões quando só os campos obrigatórios são informados', () {
      var alert = CurrencyAlert(
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above,
          counterCurrency: "BRL");

      expect(alert.id, isNull);
      expect(alert.triggered, isFalse);
      expect(alert.active, isTrue);
    });

    group('isMetBy', () {
      test('condição "above" é atendida quando o valor é maior ou igual',
          () {
        var alert = CurrencyAlert(
            currencyCode: "USD",
            targetValue: 5.0,
            condition: CurrencyAlertCondition.above,
            counterCurrency: "BRL");

        expect(alert.isMetBy(5.0), isTrue);
        expect(alert.isMetBy(5.5), isTrue);
        expect(alert.isMetBy(4.9), isFalse);
      });

      test('condição "below" é atendida quando o valor é menor ou igual', () {
        var alert = CurrencyAlert(
            currencyCode: "USD",
            targetValue: 5.0,
            condition: CurrencyAlertCondition.below,
            counterCurrency: "BRL");

        expect(alert.isMetBy(5.0), isTrue);
        expect(alert.isMetBy(4.5), isTrue);
        expect(alert.isMetBy(5.1), isFalse);
      });
    });

    test('toMap converte os booleanos em inteiros', () {
      var map = CurrencyAlert(
              id: 7,
              currencyCode: "EUR",
              targetValue: 6.2,
              condition: CurrencyAlertCondition.below,
              counterCurrency: "EUR",
              triggered: true,
              active: false)
          .toMap();

      expect(map, {
        'id': 7,
        'currencyCode': "EUR",
        'targetValue': 6.2,
        'condition': "below",
        'counterCurrency': "EUR",
        'triggered': 1,
        'active': 0,
      });
    });

    test('toString expõe todos os campos', () {
      var text = CurrencyAlert(
              id: 1,
              currencyCode: "GBP",
              targetValue: 7.0,
              condition: CurrencyAlertCondition.above,
              counterCurrency: "BRL")
          .toString();

      expect(text, contains("id: 1"));
      expect(text, contains("currencyCode: GBP"));
      expect(text, contains("targetValue: 7.0"));
      expect(text, contains("counterCurrency: BRL"));
    });
  });
}
