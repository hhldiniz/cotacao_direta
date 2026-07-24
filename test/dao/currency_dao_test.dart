import 'package:cotacao_direta/dao/currency_dao.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/database_test_helper.dart';

Currency _currency(String id, String historicalDate,
        {double value = 5.0, String? friendlyName, String? timestamp}) =>
    Currency(
        id: id,
        value: value,
        historicalDate: historicalDate,
        timestamp: timestamp ?? historicalDate,
        friendlyName: friendlyName ?? "Nome de $id");

void main() {
  useInMemoryDatabase();

  late CurrencyDao dao;

  setUp(() {
    dao = CurrencyDao();
  });

  group('CurrencyDao.insert', () {
    test('grava a moeda com todas as colunas', () async {
      await dao.insert(_currency("USD", "2024-01-01T00:00:00.000",
          value: 4.95, friendlyName: "Dólar dos Estados Unidos"));

      var db = (await AppDatabase().openAppDatabase())!;
      var row = (await db.query("Currency")).single;

      expect(row["id"], "USD");
      expect(row["value"], 4.95);
      expect(row["historicalDate"], "2024-01-01T00:00:00.000");
      expect(row["friendlyName"], "Dólar dos Estados Unidos");
    });

    test('substitui a linha de mesma chave (id + historicalDate)', () async {
      await dao
          .insert(_currency("USD", "2024-01-01T00:00:00.000", value: 4.95));
      await dao
          .insert(_currency("USD", "2024-01-01T00:00:00.000", value: 5.10));

      var db = (await AppDatabase().openAppDatabase())!;
      var rows = await db.query("Currency");

      expect(rows.length, 1);
      expect(rows.single["value"], 5.10);
    });

    test('mantém linhas separadas para datas diferentes da mesma moeda',
        () async {
      await dao.insert(_currency("USD", "2024-01-01T00:00:00.000"));
      await dao.insert(_currency("USD", "2024-01-02T00:00:00.000"));

      var db = (await AppDatabase().openAppDatabase())!;

      expect((await db.query("Currency")).length, 2);
    });
  });

  group('CurrencyDao.insertMany', () {
    test('grava todas as moedas da lista em lote', () async {
      await dao.insertMany([
        _currency("USD", "2024-01-01T00:00:00.000"),
        _currency("EUR", "2024-01-01T00:00:00.000"),
        _currency("JPY", "2024-01-02T00:00:00.000"),
      ]);

      var db = (await AppDatabase().openAppDatabase())!;

      expect((await db.query("Currency")).length, 3);
    });

    test('aceita lista vazia sem erro', () async {
      await dao.insertMany([]);

      var db = (await AppDatabase().openAppDatabase())!;

      expect(await db.query("Currency"), isEmpty);
    });

    test('substitui duplicatas dentro do próprio lote', () async {
      await dao.insertMany([
        _currency("USD", "2024-01-01T00:00:00.000", value: 4.0),
        _currency("USD", "2024-01-01T00:00:00.000", value: 6.0),
      ]);

      var db = (await AppDatabase().openAppDatabase())!;
      var rows = await db.query("Currency");

      expect(rows.length, 1);
      expect(rows.single["value"], 6.0);
    });
  });

  group('CurrencyDao.getLatestDataByCurrencyCode', () {
    test('devolve null quando a moeda não existe', () async {
      expect(await dao.getLatestDataByCurrencyCode("USD"), isNull);
    });

    test('devolve a linha mais recente da moeda', () async {
      await dao.insertMany([
        _currency("USD", "2024-01-01T00:00:00.000", value: 4.0),
        _currency("USD", "2024-03-01T00:00:00.000", value: 6.0),
        _currency("USD", "2024-02-01T00:00:00.000", value: 5.0),
      ]);

      var currency = await dao.getLatestDataByCurrencyCode("USD");

      expect(currency!.historicalDate, "2024-03-01T00:00:00.000");
      expect(currency.value, 6.0);
    });

    test('não mistura moedas diferentes', () async {
      await dao.insertMany([
        _currency("USD", "2024-01-01T00:00:00.000", value: 4.0),
        _currency("EUR", "2024-05-01T00:00:00.000", value: 6.0),
      ]);

      var currency = await dao.getLatestDataByCurrencyCode("USD");

      expect(currency!.id, "USD");
      expect(currency.value, 4.0);
    });

    // O sqflite avisa que passar null em whereArgs deve virar exceção em
    // versões futuras: hoje a consulta simplesmente não casa com nada.
    test('devolve null quando o código é nulo', () async {
      await dao.insert(_currency("USD", "2024-01-01T00:00:00.000"));

      expect(await dao.getLatestDataByCurrencyCode(null), isNull);
    });

    test('preenche o friendlyName do resultado', () async {
      await dao.insert(_currency("USD", "2024-01-01T00:00:00.000",
          friendlyName: "Dólar dos Estados Unidos"));

      var currency = await dao.getLatestDataByCurrencyCode("USD");

      expect(currency!.friendlyName, "Dólar dos Estados Unidos");
    });
  });

  group('CurrencyDao.getCurrencyByCode', () {
    test('devolve null quando a moeda não existe', () async {
      expect(await dao.getCurrencyByCode("USD"), isNull);
    });

    test('devolve a moeda com todos os campos preenchidos', () async {
      await dao.insert(_currency("EUR", "2024-01-01T00:00:00.000",
          value: 6.2,
          friendlyName: "Euro",
          timestamp: "2024-01-01T10:00:00.000"));

      var currency = await dao.getCurrencyByCode("EUR");

      expect(currency!.id, "EUR");
      expect(currency.value, 6.2);
      expect(currency.historicalDate, "2024-01-01T00:00:00.000");
      expect(currency.timestamp, "2024-01-01T10:00:00.000");
      expect(currency.friendlyName, "Euro");
    });
  });

  group('CurrencyDao.getHistoricalData', () {
    setUp(() async {
      await dao.insertMany([
        _currency("USD", "2024-01-01T00:00:00.000", value: 4.0),
        _currency("USD", "2024-02-01T00:00:00.000", value: 5.0),
        _currency("USD", "2024-03-01T00:00:00.000", value: 6.0),
        _currency("EUR", "2024-02-01T00:00:00.000", value: 7.0),
      ]);
    });

    test('devolve as cotações da moeda dentro do intervalo', () async {
      var result = await dao.getHistoricalData(
          ["USD"], "2024-01-15T00:00:00.000", "2024-03-15T00:00:00.000");

      expect(result.map((currency) => currency.historicalDate),
          ["2024-02-01T00:00:00.000", "2024-03-01T00:00:00.000"]);
      expect(result.map((currency) => currency.value), [5.0, 6.0]);
    });

    test('inclui os limites do intervalo', () async {
      var result = await dao.getHistoricalData(
          ["USD"], "2024-01-01T00:00:00.000", "2024-03-01T00:00:00.000");

      expect(result.length, 3);
    });

    test('devolve lista vazia quando nada cai no intervalo', () async {
      var result = await dao.getHistoricalData(
          ["USD"], "2025-01-01T00:00:00.000", "2025-12-31T00:00:00.000");

      expect(result, isEmpty);
    });

    test('preenche todos os campos, inclusive o friendlyName', () async {
      var result = await dao.getHistoricalData(
          ["EUR"], "2024-01-01T00:00:00.000", "2024-12-31T00:00:00.000");

      var currency = result.single;
      expect(currency.id, "EUR");
      expect(currency.value, 7.0);
      expect(currency.friendlyName, "Nome de EUR");
      expect(currency.timestamp, "2024-02-01T00:00:00.000");
    });

    test('devolve as cotações de várias moedas de uma vez', () async {
      var result = await dao.getHistoricalData(
          ["USD", "EUR"], "2024-01-01T00:00:00.000", "2024-12-31T00:00:00.000");

      expect(result, hasLength(4));
      expect(result.map((currency) => currency.id).toSet(), {"USD", "EUR"});
    });

    test('traz só as moedas pedidas', () async {
      var result = await dao.getHistoricalData(
          ["EUR"], "2024-01-01T00:00:00.000", "2024-12-31T00:00:00.000");

      expect(result.map((currency) => currency.id), ["EUR"]);
    });

    test('devolve lista vazia quando nenhuma moeda é pedida', () async {
      var result = await dao.getHistoricalData(
          [], "2024-01-01T00:00:00.000", "2024-12-31T00:00:00.000");

      expect(result, isEmpty);
    });
  });
}
