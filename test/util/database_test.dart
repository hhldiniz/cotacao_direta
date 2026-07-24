import 'dart:io';

import 'package:cotacao_direta/util/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/database_test_helper.dart';

Future<List<String>> _columnsOf(Database db, String table) async {
  var info = await db.rawQuery("PRAGMA table_info($table)");
  return info.map((column) => column["name"] as String).toList();
}

void main() {
  useInMemoryDatabase();

  group('AppDatabase', () {
    test('é um singleton', () {
      expect(identical(AppDatabase(), AppDatabase()), isTrue);
    });

    test('abre o banco na versão 5', () async {
      var db = await AppDatabase().openAppDatabase();

      expect(db, isNotNull);
      expect(db!.isOpen, isTrue);
      expect(await db.getVersion(), 5);
    });

    test('reaproveita a mesma conexão em chamadas seguintes', () async {
      var first = await AppDatabase().openAppDatabase();
      var second = await AppDatabase().openAppDatabase();

      expect(identical(first, second), isTrue);
    });

    test('cria a tabela Currency com as colunas usadas pelo DAO', () async {
      var db = (await AppDatabase().openAppDatabase())!;

      expect(
          await _columnsOf(db, "Currency"),
          containsAll(
              ["id", "value", "timestamp", "historicalDate", "friendlyName"]));
    });

    test('a chave primária de Currency é composta por id e historicalDate',
        () async {
      var db = (await AppDatabase().openAppDatabase())!;
      var info = await db.rawQuery("PRAGMA table_info(Currency)");
      var primaryKey = info
          .where((column) => (column["pk"] as int) > 0)
          .map((column) => column["name"] as String)
          .toList();

      expect(primaryKey, containsAll(["id", "historicalDate"]));
      expect(primaryKey.length, 2);
    });

    test('friendlyName tem valor padrão vazio, e não nulo', () async {
      var db = (await AppDatabase().openAppDatabase())!;
      await db.insert("Currency", {
        "id": "USD",
        "value": 5.0,
        "timestamp": "2024-01-01T00:00:00.000",
        "historicalDate": "2024-01-01T00:00:00.000"
      });

      var rows = await db.query("Currency");
      expect(rows.single["friendlyName"], "");
    });

    test('cria a tabela Configurations com as colunas usadas pelo DAO',
        () async {
      var db = (await AppDatabase().openAppDatabase())!;

      expect(
          await _columnsOf(db, "Configurations"),
          containsAll([
            "id",
            "overrideDefaultCurrency",
            "selectedOverrideCurrencyCode"
          ]));
    });

    test('reset fecha a conexão e a próxima abertura cria um banco novo',
        () async {
      var db = (await AppDatabase().openAppDatabase())!;
      await db.insert("Currency", {
        "id": "USD",
        "value": 5.0,
        "timestamp": "2024-01-01T00:00:00.000",
        "historicalDate": "2024-01-01T00:00:00.000"
      });

      await AppDatabase.reset();

      expect(db.isOpen, isFalse);
      var reopened = (await AppDatabase().openAppDatabase())!;
      expect(identical(db, reopened), isFalse);
      expect(await reopened.query("Currency"), isEmpty);
    });

    test('os dados sobrevivem à reabertura quando o banco é um arquivo',
        () async {
      var directory =
          await Directory.systemTemp.createTemp("cotacao_direta_test");
      addTearDown(() => directory.delete(recursive: true));
      AppDatabase.databasePathOverride = join(directory.path, "test.db");

      var db = (await AppDatabase().openAppDatabase())!;
      await db.insert("Currency", {
        "id": "USD",
        "value": 5.0,
        "timestamp": "2024-01-01T00:00:00.000",
        "historicalDate": "2024-01-01T00:00:00.000"
      });
      await AppDatabase.reset();

      var reopened = (await AppDatabase().openAppDatabase())!;
      expect(await reopened.getVersion(), 5,
          reason: "reabrir não deve disparar onCreate/onUpgrade de novo");
      expect((await reopened.query("Currency")).single["id"], "USD");
    });
  });
}
