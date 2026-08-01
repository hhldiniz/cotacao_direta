import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqlite_api.dart';

class CurrencyDao {
  /// Colunas lidas em todas as consultas: uma cotação só é interpretável junto
  /// da contrapartida que a originou.
  static const _columns = [
    "id",
    "value",
    "historicalDate",
    "timestamp",
    "friendlyName",
    "counterCurrency"
  ];

  Currency _fromRow(Map<String, Object?> row) => Currency(
      id: row["id"] as String?,
      value: row["value"] as double?,
      historicalDate: row["historicalDate"] as String?,
      timestamp: row["timestamp"] as String?,
      friendlyName: row["friendlyName"] as String?,
      counterCurrency: row["counterCurrency"] as String?);

  Future<void> insert(Currency currency) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    await db?.insert("Currency", currency.toMap(),
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

  Future<Currency?> getLatestDataByCurrencyCode(
      String? currencyCode, String counterCurrency) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var result = await db?.query("Currency",
        columns: _columns,
        where: "id = ? AND counterCurrency = ?",
        whereArgs: [currencyCode, counterCurrency],
        orderBy: "historicalDate DESC",
        limit: 1);
    if (result == null || result.isEmpty) return null;
    return _fromRow(result.first);
  }

  Future<List<Currency>> getHistoricalData(List<String> currencyCodeList,
      String initialDate, String finalDate, String counterCurrency) async {
    if (currencyCodeList.isEmpty) return [];
    final Database? db = await (AppDatabase().openAppDatabase());
    var placeholders = List.filled(currencyCodeList.length, "?").join(", ");
    var result = await db?.query("currency",
        columns: _columns,
        where: "id IN ($placeholders) AND counterCurrency = ? "
            "AND historicalDate >= ? AND historicalDate <= ?",
        whereArgs: [
          ...currencyCodeList,
          counterCurrency,
          initialDate,
          finalDate
        ]);
    return List.generate(
        result?.length ?? 0, (index) => _fromRow(result![index]));
  }

  Future<Currency?> getCurrencyByCode(
      String currencyCode, String counterCurrency) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var result = await db?.query("currency",
        columns: _columns,
        where: "id = ? AND counterCurrency = ?",
        whereArgs: [currencyCode, counterCurrency]);
    if (result == null || result.isEmpty) return null;
    return _fromRow(result.first);
  }
}
