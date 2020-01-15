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

  Future<Database> openAppDatabase() async {
    var path = join(await getDatabasesPath(), 'doggie_database.db');
    if (_database == null)
      _database = await openDatabase(path, onCreate: (db, version) {
        db.execute(
            "CREATE TABLE Currency(id TEXT PRIMARY KEY, value REAL, timestamp TEXT)");
      }, onUpgrade: (database, oldVersion, newVersion) {
        migrationsScripts1_2
            .forEach((script) async => await database.execute(script));
      }, version: 2);
    return _database;
  }
}
