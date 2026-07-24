import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static AppDatabase? _instance;
  Database? _database;

  /// Substitui o caminho do arquivo do banco. Usado pelos testes, que rodam
  /// sem os canais de plataforma que sustentam [getDatabasesPath].
  static String? databasePathOverride;

  factory AppDatabase() {
    if (_instance == null) _instance = AppDatabase._internalConstructor();
    return _instance!;
  }

  AppDatabase._internalConstructor();

  /// Fecha e descarta o singleton, para que cada teste comece de um banco novo.
  static Future<void> reset() async {
    await _instance?._database?.close();
    _instance?._database = null;
    _instance = null;
  }

  var migrationsScripts1_2 = [
    "ALTER TABLE Currency ADD historicalDate TEXT NOT NULL DEFAULT ''"
  ];

  var migrationsScripts2_3 = [
    "ALTER TABLE Currency RENAME TO old_Currency",
    "CREATE TABLE Currency(id TEXT, historicalDate TEXT, value REAL, timestamp TEXT, PRIMARY KEY(id, historicalDate))",
    "INSERT INTO Currency(id, historicalDate, value, timestamp) SELECT id, historicalDate, value, timestamp FROM old_Currency",
    "DROP TABLE old_Currency"
  ];

  var migrationsScripts3_4 = [
    "CREATE TABLE Configurations(id INT PRIMARY KEY, overrideDefaultCurrency INTEGER, selectedOverrideCurrencyCode TEXT)"
  ];

  var migrationsScripts4_5 = [
    "ALTER TABLE Currency RENAME TO old_Currency",
    "CREATE TABLE Currency(id TEXT, historicalDate TEXT, value REAL, timestamp TEXT, friendlyName TEXT NOT NULL DEFAULT '', PRIMARY KEY(id, historicalDate))",
    "INSERT INTO Currency(id, historicalDate, value, timestamp) SELECT id, historicalDate, value, timestamp FROM old_Currency",
    "DROP TABLE old_Currency"
  ];

  /// Scripts a aplicar para chegar em cada versão, na ordem.
  Map<int, List<String>> get _migrationsByVersion => {
        2: migrationsScripts1_2,
        3: migrationsScripts2_3,
        4: migrationsScripts3_4,
        5: migrationsScripts4_5,
      };

  Future<Database?> openAppDatabase() async {
    var path = databasePathOverride ??
        join(await getDatabasesPath(), 'doggie_database.db');
    if (_database == null)
      _database = await openDatabase(path, onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE Currency(id TEXT, value REAL, timestamp TEXT, historicalDate TEXT, friendlyName TEXT NOT NULL DEFAULT '', PRIMARY KEY(id, historicalDate))");
        await db.execute(
            "CREATE TABLE Configurations(id INT PRIMARY KEY, overrideDefaultCurrency INTEGER, selectedOverrideCurrencyCode TEXT)");
      }, onUpgrade: (database, oldVersion, newVersion) async {
        // Aplica todas as versões intermediárias, uma de cada vez: quem estava
        // na versão 1 precisa passar por 2, 3 e 4 antes de chegar na 5.
        for (var version = oldVersion + 1; version <= newVersion; version++) {
          for (var script in _migrationsByVersion[version] ?? const <String>[]) {
            await database.execute(script);
          }
        }
      }, version: 5);
    return _database;
  }
}
