import 'package:cotacao_direta/dao/currency_alert_dao.dart';
import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/database_test_helper.dart';

CurrencyAlert _alert(String currencyCode,
        {int? id,
        double targetValue = 5.0,
        CurrencyAlertCondition condition = CurrencyAlertCondition.above,
        bool triggered = false,
        bool active = true}) =>
    CurrencyAlert(
        id: id,
        currencyCode: currencyCode,
        targetValue: targetValue,
        condition: condition,
        triggered: triggered,
        active: active);

void main() {
  useInMemoryDatabase();

  late CurrencyAlertDao dao;

  setUp(() {
    dao = CurrencyAlertDao();
  });

  group('CurrencyAlertDao.insert', () {
    test('grava o alerta com todas as colunas', () async {
      await dao.insert(_alert("USD", targetValue: 5.5));

      var db = (await AppDatabase().openAppDatabase())!;
      var row = (await db.query("CurrencyAlerts")).single;

      expect(row["currencyCode"], "USD");
      expect(row["targetValue"], 5.5);
      expect(row["condition"], "above");
      expect(row["triggered"], 0);
      expect(row["active"], 1);
    });

    test('atribui um id autoincrementado quando nenhum é informado', () async {
      var firstId = await dao.insert(_alert("USD"));
      var secondId = await dao.insert(_alert("EUR"));

      expect(secondId, greaterThan(firstId));
    });
  });

  group('CurrencyAlertDao.getAll', () {
    test('devolve lista vazia quando não há alertas', () async {
      expect(await dao.getAll(), isEmpty);
    });

    test('devolve todos os alertas gravados', () async {
      await dao.insert(_alert("USD"));
      await dao.insert(_alert("EUR", condition: CurrencyAlertCondition.below));

      var alerts = await dao.getAll();

      expect(alerts, hasLength(2));
      expect(alerts.map((alert) => alert.currencyCode).toSet(), {"USD", "EUR"});
    });
  });

  group('CurrencyAlertDao.update', () {
    test('atualiza os campos do alerta existente', () async {
      var id = await dao.insert(_alert("USD"));
      var alert = _alert("USD", id: id, triggered: true);

      await dao.update(alert);

      var stored = (await dao.getAll()).single;
      expect(stored.triggered, isTrue);
    });
  });

  group('CurrencyAlertDao.delete', () {
    test('remove o alerta pelo id', () async {
      var id = await dao.insert(_alert("USD"));
      await dao.insert(_alert("EUR"));

      await dao.delete(id);

      var alerts = await dao.getAll();
      expect(alerts, hasLength(1));
      expect(alerts.single.currencyCode, "EUR");
    });
  });

  group('CurrencyAlertDao.getActiveByCurrencyCode', () {
    test('devolve só os alertas ativos e não disparados da moeda', () async {
      await dao.insert(_alert("USD"));
      await dao.insert(_alert("USD", triggered: true));
      await dao.insert(_alert("USD", active: false));
      await dao.insert(_alert("EUR"));

      var alerts = await dao.getActiveByCurrencyCode("USD");

      expect(alerts, hasLength(1));
      expect(alerts.single.currencyCode, "USD");
      expect(alerts.single.triggered, isFalse);
      expect(alerts.single.active, isTrue);
    });
  });
}
