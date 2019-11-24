import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqlite_api.dart';

class CurrencyDao {
  Future<void> insert(Currency currency) async {
    final Database db = await AppDatabase().openAppDatabase();
    db.insert("currency", currency.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Currency>> getByCurrencyCode(String currencyCode) async {
    final Database db = await AppDatabase().openAppDatabase();
    List<Map<String, dynamic>> result = await db.query("currency",
        columns: ["id", "value"], where: "id = ?", whereArgs: [currencyCode]);
    return List.generate(result.length, (i) {
      return Currency(
          id: result[i]["id"],
          value: result[i]["value"],
          timestamp: result[i]["timestamp"]);
    });
  }
}
