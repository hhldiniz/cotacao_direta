import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase
{
  static AppDatabase _instance;

  factory AppDatabase(){
    if(_instance == null) _instance = AppDatabase._internalConstructor();
    return _instance;
  }

  AppDatabase._internalConstructor();

  Future<Database> openAppDatabase() async{
    var path = join(await getDatabasesPath(), 'doggie_database.db');
    return openDatabase(path, onCreate: (db, version){
      db.execute(
        "CREATE TABLE Currency(id TEXT PRIMARY KEY, value REAL)"
      );
    });
  }
}