import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqlite_api.dart';

class CurrencyDao {
  Future<void> insert(Currency currency) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    db?.insert("Currency", currency.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertMany(List<Currency> currencies) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var batch = db?.batch();
    currencies.forEach((currency) {
      batch?.insert("Currency", currency.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch?.commit();
  }

  Future<Currency?> getLatestDataByCurrencyCode(String? currencyCode) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var result = await db?.query("Currency",
        columns: ["id", "value", "historicalDate", "timestamp", "friendlyName"],
        where: "id = ?",
        whereArgs: [currencyCode],
        orderBy: "historicalDate DESC",
        limit: 1);
    if (result?.length == 0)
      return null;
    else
      return Currency(
          id: result?.first["id"] as String?,
          value: result?.first["value"] as double?,
          historicalDate: result?.first["historicalDate"] as String?,
          timestamp: result?.first["timestamp"] as String?);
  }

  Future<List<Currency>> getHistoricalData(List<String> currencyCodeList,
      String initialDate, String finalDate) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var result = await db?.query("currency",
        columns: ["id", "value", "historicalDate", "timestamp", "friendlyName"],
        where: "id IN (?) AND historicalDate >= ? AND historicalDate <= ?",
        whereArgs: [currencyCodeList.join(", "), initialDate, finalDate]);
    return List.generate(result?.length ?? 0, (index) {
      return Currency(
          id: result?[index]["id"] as String?,
          value: result?[index]["value"] as double?,
          timestamp: result?[index]["timestamp"] as String?,
          historicalDate: result?[index]["historicalDate"] as String?,
          friendlyName: result?[index]["friendlyName"] as String?);
    });
  }

  Future<Currency?> getCurrencyByCode(String currencyCode) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var result = await db?.query("currency",
        columns: ["id", "value", "historicalDate", "timestamp", "friendlyName"],
        where: "id=?",
        whereArgs: [currencyCode]);
    if (result?.isEmpty == true)
      return null;
    else
      return Currency(
          id: currencyCode,
          historicalDate: result?.first["historicalDate"] as String?,
          timestamp: result?.first["timestamp"] as String?,
          value: result?.first["value"] as double?,
          friendlyName: result?.first["friendlyName"] as String?);
  }
}
