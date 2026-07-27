import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/repository/currency_alert_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeCurrencyAlertDao dao;
  late CurrencyAlertRepository repository;

  setUp(() {
    dao = FakeCurrencyAlertDao();
    repository = CurrencyAlertRepository(currencyAlertDao: dao);
  });

  group('CurrencyAlertRepository', () {
    test('repassa o insert para o DAO', () async {
      var alert = CurrencyAlert(
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above);

      await repository.insert(alert);

      expect(dao.alerts, [alert]);
    });

    test('repassa o update para o DAO', () async {
      var alert = CurrencyAlert(
          id: 1,
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above);
      dao.alerts.add(alert);

      alert.triggered = true;
      await repository.update(alert);

      expect(dao.alerts.single.triggered, isTrue);
    });

    test('repassa o delete para o DAO', () async {
      dao.alerts.add(CurrencyAlert(
          id: 1,
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above));

      await repository.delete(1);

      expect(dao.alerts, isEmpty);
    });

    test('getAll devolve os alertas do DAO', () async {
      dao.alerts.add(CurrencyAlert(
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above));

      expect(await repository.getAll(), hasLength(1));
    });

    test('getActiveByCurrencyCode filtra pela moeda', () async {
      dao.alerts.addAll([
        CurrencyAlert(
            currencyCode: "USD",
            targetValue: 5.0,
            condition: CurrencyAlertCondition.above),
        CurrencyAlert(
            currencyCode: "EUR",
            targetValue: 6.0,
            condition: CurrencyAlertCondition.above),
      ]);

      var result = await repository.getActiveByCurrencyCode("USD");

      expect(result, hasLength(1));
      expect(result.single.currencyCode, "USD");
    });

    test('usa o CurrencyAlertDao real quando nenhum é informado', () {
      expect(CurrencyAlertRepository(), isNotNull);
    });
  });
}
