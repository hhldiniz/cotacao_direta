import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqlite_api.dart';

class CurrencyDao {
  Future<void> insert(Currency currency) async {
    final Database db = await AppDatabase().openAppDatabase();
    db.insert("currency", currency.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Currency> getByCurrencyCode(String currencyCode) async {
    final Database db = await AppDatabase().openAppDatabase();
    var result = await db.query("currency",
        columns: ["id", "value", "timestamp"], where: "id = ?", whereArgs: [currencyCode]);
    if(result.length == 0)
      return null;
    else
      return Currency(
          id: result.first["id"],
          value: result.first["value"],
          timestamp: result.first["timestamp"]
      );
  }
}
