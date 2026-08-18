import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqflite.dart';

class CurrencyAlertDao {
  static const _table = "CurrencyAlerts";
  static const _columns = [
    "id",
    "currencyCode",
    "targetValue",
    "condition",
    "counterCurrency",
    "triggered",
    "active"
  ];

  Future<int> insert(CurrencyAlert alert) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var map = alert.toMap();
    // id nulo deixa o SQLite atribuir o próximo valor da chave autoincrement.
    if (map['id'] == null) map.remove('id');
    return await db?.insert(_table, map) ?? -1;
  }

  Future<void> update(CurrencyAlert alert) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    await db?.update(_table, alert.toMap(), where: "id = ?", whereArgs: [alert.id]);
  }

  Future<void> delete(int id) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    await db?.delete(_table, where: "id = ?", whereArgs: [id]);
  }

  Future<List<CurrencyAlert>> getAll() async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var result = await db?.query(_table, columns: _columns, orderBy: "id DESC");
    return List.generate(
        result?.length ?? 0, (index) => _fromRow(result![index]));
  }

  Future<List<CurrencyAlert>> getActiveByCurrencyCode(
      String currencyCode) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var result = await db?.query(_table,
        columns: _columns,
        where: "currencyCode = ? AND active = 1 AND triggered = 0",
        whereArgs: [currencyCode]);
    return List.generate(
        result?.length ?? 0, (index) => _fromRow(result![index]));
  }

  CurrencyAlert _fromRow(Map<String, Object?> row) {
    return CurrencyAlert(
      id: row["id"] as int?,
      currencyCode: row["currencyCode"] as String,
      targetValue: (row["targetValue"] as num).toDouble(),
      condition: CurrencyAlertCondition.values.byName(row["condition"] as String),
      counterCurrency: row["counterCurrency"] as String,
      triggered: row["triggered"] == 1,
      active: row["active"] == 1,
    );
  }
}
