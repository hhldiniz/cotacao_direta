import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqflite.dart';

class ConfigurationDao {
  static const configurationId = 1;

  Future<void> insert(Configuration configuration) async {
    final Database db = await AppDatabase().openAppDatabase();
    db.insert("Configuration", configuration.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Configuration> getConfiguration() async {
    final Database db = await AppDatabase().openAppDatabase();
    var result = await db.query("Configuration",
        columns: [
          "id",
          "overrideDefaultCurrency",
          "selectedOverrideCurrencyCode"
        ],
        where: "id = ?",
        whereArgs: [configurationId],
        limit: 1);
    return Configuration(configurationId,
        overrideDefaultCurrency: result.first["overrideDefaultCurrency"],
        selectedOverrideCurrencyCode:
            result.first["selectedOverrideCurrencyCode"]);
  }
}
