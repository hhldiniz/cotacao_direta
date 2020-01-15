import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqlite_api.dart';

class CurrencyDao {
  Future<void> insert(Currency currency) async {
    final Database db = await AppDatabase().openAppDatabase();
    db.insert("currency", currency.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertMany(List<Currency> currencies) async {
    final Database db = await AppDatabase().openAppDatabase();
    var batch = db.batch();
    currencies.forEach((currency) {
      batch.insert("currency", currency.toMap());
    });
    await batch.commit();
  }

  Future<Currency> getLatestDataByCurrencyCode(String currencyCode) async {
    final Database db = await AppDatabase().openAppDatabase();
    var result = await db.query("currency",
        columns: ["id", "value", "historicalDate", "timestamp"],
        where: "id = ?",
        whereArgs: [currencyCode],
        orderBy: "timestamp DESC",
        limit: 1);
    if (result.length == 0)
      return null;
    else
      return Currency(
          id: result.first["id"],
          value: result.first["value"],
          historicalDate: result.first["historicalDate"],
          timestamp: result.first["timestamp"]);
  }

  Future<List<Currency>> getHistoricalData(List<String> currencyCodeList,
      String initialDate, String finalDate) async {
    final Database db = await AppDatabase().openAppDatabase();
    var result = await db.query(
      "currency",
      columns: ["id", "value", "historicalDate", "timestamp"],
      where: "id IN ? AND hitoricalDate BETWEEN ? AND ?",
      whereArgs: [currencyCodeList, initialDate, finalDate]
    );
    return List.generate(result.length, (index){
      return Currency(
        id: result[index]["id"],
        value: result[index]["value"],
        timestamp: result[index]["timestamp"],
        historicalDate: result[index]["historicalDate"]
      );
    });
  }
}
