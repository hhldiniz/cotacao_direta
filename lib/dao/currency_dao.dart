import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:sqflite/sqlite_api.dart';

class CurrencyDao
{
  Future<void> insert(Currency currency) async{
    final Database db = await AppDatabase().openAppDatabase();
    db.insert("currency", currency.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}