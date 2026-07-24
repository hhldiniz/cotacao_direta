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

/// Cria um arquivo de banco no esquema de uma versão antiga do aplicativo, para
/// que a abertura seguinte tenha que migrá-lo.
Future<String> _createLegacyDatabase(
    {required int version,
    required List<String> tables,
    required Map<String, Map<String, Object?>> rows}) async {
  var directory = await Directory.systemTemp.createTemp("cotacao_direta_test");
  addTearDown(() => directory.delete(recursive: true));
  var path = join(directory.path, "legacy.db");

  var legacy = await databaseFactory.openDatabase(path,
      options: OpenDatabaseOptions(
          version: version,
          onCreate: (db, _) async {
            for (var table in tables) {
              await db.execute(table);
            }
          }));
  for (var row in rows.entries) {
    await legacy.insert(row.key, row.value);
  }
  await legacy.close();

  return path;
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

    test('migra um banco da versão 1 até a 5, passando por todas as etapas',
        () async {
      var path = await _createLegacyDatabase(version: 1, tables: [
        "CREATE TABLE Currency(id TEXT PRIMARY KEY, value REAL, timestamp TEXT)"
      ], rows: {
        "Currency": {
          "id": "USD",
          "value": 5.0,
          "timestamp": "2024-01-01T00:00:00.000"
        }
      });
      AppDatabase.databasePathOverride = path;

      var db = (await AppDatabase().openAppDatabase())!;

      expect(await db.getVersion(), 5);
      expect(await _columnsOf(db, "Currency"),
          containsAll(["historicalDate", "friendlyName"]));
      expect(await _columnsOf(db, "Configurations"),
          containsAll(["overrideDefaultCurrency"]),
          reason: "a etapa 3→4 não pode ser pulada");
      var row = (await db.query("Currency")).single;
      expect(row["id"], "USD");
      expect(row["value"], 5.0);
    });

    test('migra um banco da versão 4 para a 5 acrescentando o friendlyName',
        () async {
      var path = await _createLegacyDatabase(version: 4, tables: [
        "CREATE TABLE Currency(id TEXT, value REAL, timestamp TEXT, historicalDate TEXT, PRIMARY KEY(id, historicalDate))",
        "CREATE TABLE Configurations(id INT PRIMARY KEY, overrideDefaultCurrency INTEGER, selectedOverrideCurrencyCode TEXT)"
      ], rows: {
        "Currency": {
          "id": "USD",
          "value": 5.0,
          "timestamp": "2024-01-01T00:00:00.000",
          "historicalDate": "2024-01-01T00:00:00.000"
        }
      });
      AppDatabase.databasePathOverride = path;

      var db = (await AppDatabase().openAppDatabase())!;

      expect(await db.getVersion(), 5);
      var row = (await db.query("Currency")).single;
      expect(row["historicalDate"], "2024-01-01T00:00:00.000");
      expect(row["friendlyName"], "",
          reason: "quem já estava no banco fica com o nome amigável vazio");
    });

    test('a tabela migrada aceita a mesma moeda em datas diferentes', () async {
      var path = await _createLegacyDatabase(version: 4, tables: [
        "CREATE TABLE Currency(id TEXT, value REAL, timestamp TEXT, historicalDate TEXT, PRIMARY KEY(id, historicalDate))",
        "CREATE TABLE Configurations(id INT PRIMARY KEY, overrideDefaultCurrency INTEGER, selectedOverrideCurrencyCode TEXT)"
      ], rows: {});
      AppDatabase.databasePathOverride = path;

      var db = (await AppDatabase().openAppDatabase())!;
      await db.insert("Currency", {
        "id": "USD",
        "value": 5.0,
        "timestamp": "2024-01-01T00:00:00.000",
        "historicalDate": "2024-01-01T00:00:00.000"
      });
      await db.insert("Currency", {
        "id": "USD",
        "value": 6.0,
        "timestamp": "2024-01-02T00:00:00.000",
        "historicalDate": "2024-01-02T00:00:00.000"
      });

      expect((await db.query("Currency")).length, 2);
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
