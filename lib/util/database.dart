import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase
{
  static AppDatabase _instance;
  Database _database;

  factory AppDatabase(){
    if(_instance == null) _instance = AppDatabase._internalConstructor();
    return _instance;
  }

  AppDatabase._internalConstructor();

  Future<Database> openAppDatabase() async{
    var path = join(await getDatabasesPath(), 'doggie_database.db');
    if(_database == null)
      _database = await openDatabase(path, onCreate: (db, version){
      db.execute(
        "CREATE TABLE Currency(id TEXT PRIMARY KEY, value REAL)"
      );
    }, version: 1);
    return _database;
  }
}