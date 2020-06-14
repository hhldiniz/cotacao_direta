import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static AppDatabase _instance;
  Database _database;

  factory AppDatabase() {
    if (_instance == null) _instance = AppDatabase._internalConstructor();
    return _instance;
  }

  AppDatabase._internalConstructor();

  var migrationsScripts1_2 = [
    "ALTER TABLE Currency ADD historicalDate TEXT NOT NULL DEFAULT ''"
  ];

  var migrationsScripts2_3 = [
    "ALTER TABLE Currency RENAME TO old_Currency",
    "CREATE TABLE Currency(id TEXT PRIMARY KEY, historicalDate TEXT PRIMARY KEY, value REAL, timestamp TEXT)",
    "INSERT INTO Currency(id, historicalDate, value, timestamp) SELECT id, historicalDate, value, timestamp FROM old_Currency",
    "DROP TABLE old_Currency"
  ];

  Future<Database> openAppDatabase() async {
    var path = join(await getDatabasesPath(), 'doggie_database.db');
    if (_database == null)
      _database = await openDatabase(path, onCreate: (db, version) {
        db.execute(
            "CREATE TABLE Currency(id TEXT, value REAL, timestamp TEXT, historicalDate TEXT, PRIMARY KEY(id, historicalDate))");
      }, onUpgrade: (database, oldVersion, newVersion) {
        switch (newVersion) {
          case 2:
            migrationsScripts1_2
                .forEach((script) async => await database.execute(script));
            break;
          case 3:
            migrationsScripts2_3
                .forEach((script) async => await database.execute(script));
            break;
        }
      }, version: 3);
    return _database;
  }
}
