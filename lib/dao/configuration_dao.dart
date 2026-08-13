import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqflite.dart';

class ConfigurationDao {
  static int configurationId = 1;

  Future<void> insert(Configuration configuration) async {
    final Database? db = await (AppDatabase().openAppDatabase());
    await db?.insert("Configurations", configuration.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Configuration> getConfiguration() async {
    final Database? db = await (AppDatabase().openAppDatabase());
    var result = await db?.query("Configurations",
        columns: [
          "id",
          "overrideDefaultCurrency",
          "selectedOverrideCurrencyCode",
          "homeCurrencyCodes",
          "languageCode"
        ],
        where: "id = ?",
        whereArgs: [configurationId],
        limit: 1);
    if (result?.isEmpty == true) {
      return Configuration(configurationId);
    } else
      return Configuration(configurationId,
          overrideDefaultCurrency:
              result?.first["overrideDefaultCurrency"] == 1,
          selectedOverrideCurrencyCode:
              result?.first["selectedOverrideCurrencyCode"] as String?,
          languageCode: result?.first["languageCode"] as String?,
          homeCurrencyCodes: Configuration.parseHomeCurrencyCodes(
              result?.first["homeCurrencyCodes"] as String?));
  }
}
